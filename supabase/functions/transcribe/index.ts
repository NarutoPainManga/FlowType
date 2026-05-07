import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  errorResponse,
  handleCors,
  jsonResponse,
  methodNotAllowed,
  parseMultipartForm,
} from "../_shared/http.ts";
import { transcribeAudio } from "../_shared/provider.ts";
import { requireAuth } from "../_shared/auth.ts";
import { assertUsageAvailable } from "../_shared/usage.ts";
import { validateMode, validateSource } from "../_shared/validation.ts";
import { TranscribeResponse } from "../_shared/types.ts";

serve(async (request) => {
  const cors = handleCors(request);
  if (cors) return cors;

  if (request.method !== "POST") {
    return methodNotAllowed(["POST", "OPTIONS"]);
  }

  try {
    const auth = await requireAuth(request);
    await assertUsageAvailable(auth);

    const formData = await parseMultipartForm(request);
    const audio = formData.get("audio");
    const mode = validateMode(formData.get("mode"));
    const source = validateSource(formData.get("source"));

    if (!(audio instanceof File)) {
      return errorResponse("invalid_audio", "Expected multipart field `audio`");
    }

    const result: TranscribeResponse = await transcribeAudio({
      audio,
      fileName: audio.name || "dictation.m4a",
      mimeType: audio.type || "application/octet-stream",
    });

    return jsonResponse({
      ...result,
      meta: {
        mode,
        source,
      },
    });
  } catch (error) {
    return errorResponse(
      "transcribe_failed",
      error instanceof Error ? error.message : "Unknown transcription error",
      400,
    );
  }
});
