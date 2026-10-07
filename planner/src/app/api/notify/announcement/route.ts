import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { sendAnnouncementToAllDevices } from '@/lib/firebase/announcementSender'

export const dynamic = 'force-dynamic'

/**
 * POST /api/notify/announcement
 *
 * Security model:
 *  1. Reads the authenticated Supabase session from the httpOnly cookie.
 *  2. Gets the authenticated Supabase user ID — never from the request body.
 *  3. Compares it against ANNOUNCEMENT_ADMIN_USER_ID (server-only env var).
 *  4. Rejects with 403 if the user is not the configured admin.
 *  5. Only then dispatches the announcement via Firebase Admin SDK.
 *
 * Nothing in the request body is trusted for authorization.
 */
export async function POST(req: NextRequest) {
  console.log('[ANNOUNCEMENT API] Request received')

  // ── 1. Authenticate via server-side Supabase session ──────────────────────
  const supabase = await createClient()
  const {
    data: { user },
    error: authError
  } = await supabase.auth.getUser()

  if (authError || !user) {
    console.warn('[ANNOUNCEMENT API] Unauthenticated request rejected')
    return NextResponse.json({ error: 'Authentication required.' }, { status: 401 })
  }

  // ── 2. Authorize — compare against server-only admin UID ──────────────────
  const adminUid = process.env.ANNOUNCEMENT_ADMIN_USER_ID
  if (!adminUid || adminUid.trim() === '') {
    console.error('[ANNOUNCEMENT API] ANNOUNCEMENT_ADMIN_USER_ID is not configured')
    return NextResponse.json(
      { error: 'Announcement system is not configured.' },
      { status: 503 }
    )
  }

  if (user.id !== adminUid.trim()) {
    console.warn(`[ANNOUNCEMENT API] Forbidden — user ${user.id} is not the admin`)
    return NextResponse.json(
      { error: 'You do not have permission to send announcements.' },
      { status: 403 }
    )
  }

  console.log('[ANNOUNCEMENT API] Admin authorized')

  // ── 3. Parse and validate request body ────────────────────────────────────
  let body: any
  try {
    body = await req.json()
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body.' }, { status: 400 })
  }

  const title = typeof body?.title === 'string' ? body.title.trim() : ''
  const message = typeof body?.message === 'string' ? body.message.trim() : ''
  const route = typeof body?.route === 'string' ? body.route.trim() : undefined

  if (!title) {
    return NextResponse.json({ error: 'Announcement title is required.' }, { status: 400 })
  }
  if (!message) {
    return NextResponse.json({ error: 'Announcement message is required.' }, { status: 400 })
  }
  if (title.length > 100) {
    return NextResponse.json({ error: 'Title must be 100 characters or fewer.' }, { status: 400 })
  }
  if (message.length > 500) {
    return NextResponse.json({ error: 'Message must be 500 characters or fewer.' }, { status: 400 })
  }

  console.log(`[ANNOUNCEMENT API] Sending: "${title}"`)

  // ── 4. Dispatch via Firebase Admin ────────────────────────────────────────
  try {
    const result = await sendAnnouncementToAllDevices({
      title,
      message,
      route: route || undefined,
      sentBy: user.id
    })

    console.log(
      `[ANNOUNCEMENT API] Done — id=${result.announcementId}, total=${result.totalDevices}, success=${result.successCount}, failure=${result.failureCount}`
    )

    return NextResponse.json({
      success: true,
      announcementId: result.announcementId,
      recipientUsers: result.recipientUsers,
      deviceCount: result.deviceCount,
      uniqueTokens: result.uniqueTokens,
      totalDevices: result.totalDevices,
      successCount: result.successCount,
      failureCount: result.failureCount
    })
  } catch (err: any) {
    console.error('[ANNOUNCEMENT API] Error during send:', err?.message)
    return NextResponse.json(
      { error: 'Failed to send announcement. Please try again.' },
      { status: 500 }
    )
  }
}

/**
 * GET /api/notify/announcement
 * Returns recent announcements for the authenticated admin,
 * or server-side Firestore device diagnostics if ?diagnostic=true.
 */
export async function GET(req: NextRequest) {
  const supabase = await createClient()
  const {
    data: { user },
    error: authError
  } = await supabase.auth.getUser()

  if (authError || !user) {
    return NextResponse.json({ error: 'Authentication required.' }, { status: 401 })
  }

  const adminUid = process.env.ANNOUNCEMENT_ADMIN_USER_ID
  if (!adminUid || user.id !== adminUid.trim()) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  const isDiagnostic = req.nextUrl.searchParams.get('diagnostic') === 'true'
  if (isDiagnostic) {
    const { getAnnouncementDiagnostics } = await import('@/lib/firebase/announcementSender')
    const diagnostic = await getAnnouncementDiagnostics()
    return NextResponse.json({ diagnostic })
  }

  const { getRecentAnnouncements } = await import('@/lib/firebase/announcementSender')
  const announcements = await getRecentAnnouncements(10)
  return NextResponse.json({ announcements })
}

