# FlowType Account Deletion Function

This Edge Function deletes the currently authenticated anonymous FlowType account.

## Required secrets

Supabase-hosted Edge Functions already receive these defaults automatically:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

This function also accepts `SUPABASE_PUBLISHABLE_KEY` / `SB_PUBLISHABLE_KEY` and
`SB_SECRET_KEY` as fallbacks, but you usually do not need to set anything extra.

## Deploy

```bash
supabase functions deploy account
```

## How it works

1. Reads the caller's bearer token from the `Authorization` header.
2. Verifies the user with a publishable or anon-key client.
3. Deletes that auth user with a separate service-role client.
4. Returns a success response to the iOS app, which then signs out locally and clears drafts on device.
