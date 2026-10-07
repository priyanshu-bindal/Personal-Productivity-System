import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export const dynamic = 'force-dynamic'

/**
 * GET /api/auth/me
 * Returns whether the current user is an authorized announcement admin.
 * Used by client components (e.g. Sidebar) to selectively show admin controls.
 */
export async function GET(_req: NextRequest) {
  try {
    const supabase = await createClient()
    const {
      data: { user },
      error
    } = await supabase.auth.getUser()

    if (error || !user) {
      return NextResponse.json({ authenticated: false, isAdmin: false })
    }

    const adminUid = process.env.ANNOUNCEMENT_ADMIN_USER_ID
    const isAdmin = Boolean(adminUid && user.id === adminUid.trim())

    return NextResponse.json({
      authenticated: true,
      email: user.email,
      isAdmin,
    })
  } catch (err: any) {
    return NextResponse.json({ authenticated: false, isAdmin: false }, { status: 500 })
  }
}
