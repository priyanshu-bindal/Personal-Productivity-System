'use server'

import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'

import { getCurrentUser } from '@/lib/auth'

export async function getUserProfile() {
  const user = await getCurrentUser()
  if (!user) return null
  const supabase = await createClient()

  let { data: profile, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single()

  if (error || !profile) {
    // Upsert fallback profile if not created during signup
    const { data: newProfile } = await supabase
      .from('profiles')
      .upsert({ 
        id: user.id, 
        full_name: user.user_metadata?.full_name || '', 
        avatar_url: user.user_metadata?.avatar_url || '' 
      })
      .select('*')
      .single()

    profile = newProfile || {}
  }

  return {
    id: user.id,
    email: user.email || '',
    fullName: profile?.full_name || user.user_metadata?.full_name || '',
    avatarUrl: profile?.avatar_url || user.user_metadata?.avatar_url || '',
    defaultSessionDuration: profile?.default_session_duration || 60,
    practiceReminders: profile?.practice_reminders ?? true,
    dailyReminderTime: profile?.daily_reminder_time || '09:00'
  }
}

export async function updateProfile(data: { fullName?: string; avatarUrl?: string }) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")

  const updateData: any = {}
  if (data.fullName !== undefined) updateData.full_name = data.fullName
  if (data.avatarUrl !== undefined) updateData.avatar_url = data.avatarUrl

  const { error } = await supabase.from('profiles').update(updateData).eq('id', user.id)
  if (error) throw new Error(error.message)

  // Update user_metadata in Auth
  if (data.fullName !== undefined) {
    await supabase.auth.updateUser({ data: { full_name: data.fullName } })
  }

  revalidatePath('/settings')
}

export async function updatePreferences(data: { 
  defaultSessionDuration?: number
  practiceReminders?: boolean
  dailyReminderTime?: string
}) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")

  const updateData: any = {}
  if (data.defaultSessionDuration !== undefined) updateData.default_session_duration = data.defaultSessionDuration
  if (data.practiceReminders !== undefined) updateData.practice_reminders = data.practiceReminders
  if (data.dailyReminderTime !== undefined) updateData.daily_reminder_time = data.dailyReminderTime

  let { error } = await supabase.from('profiles').update(updateData).eq('id', user.id)

  // Fallback if migration 003 columns aren't ready
  if (error && error.code === 'PGRST204') {
    console.warn('Preference columns not in DB schema yet, skipped DB update')
  } else if (error) {
    throw new Error(error.message)
  }

  revalidatePath('/settings')
}

export async function changePassword(newPassword: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")

  if (!newPassword || newPassword.length < 6) {
    throw new Error("Password must be at least 6 characters long")
  }

  const { error } = await supabase.auth.updateUser({ password: newPassword })
  if (error) throw new Error(error.message)
}

export async function exportUserData() {
  const user = await getCurrentUser()
  if (!user) throw new Error("Unauthorized")
  const supabase = await createClient()

  const [
    { data: skills },
    { data: sessions },
    { data: notes },
    { data: expenses },
    { data: goals },
    { data: budgets }
  ] = await Promise.all([
    supabase.from('skills').select('*').eq('user_id', user.id),
    supabase.from('learning_sessions').select('*').eq('user_id', user.id),
    supabase.from('notes').select('*').eq('user_id', user.id),
    supabase.from('expenses').select('*').eq('user_id', user.id),
    supabase.from('goals').select('*').eq('user_id', user.id),
    supabase.from('budgets').select('*').eq('user_id', user.id)
  ])

  return {
    exportDate: new Date().toISOString(),
    account: {
      id: user.id,
      email: user.email
    },
    skills: skills || [],
    learningSessions: sessions || [],
    notes: notes || [],
    expenses: expenses || [],
    goals: goals || [],
    budgets: budgets || []
  }
}

export async function deleteAccountData() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")

  // Safely clean up user-owned records
  await Promise.all([
    supabase.from('skills').delete().eq('user_id', user.id),
    supabase.from('learning_sessions').delete().eq('user_id', user.id),
    supabase.from('notes').delete().eq('user_id', user.id),
    supabase.from('expenses').delete().eq('user_id', user.id),
    supabase.from('goals').delete().eq('user_id', user.id),
    supabase.from('budgets').delete().eq('user_id', user.id),
    supabase.from('weekly_plans').delete().eq('user_id', user.id),
    supabase.from('profiles').delete().eq('id', user.id)
  ])

  await supabase.auth.signOut()
}
