export interface AppEnv {
  supabaseUrl: string;
  supabaseAnonKey: string;
  supabaseServiceRoleKey?: string;
  openAiApiKey?: string;
  openAiTranscriptionModel: string;
  openAiTextModel: string;
  revenueCatWebhookSecret?: string;
}

export function getEnv(): AppEnv {
  return {
    supabaseUrl: mustGetEnv("SUPABASE_URL"),
    supabaseAnonKey: mustGetEnv("SUPABASE_ANON_KEY"),
    supabaseServiceRoleKey: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? undefined,
    openAiApiKey: Deno.env.get("OPENAI_API_KEY") ?? undefined,
    openAiTranscriptionModel: Deno.env.get("OPENAI_TRANSCRIPTION_MODEL") ?? "whisper-1",
    openAiTextModel: Deno.env.get("OPENAI_TEXT_MODEL") ?? "gpt-4.1-mini",
    revenueCatWebhookSecret: Deno.env.get("REVENUECAT_WEBHOOK_SECRET") ?? undefined,
  };
}

function mustGetEnv(name: string): string {
  const value = Deno.env.get(name);

  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value;
}
