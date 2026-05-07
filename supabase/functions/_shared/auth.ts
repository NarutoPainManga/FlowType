import { createClient } from "jsr:@supabase/supabase-js@2";
import { getEnv } from "./env.ts";
import { AuthContext } from "./types.ts";

export async function requireAuth(request: Request): Promise<AuthContext> {
  const authHeader = request.headers.get("Authorization");

  if (!authHeader?.startsWith("Bearer ")) {
    throw new Error("Missing bearer token");
  }

  const accessToken = authHeader.slice("Bearer ".length);
  const env = getEnv();
  const supabase = createClient(env.supabaseUrl, env.supabaseAnonKey, {
    global: {
      headers: {
        Authorization: authHeader,
      },
    },
  });
  const { data, error } = await supabase.auth.getUser(accessToken);

  if (error || !data.user) {
    throw new Error("Invalid or expired token");
  }

  return {
    userId: data.user.id,
    accessToken,
  };
}
