# FlowType Account Deletion Function

This Edge Function deletes the currently authenticated anonymous FlowType account.

## Required secrets

Set these secrets in your Supabase project before deploying:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY` or `SB_PUBLISHABLE_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` or `SB_SECRET_KEY`

## Deploy

```bash
supabase functions deploy account
```

## How it works

1. Reads the caller's bearer token from the `Authorization` header.
2. Verifies the user with a publishable-key client.
3. Deletes that auth user with a separate service-role client.
4. Returns a success response to the iOS app, which then signs out locally and clears drafts on device.
