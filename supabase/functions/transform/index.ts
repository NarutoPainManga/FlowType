import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { requireAuth } from "../_shared/auth.ts";
import {
  errorResponse,
  handleCors,
  jsonResponse,
  methodNotAllowed,
  parseJsonBody,
} from "../_shared/http.ts";
import { transformText } from "../_shared/provider.ts";
import { assertTransformAvailable, saveDictationSession } from "../_shared/usage.ts";
import { TransformRequest, TransformResponse } from "../_shared/types.ts";
import { countWords } from "../_shared/utils.ts";
import { validateTransformBody } from "../_shared/validation.ts";

serve(async (request) => {
  const cors = handleCors(request);
  if (cors) return cors;

  if (request.method !== "POST") {
    return methodNotAllowed(["POST", "OPTIONS"]);
  }

  try {
    const auth = await requireAuth(request);
    const usage = await assertTransformAvailable(auth);
    const body = validateTransformBody(await parseJsonBody<TransformRequest>(request));
    const output = await transformText(body);
    const wordCount = countWords(output);
    const sessionId = await saveDictationSession({
      userId: auth.userId,
      mode: body.mode ?? "brain_dump",
      source: "transform",
      rawTranscript: body.input,
      polishedText: output,
      wordCount,
    });
    const response: TransformResponse = {
      output,
      wordCount,
      sessionId,
      transformsUsed: usage.transformsUsed + 1,
      transformsLimit: usage.transformsLimit,
      canTransform: usage.plan === "pro"
        ? true
        : usage.transformsLimit === null
        ? false
        : usage.transformsUsed + 1 < usage.transformsLimit,
    };

    return jsonResponse(response);
  } catch (error) {
    return errorResponse(
      "transform_failed",
      error instanceof Error ? error.message : "Unknown transform error",
      400,
    );
  }
});
