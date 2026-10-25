// Vitalog — delete the signed-in user's own account.
//
// The publishable key cannot delete auth users, so the app calls this edge
// function with its session token. The function verifies that token, then
// deletes the auth user with the service role seat (SUPABASE_SERVICE_ROLE_KEY,
// injected by the platform). Deleting the auth row cascades, by the FKs
// in schema.sql / schema_restore.sql, to every row the account owns:
// reports, lab_results and family_members. Nothing outside the account is
// in scope or reachable.
//
// Deploy once per project (dashboard → Edge Functions → create
// "delete-account", paste this, or `supabase functions deploy delete-account`).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

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
  if (delError) return new Response(delError.message, { status: 500 })

  return new Response('deleted', { status: 200 })
})
