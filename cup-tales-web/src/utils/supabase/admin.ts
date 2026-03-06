import { createClient } from '@supabase/supabase-js'

export function createAdminClient() {
    // Bypasses RLS, never expose to client
    return createClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.SUPABASE_SERVICE_ROLE_KEY!
    )
}
