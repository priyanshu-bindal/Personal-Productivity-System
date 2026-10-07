import { getCurrentUser } from '@/lib/auth'
import { redirect } from 'next/navigation'
import { AnnouncementAdminClient } from './AnnouncementAdminClient'

export const metadata = {
  title: 'Announcements | Admin | FocusFlow',
  description: 'Send broadcast announcements to FocusFlow users.',
}

/**
 * Protected Admin Announcement Page (/admin/announcements).
 *
 * Strict multi-layer authorization:
 * 1. Checks server-side authenticated Supabase session.
 * 2. Compares user.id strictly against ANNOUNCEMENT_ADMIN_USER_ID environment variable.
 * 3. If unauthenticated -> redirects to sign in.
 * 4. If not the authorized admin UID -> renders 403 Forbidden state, never the form.
 */
export default async function AdminAnnouncementsPage() {
  const user = await getCurrentUser()

  if (!user) {
    redirect('/auth/signin?next=/admin/announcements')
  }

  const adminUid = process.env.ANNOUNCEMENT_ADMIN_USER_ID
  const isAuthorized = !!adminUid && user.id === adminUid.trim()

  if (!isAuthorized) {
    return (
      <div className="min-h-[70vh] flex items-center justify-center p-6">
        <div className="max-w-md w-full rounded-2xl border border-red-500/20 bg-zinc-950/80 p-8 text-center space-y-4 backdrop-blur-xl">
          <div className="w-12 h-12 rounded-xl bg-red-500/10 border border-red-500/20 flex items-center justify-center mx-auto text-red-400">
            <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          </div>
          <h1 className="text-xl font-semibold text-zinc-100">Access Restricted</h1>
          <p className="text-sm text-zinc-400">
            This administration console is only available to authorized FocusFlow administrators.
          </p>
          <a
            href="/"
            className="inline-block mt-4 text-xs font-medium text-zinc-400 hover:text-zinc-200 transition-colors"
          >
            ← Return to Dashboard
          </a>
        </div>
      </div>
    )
  }

  return (
    <div className="p-4 md:p-10 max-w-4xl mx-auto space-y-8 pb-24 md:pb-10">
      <AnnouncementAdminClient />
    </div>
  )
}
