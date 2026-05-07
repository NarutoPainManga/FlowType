import { createAdminClient } from "./db.ts";
import { AuthContext, UsageState } from "./types.ts";

const FREE_DICTATION_LIMIT = 5;

export async function getUsageState(
  auth: AuthContext,
): Promise<UsageState> {
  const weekStart = startOfWeekIso(new Date());
  const supabase = createAdminClient();

  const [{ data: usageRow, error: usageError }, { data: subscriptionRow, error: subscriptionError }] =
    await Promise.all([
      supabase
        .from("usage_counters")
        .select("week_start, dictation_count, audio_seconds")
        .eq("user_id", auth.userId)
        .maybeSingle(),
      supabase
        .from("subscription_snapshots")
        .select("entitlement, status, expires_at")
        .eq("user_id", auth.userId)
        .maybeSingle(),
    ]);

  if (usageError) {
    throw new Error(`Failed to load usage state: ${usageError.message}`);
  }
  if (subscriptionError) {
    throw new Error(`Failed to load subscription state: ${subscriptionError.message}`);
  }

  const isPro = isProSubscription(subscriptionRow);
  let dictationsUsed = usageRow?.dictation_count ?? 0;
  let audioSecondsUsed = usageRow?.audio_seconds ?? 0;
  const storedWeekStart = usageRow?.week_start ?? weekStart;

  if (storedWeekStart !== weekStart) {
    const { error: resetError } = await supabase
      .from("usage_counters")
      .upsert({
        user_id: auth.userId,
        week_start: weekStart,
        dictation_count: 0,
        audio_seconds: 0,
      });

    if (resetError) {
      throw new Error(`Failed to reset usage state: ${resetError.message}`);
    }

    dictationsUsed = 0;
    audioSecondsUsed = 0;
  }

  const dictationsLimit = isPro ? null : FREE_DICTATION_LIMIT;
  const transformsUsed = await getTransformCountForWeek(auth.userId, weekStart);
  const transformsLimit = isPro ? null : Math.min(dictationsUsed, FREE_DICTATION_LIMIT);

  return {
    plan: isPro ? "pro" : "free",
    dictationsUsed,
    dictationsLimit,
    transformsUsed,
    transformsLimit,
    weekStart,
    audioSecondsUsed,
    canDictate: isPro || dictationsUsed < FREE_DICTATION_LIMIT,
    canTransform: isPro || transformsUsed < transformsLimit,
  };
}

export async function assertUsageAvailable(
  auth: AuthContext,
): Promise<UsageState> {
  const usage = await getUsageState(auth);

  if (!usage.canDictate) {
    throw new Error("Usage limit reached");
  }

  if (
    usage.plan === "free" &&
    usage.dictationsLimit !== null &&
    usage.dictationsUsed >= usage.dictationsLimit
  ) {
    throw new Error("Weekly dictation limit reached");
  }

  return usage;
}

export async function assertTransformAvailable(
  auth: AuthContext,
): Promise<UsageState> {
  const usage = await getUsageState(auth);

  if (!usage.canTransform) {
    throw new Error("Free accounts can use one AI rewrite for each completed dictation.");
  }

  if (
    usage.plan === "free" &&
    usage.transformsLimit !== null &&
    usage.transformsUsed >= usage.transformsLimit
  ) {
    throw new Error("AI rewrite limit reached for this week's free dictations.");
  }

  return usage;
}

export async function recordUsageIncrement(
  auth: AuthContext,
  increment: { dictations?: number; audioSeconds?: number },
): Promise<void> {
  const supabase = createAdminClient();
  const weekStart = startOfWeekIso(new Date());

  const { data: existing, error: loadError } = await supabase
    .from("usage_counters")
    .select("week_start, dictation_count, audio_seconds")
    .eq("user_id", auth.userId)
    .maybeSingle();

  if (loadError) {
    throw new Error(`Failed to load usage counters: ${loadError.message}`);
  }

  const isCurrentWeek = existing?.week_start === weekStart;
  const nextDictations = (isCurrentWeek ? existing?.dictation_count ?? 0 : 0) + (increment.dictations ?? 0);
  const nextAudioSeconds = (isCurrentWeek ? existing?.audio_seconds ?? 0 : 0) + (increment.audioSeconds ?? 0);

  const { error: upsertError } = await supabase
    .from("usage_counters")
    .upsert({
      user_id: auth.userId,
      week_start: weekStart,
      dictation_count: nextDictations,
      audio_seconds: nextAudioSeconds,
    });

  if (upsertError) {
    throw new Error(`Failed to update usage counters: ${upsertError.message}`);
  }
}

