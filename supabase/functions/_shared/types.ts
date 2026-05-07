export type ModeKey =
  | "email"
  | "text"
  | "slack"
  | "meeting_notes"
  | "task_list"
  | "brain_dump";

export type Source = "keyboard" | "home" | "share" | "unknown" | "transform";

export type TransformAction =
  | "shorter"
  | "professional"
  | "friendly"
  | "bullet_list";

export interface AuthContext {
  userId: string;
  accessToken: string;
}

export interface TranscribeRequest {
  mode: ModeKey;
  source: Source;
}

export interface TranscribeResponse {
  transcript: string;
  durationSeconds: number;
  meta?: {
    mode: ModeKey;
    source: Source;
  };
}

export interface PolishRequest {
  mode: ModeKey;
  transcript: string;
  source: Source;
}

export interface PolishResponse {
  output: string;
  wordCount: number;
  sessionId: string;
}

export interface TransformRequest {
  action: TransformAction;
  input: string;
  mode?: ModeKey;
}

export interface TransformResponse {
  output: string;
  wordCount: number;
  sessionId?: string;
  transformsUsed?: number;
  transformsLimit?: number | null;
  canTransform?: boolean;
}

export interface UsageState {
  plan: "free" | "pro";
  dictationsUsed: number;
  dictationsLimit: number | null;
  transformsUsed: number;
  transformsLimit: number | null;
  weekStart: string;
  audioSecondsUsed: number;
  canDictate: boolean;
  canTransform: boolean;
}

export interface UsageResponse {
  plan: "free" | "pro";
  dictationsUsed: number;
  dictationsLimit: number | null;
  transformsUsed: number;
  transformsLimit: number | null;
  weekStart: string;
  audioSecondsUsed: number;
  canDictate: boolean;
  canTransform: boolean;
}

export interface RevenueCatWebhookEvent {
  event?: {
    id?: string;
    type?: string;
    app_user_id?: string;
    entitlement_ids?: string[];
    product_id?: string | null;
    expiration_at_ms?: number | null;
  };
}

export interface RevenueCatWebhookResponse {
  received: boolean;
  eventId: string;
  eventType: string;
}
