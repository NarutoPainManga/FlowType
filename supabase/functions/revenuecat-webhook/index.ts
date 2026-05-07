import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { getEnv } from "../_shared/env.ts";
import {
  errorResponse,
  handleCors,
  jsonResponse,
  methodNotAllowed,
  parseJsonBody,
} from "../_shared/http.ts";
import { RevenueCatWebhookEvent, RevenueCatWebhookResponse } from "../_shared/types.ts";
import { recordSubscriptionSnapshot } from "../_shared/usage.ts";
import { toIsoOrNull } from "../_shared/utils.ts";

serve(async (request) => {
  const cors = handleCors(request);
  if (cors) return cors;

  if (request.method !== "POST") {
    return methodNotAllowed(["POST", "OPTIONS"]);
  }

  try {
    const env = getEnv();
    const signature = request.headers.get("x-revenuecat-signature");

    if (env.revenueCatWebhookSecret && signature !== env.revenueCatWebhookSecret) {
      return errorResponse("invalid_signature", "RevenueCat webhook signature mismatch", 401);
    }

    const payload = await parseJsonBody<RevenueCatWebhookEvent>(request);

    if (!payload.event?.id || !payload.event?.type) {
      return errorResponse("invalid_payload", "Missing RevenueCat event id or type");
    }

    await recordSubscriptionSnapshot({
      userId: payload.event.app_user_id,
      entitlement: payload.event.entitlement_ids?.[0] ?? "pro",
      status: payload.event.type,
      productId: payload.event.product_id ?? null,
      expiresAt: toIsoOrNull(payload.event.expiration_at_ms),
    });

    const response: RevenueCatWebhookResponse = {
      received: true,
      eventId: payload.event.id,
      eventType: payload.event.type,
    };

    return jsonResponse(response);
  } catch (error) {
    return errorResponse(
      "revenuecat_webhook_failed",
      error instanceof Error ? error.message : "Unknown RevenueCat webhook error",
      400,
    );
  }
});
