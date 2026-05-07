import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { requireAuth } from "../_shared/auth.ts";
import {
  errorResponse,
  handleCors,
  jsonResponse,
  methodNotAllowed,
  parseJsonBody,
} from "../_shared/http.ts";
import { polishTranscript } from "../_shared/provider.ts";
import { countWords } from "../_shared/utils.ts";
import { recordUsageIncrement, saveDictationSession } from "../_shared/usage.ts";
import { PolishRequest, PolishResponse } from "../_shared/types.ts";
import { validatePolishBody } from "../_shared/validation.ts";

serve(async (request) => {
  const cors = handleCors(request);
  if (cors) return cors;

  if (request.method !== "POST") {
    return methodNotAllowed(["POST", "OPTIONS"]);
  }

  try {
    const auth = await requireAuth(request);
    const body = validatePolishBody(await parseJsonBody<PolishRequest>(request));
    const output = await polishTranscript({
      mode: body.mode,
      transcript: body.transcript,
    });
    const wordCount = countWords(output);

    const sessionId = await saveDictationSession({
      userId: auth.userId,
      mode: body.mode,
      source: body.source,
      rawTranscript: body.transcript,
      polishedText: output,
      wordCount,
    });

    await recordUsageIncrement(auth, { dictations: 1 });

    const response: PolishResponse = {
      output,
      wordCount,
      sessionId,
    };

    return jsonResponse(response);
  } catch (error) {
    return errorResponse(
      "polish_failed",
      error instanceof Error ? error.message : "Unknown polish error",
      400,
    );
  }
});
