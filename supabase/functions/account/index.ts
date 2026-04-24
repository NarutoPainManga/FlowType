import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'DELETE, OPTIONS',
}

const supabaseURL = Deno.env.get('SUPABASE_URL') ?? ''
const publishableKey =
  Deno.env.get('SUPABASE_PUBLISHABLE_KEY') ??
  Deno.env.get('SUPABASE_ANON_KEY') ??
  Deno.env.get('SB_PUBLISHABLE_KEY') ??
  ''
const serviceRoleKey =
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SB_SECRET_KEY') ?? ''

const userClient = createClient(supabaseURL, publishableKey, {
  auth: { persistSession: false, autoRefreshToken: false },
})

const adminClient = createClient(supabaseURL, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
})

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'DELETE') {
    return Response.json({ error: 'Method not allowed.' }, { status: 405, headers: corsHeaders })
  }

  const authHeader = req.headers.get('Authorization')
  const token = authHeader?.replace('Bearer ', '')

  if (!token) {
    return Response.json({ error: 'Missing authorization token.' }, { status: 401, headers: corsHeaders })
  }

  const { data: userData, error: userError } = await userClient.auth.getUser(token)

  if (userError || !userData.user) {
    return Response.json({ error: 'Invalid session.' }, { status: 401, headers: corsHeaders })
  }

  const { error: deleteError } = await adminClient.auth.admin.deleteUser(userData.user.id, true)

  if (deleteError) {
    console.error('delete-account failed', deleteError)
    return Response.json({ error: deleteError.message }, { status: 500, headers: corsHeaders })
  }

  return Response.json(
    { success: true, userId: userData.user.id },
    { status: 200, headers: corsHeaders }
  )
})
