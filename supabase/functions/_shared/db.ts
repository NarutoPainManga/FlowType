import { createClient } from "jsr:@supabase/supabase-js@2";
import { getEnv } from "./env.ts";
import { AuthContext } from "./types.ts";

export function createAdminClient() {
  const env = getEnv();
  const serviceRoleKey = env.supabaseServiceRoleKey;

  if (!serviceRoleKey) {
    throw new Error("Missing required environment variable: SUPABASE_SERVICE_ROLE_KEY");
  }

  return createClient(env.supabaseUrl, serviceRoleKey);
}

export function createUserScopedClient(auth: AuthContext) {
  const env = getEnv();

  if (!auth.accessToken) {
    throw new Error("Missing authenticated access token");
  }

  return createClient(env.supabaseUrl, env.supabaseAnonKey, {
    global: {
      headers: {
        Authorization: `Bearer ${auth.accessToken}`,
      },
    },
  });
}
