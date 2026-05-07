export type JsonRecord = Record<string, unknown>;

export type HttpMethod = "GET" | "POST" | "OPTIONS";

export interface ErrorPayload {
  error: {
    code: string;
    message: string;
    details?: JsonRecord;
  };
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-revenuecat-signature",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

export function handleCors(request: Request): Response | null {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  return null;
}

export function methodNotAllowed(allowed: HttpMethod[]): Response {
  return jsonResponse(
    {
      error: {
        code: "method_not_allowed",
        message: `Allowed methods: ${allowed.join(", ")}`,
      },
    },
    405,
  );
}

export function jsonResponse(payload: JsonRecord, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json; charset=utf-8",
    },
  });
}

export function errorResponse(
  code: string,
  message: string,
  status = 400,
  details?: JsonRecord,
): Response {
  return jsonResponse(
    {
      error: {
        code,
        message,
        ...(details ? { details } : {}),
      },
    },
    status,
  );
}

export async function parseJsonBody<T>(request: Request): Promise<T> {
  return await request.json() as T;
}

export async function parseMultipartForm(request: Request): Promise<FormData> {
  return await request.formData();
}