export async function recordSubscriptionSnapshot(_input: {
  userId?: string;
  entitlement: string;
  status: string;
  productId?: string | null;
  expiresAt?: string | null;
}): Promise<void> {
  if (!_input.userId) {
    return;
  }

  const supabase = createAdminClient();
  const plan = isProEntitlement(_input.entitlement, _input.status, _input.expiresAt)
    ? "pro"
    : "free";

  const { error: snapshotError } = await supabase
    .from("subscription_snapshots")
    .upsert({
      user_id: _input.userId,
      entitlement: _input.entitlement,
      status: _input.status,
      product_id: _input.productId ?? null,
      expires_at: _input.expiresAt ?? null,
    });

  if (snapshotError) {
    throw new Error(`Failed to update subscription snapshot: ${snapshotError.message}`);
  }

  const { error: profileError } = await supabase
    .from("profiles")
    .update({
      plan,
    })
    .eq("id", _input.userId);

  if (profileError) {
    throw new Error(`Failed to update profile plan: ${profileError.message}`);
  }
}

export async function saveDictationSession(input: {
  userId: string;
  mode: string;
  source: string;
  rawTranscript: string;
  polishedText: string;
  durationSeconds?: number;
  wordCount: number;
}): Promise<string> {
  const supabase = createAdminClient();
  const { data, error } = await supabase
    .from("dictation_sessions")
    .insert({
      user_id: input.userId,
      mode_key: input.mode,
      source: input.source,
      raw_transcript: input.rawTranscript,
      polished_text: input.polishedText,
      duration_seconds: Math.max(0, Math.round(input.durationSeconds ?? 0)),
      word_count: input.wordCount,
    })
    .select("id")
    .single();

  if (error) {
    throw new Error(`Failed to save dictation session: ${error.message}`);
  }

  return data.id as string;
}

export async function getTransformCountForWeek(
  userId: string,
  weekStart: string,
): Promise<number> {
  const supabase = createAdminClient();
  const nextWeekStart = addDaysIso(weekStart, 7);
  const { count, error } = await supabase
    .from("dictation_sessions")
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId)
    .eq("source", "transform")
    .gte("created_at", `${weekStart}T00:00:00.000Z`)
    .lt("created_at", `${nextWeekStart}T00:00:00.000Z`);

  if (error) {
    throw new Error(`Failed to load transform usage: ${error.message}`);
  }

  return count ?? 0;
}

function startOfWeekIso(date: Date): string {
  const copy = new Date(date);
  const day = copy.getUTCDay();
  const diff = day === 0 ? -6 : 1 - day;

  copy.setUTCDate(copy.getUTCDate() + diff);
  copy.setUTCHours(0, 0, 0, 0);

  return copy.toISOString().slice(0, 10);
}

function addDaysIso(isoDate: string, days: number): string {
  const date = new Date(`${isoDate}T00:00:00.000Z`);
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}

function isProSubscription(
  subscriptionRow: { entitlement?: string | null; status?: string | null; expires_at?: string | null } | null,
): boolean {
  return isProEntitlement(
    subscriptionRow?.entitlement ?? "free",
    subscriptionRow?.status ?? "inactive",
    subscriptionRow?.expires_at ?? null,
  );
}

function isProEntitlement(
  entitlement: string,
  status: string,
  expiresAt?: string | null,
): boolean {
  const normalizedEntitlement = entitlement.toLowerCase();
  const normalizedStatus = status.toLowerCase();
  const expired = expiresAt ? new Date(expiresAt).getTime() <= Date.now() : false;
  const inactiveStatus = normalizedStatus.includes("expiration") ||
    normalizedStatus.includes("expired") ||
    normalizedStatus.includes("cancel");

  return normalizedEntitlement === "pro" && !inactiveStatus && !expired;
}
