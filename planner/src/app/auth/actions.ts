'use server'

import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'

export async function login(formData: FormData) {
  const supabase = await createClient()

  const email = (formData.get('email') as string || '').trim()
  const password = (formData.get('password') as string || '').trim()

  if (!email || !password) {
    return { error: 'Incorrect email or password. Please try again.' }
  }

  const { error } = await supabase.auth.signInWithPassword({
    email,
    password,
  })

  if (error) {
    console.error('[SUPABASE LOGIN ERROR]', error.message, error)
    return { error: 'Incorrect email or password. Please try again.' }
  }

  revalidatePath('/', 'layout')
  return { success: true }
}

export async function signup(formData: FormData) {
  const supabase = await createClient()

  const email = (formData.get('email') as string || '').trim()
  const password = (formData.get('password') as string || '').trim()
  const fullName = (formData.get('full_name') as string || '').trim()

  const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        full_name: fullName,
      },
    },
  })

  console.log('[SUPABASE SIGNUP RESULT]', {
    user: signUpData?.user?.id,
    identities: signUpData?.user?.identities,
    session: !!signUpData?.session,
    error: signUpError?.message,
  })

  if (signUpError) {
    console.error('[SUPABASE SIGNUP ERROR]', signUpError)
    const msg = (signUpError.message || '').toLowerCase()
    if (
      msg.includes('already registered') ||
      msg.includes('already in use') ||
      msg.includes('user_already_exists') ||
      msg.includes('already exists') ||
      signUpError.status === 422 ||
      signUpError.code === 'user_already_exists'
    ) {
      return { error: 'An account with this email already exists. Please sign in instead.' }
    }
    return { error: signUpError.message || 'Unable to create account. Please check your details and try again.' }
  }

  // Supabase returns user with empty identities array if user already exists (when email confirmation is enabled)
  if (signUpData.user && signUpData.user.identities && signUpData.user.identities.length === 0) {
    console.warn('[SUPABASE SIGNUP] User already exists (identities array empty)')
    return { error: 'An account with this email already exists. Please sign in instead.' }
  }

  // Auto-login immediately if session was not established directly by signUp
  if (!signUpData.session) {
    const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (signInError) {
      console.error('[SUPABASE AUTO-LOGIN ERROR AFTER SIGNUP]', signInError)
      const msg = (signInError.message || '').toLowerCase()
      if (
        msg.includes('already registered') ||
        msg.includes('user_already_exists') ||
        msg.includes('invalid login credentials')
      ) {
        return { error: 'An account with this email already exists. Please sign in instead.' }
      }
      return { error: signInError.message || 'Account created, but failed to log in automatically. Please sign in.' }
    }
  }

  revalidatePath('/', 'layout')
  return { success: true }
}

export async function signout() {
  const supabase = await createClient()
  await supabase.auth.signOut()
  revalidatePath('/', 'layout')
}
