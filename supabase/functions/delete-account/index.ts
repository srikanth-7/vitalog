// Vitalog — delete the signed-in user's own account.
//
// The publishable key cannot delete auth users, so the app calls this edge
// function with its session token. The function verifies that token, then
// deletes the auth user with the service role seat (SUPABASE_SERVICE_ROLE_KEY,
// injected by the platform). Deleting the auth row cascades, by the FKs
// in schema.sql, to the account's key and its access rows (profile_keys).
// A profile nobody else shares then goes with its sealed reports (trigger
// drop_orphan_profile); one shared with family stays theirs.
//
// Deploy once per project (dashboard → Edge Functions → create
// "delete-account", paste this, or `supabase functions deploy delete-account`).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.4'
// Pinned exactly (security audit #10): bump on purpose, after reading the changelog.

Deno.serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { autoRefreshToken: false, persistSession: false } },
  )

  const token = (req.headers.get('Authorization') ?? '').replace(
    'Bearer ',
    '',
  ).trim()
  if (!token) return new Response('Unauthorized', { status: 401 })

  // The user's own session token is the only authorization.
  const { data, error } = await supabase.auth.getUser(token)
  if (error || !data.user) return new Response('Unauthorized', { status: 401 })

  const { error: delError } = await supabase.auth.admin.deleteUser(data.user.id)
  if (delError) {
    // Details stay in the function logs; the caller learns only that it failed.
    console.error('delete-account', data.user.id, delError)
    return new Response('Could not delete the account', { status: 500 })
  }

  return new Response('deleted', { status: 200 })
})
