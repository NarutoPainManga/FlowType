import {
  ModeKey,
  PolishRequest,
  Source,
  TransformAction,
  TransformRequest,
  TranscribeRequest,
} from "./types.ts";

const MODE_KEYS: ModeKey[] = [
  "email",
  "text",
  "slack",
  "meeting_notes",
  "task_list",
  "brain_dump",
];

const SOURCES: Source[] = ["keyboard", "home", "share", "unknown"];

const TRANSFORM_ACTIONS: TransformAction[] = [
  "shorter",
  "professional",
  "friendly",
  "bullet_list",
];

export function validateTranscribeBody(value: unknown): TranscribeRequest {
  const payload = ensureRecord(value);

  return {
    mode: validateMode(payload.mode),
    source: validateSource(payload.source),
  };
}

export function validatePolishBody(value: unknown): PolishRequest {
  const payload = ensureRecord(value);

  return {
    mode: validateMode(payload.mode),
    transcript: validateString(payload.transcript, "transcript", 1),
    source: validateSource(payload.source),
  };
}

export function validateTransformBody(value: unknown): TransformRequest {
  const payload = ensureRecord(value);

  return {
    action: validateTransformAction(payload.action),
    input: validateString(payload.input, "input", 1),
    mode: payload.mode === undefined ? undefined : validateMode(payload.mode),
  };
}

export function validateMode(value: unknown): ModeKey {
  const mode = validateString(value, "mode");

  if (!MODE_KEYS.includes(mode as ModeKey)) {
    throw new Error(`Invalid mode: ${mode}`);
  }

  return mode as ModeKey;
}

export function validateSource(value: unknown): Source {
  const source = validateString(value, "source");

  if (!SOURCES.includes(source as Source)) {
    throw new Error(`Invalid source: ${source}`);
  }

  return source as Source;
}

export function validateTransformAction(value: unknown): TransformAction {
  const action = validateString(value, "action");

  if (!TRANSFORM_ACTIONS.includes(action as TransformAction)) {
    throw new Error(`Invalid action: ${action}`);
  }

  return action as TransformAction;
}

export function validateString(
  value: unknown,
  field: string,
  minLength = 0,
): string {
  if (typeof value !== "string") {
    throw new Error(`Expected ${field} to be a string`);
  }

  const trimmed = value.trim();

  if (trimmed.length < minLength) {
    throw new Error(`Expected ${field} to have length >= ${minLength}`);
  }

  return trimmed;
}

function ensureRecord(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("Expected request body to be a JSON object");
  }

  return value as Record<string, unknown>;
}
