import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url)
  const code = searchParams.get('code')
  const next = searchParams.get('next') ?? '/'

  // Capture any error message passed by Supabase Auth (e.g. otp_expired)
  const queryError = searchParams.get('error_description') || searchParams.get('error')

  if (code) {
    const supabase = await createClient()
    const { error } = await supabase.auth.exchangeCodeForSession(code)
    
    if (!error) {
      const forwardedHost = request.headers.get('x-forwarded-host')
      const isLocalEnv = process.env.NODE_ENV === 'development'
      
      if (isLocalEnv) {
        return NextResponse.redirect(`${origin}${next}`)
      } else if (forwardedHost) {
        return NextResponse.redirect(`https://${forwardedHost}${next}`)
      } else {
        return NextResponse.redirect(`${origin}${next}`)
      }
    }
  }

  // If error occurs or code is invalid/expired, redirect to signin with user-friendly error
  const displayError = queryError && queryError !== 'access_denied' 
    ? queryError 
    : 'Verification link is invalid or has expired.'

  return NextResponse.redirect(`${origin}/auth/signin?error=${encodeURIComponent(displayError)}`)
}
