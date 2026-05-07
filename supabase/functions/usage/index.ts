import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { requireAuth } from "../_shared/auth.ts";
import {
  errorResponse,
  handleCors,
  jsonResponse,
  methodNotAllowed,
} from "../_shared/http.ts";
import { UsageResponse } from "../_shared/types.ts";
import { getUsageState } from "../_shared/usage.ts";

serve(async (request) => {
  const cors = handleCors(request);
  if (cors) return cors;

  if (request.method !== "GET") {
    return methodNotAllowed(["GET", "OPTIONS"]);
  }

  try {
    const auth = await requireAuth(request);
    const usage = await getUsageState(auth);
    const response: UsageResponse = {
      plan: usage.plan,
      dictationsUsed: usage.dictationsUsed,
      dictationsLimit: usage.dictationsLimit,
      transformsUsed: usage.transformsUsed,
      transformsLimit: usage.transformsLimit,
      weekStart: usage.weekStart,
      audioSecondsUsed: usage.audioSecondsUsed,
      canDictate: usage.canDictate,
      canTransform: usage.canTransform,
    };

    return jsonResponse(response);
  } catch (error) {
    return errorResponse(
      "usage_failed",
      error instanceof Error ? error.message : "Unknown usage error",
      401,
    );
  }
});
