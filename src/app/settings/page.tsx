import { getUserProfile } from '@/lib/settings-actions'
import { SettingsClient } from '@/components/settings/SettingsClient'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export const metadata = {
  title: 'Settings | FocusFlow',
  description: 'Manage your account details, practice preferences, theme, and data privacy.'
}

import { getCurrentUser } from '@/lib/auth'

export default async function SettingsPage() {
  const user = await getCurrentUser()

  if (!user) {
    redirect('/auth/signin')
  }

  const profile = await getUserProfile()

  if (!profile) {
    redirect('/auth/signin')
  }

  return (
    <div className="p-4 md:p-10 max-w-6xl mx-auto space-y-8 pb-24 md:pb-10">
      <SettingsClient initialProfile={profile} />
    </div>
  )
}
