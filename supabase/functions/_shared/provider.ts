import { getEnv } from "./env.ts";
import {
  ModeKey,
  TransformAction,
} from "./types.ts";

export interface TranscriptionInput {
  audio: Blob;
  fileName: string;
  mimeType: string;
}

export interface TranscriptionResult {
  transcript: string;
  durationSeconds: number;
}

export interface PolishInput {
  mode: ModeKey;
  transcript: string;
}

export interface TransformInput {
  action: TransformAction;
  input: string;
  mode?: ModeKey;
}

export async function transcribeAudio(
  input: TranscriptionInput,
): Promise<TranscriptionResult> {
  const env = getEnv();

  if (!env.openAiApiKey) {
    throw new Error("Missing required environment variable: OPENAI_API_KEY");
  }

  const formData = new FormData();
  formData.append(
    "file",
    new File([input.audio], input.fileName, { type: input.mimeType }),
  );
  formData.append("model", env.openAiTranscriptionModel);
  formData.append("response_format", "verbose_json");

  const response = await fetch("https://api.openai.com/v1/audio/transcriptions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.openAiApiKey}`,
    },
    body: formData,
  });

  if (!response.ok) {
    throw new Error(`OpenAI transcription failed with status ${response.status}`);
  }

  const payload = await response.json() as {
    text?: string;
    duration?: number;
  };

  if (!payload.text?.trim()) {
    throw new Error("OpenAI transcription response did not include text");
  }

  return {
    transcript: payload.text.trim(),
    durationSeconds: payload.duration ?? estimateDurationSeconds(input.audio),
  };
}

export async function polishTranscript(
  input: PolishInput,
): Promise<string> {
  return await generateText({
    instructions: [
      "You rewrite dictated text into a polished final draft.",
      "Preserve the user's meaning exactly.",
      "Do not add facts, names, numbers, or commitments that were not stated.",
      "Remove filler words and false starts.",
      "Fix punctuation and grammar.",
      "Return only the rewritten text with no commentary.",
      modeInstruction(input.mode),
    ].join(" "),
    input: input.transcript,
  });
}

export async function transformText(input: TransformInput): Promise<string> {
  return await generateText({
    instructions: [
      "You transform existing text while preserving its meaning.",
      "Do not invent facts.",
      "Return only the transformed text with no commentary.",
      transformInstruction(input.action),
      input.mode ? `Keep the output appropriate for ${formatModeLabel(input.mode)} mode.` : "",
    ].filter(Boolean).join(" "),
    input: input.input,
  });
}

function formatModeLabel(mode: ModeKey): string {
  return mode
    .split("_")
    .map((segment) => segment[0].toUpperCase() + segment.slice(1))
    .join(" ");
}

function modeInstruction(mode: ModeKey): string {
  switch (mode) {
    case "email":
      return "Format as a concise professional email message.";
    case "text":
      return "Format as a casual, clean text message.";
    case "slack":
      return "Format as a short team-ready Slack update.";
    case "meeting_notes":
      return "Format as clear meeting notes with decisions and action items when present.";
    case "task_list":
      return "Format as a compact checklist with one task per line.";
    case "brain_dump":
      return "Keep the user's original thought flow, but clean it up for readability.";
  }
}

function transformInstruction(action: TransformAction): string {
  switch (action) {
    case "shorter":
      return "Make the text shorter and tighter.";
    case "professional":
      return "Make the text more professional and polished.";
    case "friendly":
      return "Make the text warmer and friendlier.";
    case "bullet_list":
      return "Rewrite the text as a concise bullet list.";
  }
}

async function generateText(
  input: { instructions: string; input: string },
): Promise<string> {
  const env = getEnv();

  if (!env.openAiApiKey) {
    throw new Error("Missing required environment variable: OPENAI_API_KEY");
  }

  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.openAiApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: env.openAiTextModel,
      instructions: input.instructions,
      input: input.input,
      max_output_tokens: 300,
    }),
  });

  if (!response.ok) {
    throw new Error(`OpenAI text generation failed with status ${response.status}`);
  }

  const payload = await response.json() as {
    output_text?: string;
    output?: Array<{
      content?: Array<{
        type?: string;
        text?: string;
      }>;
    }>;
  };

  const text = payload.output_text?.trim() ?? extractOutputText(payload.output);

  if (!text) {
    throw new Error("OpenAI text generation response did not include text");
  }

  return text;
}

function extractOutputText(
  output?: Array<{ content?: Array<{ type?: string; text?: string }> }>,
): string {
  if (!output) {
    return "";
  }

  return output
    .flatMap((item) => item.content ?? [])
    .filter((content) => content.type === "output_text" || content.type === "text" || content.text)
    .map((content) => content.text?.trim() ?? "")
    .filter(Boolean)
    .join("\n")
    .trim();
}

function estimateDurationSeconds(audio: Blob): number {
  return audio.size > 0 ? Math.max(1, Math.round(audio.size / 16000)) : 1;
}
