import { cache } from 'react'
import { createClient } from '@/lib/supabase/server'

/**
 * Canonical server-side helper to retrieve the authenticated user.
 * Wrapped in React `cache()` to deduplicate user lookup calls 
 * within a single Server Component request render lifecycle.
 */
export const getCurrentUser = cache(async () => {
  const supabase = await createClient()
  const { data: { user }, error } = await supabase.auth.getUser()
  if (error || !user) return null
  return user
})
