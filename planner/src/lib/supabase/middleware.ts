import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request,
  })

  const { pathname } = request.nextUrl
  const isAuthRoute = pathname.startsWith('/auth') || pathname.startsWith('/api/auth')
  const allCookies = request.cookies.getAll()
  const hasAuthCookie = allCookies.some(c => 
    c.name.includes('sb-') || 
    c.name.includes('auth-token') || 
    c.name.includes('supabase')
  )

  // Fast-path 1: Unauthenticated user accessing auth route -> Allow through instantly
  if (isAuthRoute && !hasAuthCookie) {
    return supabaseResponse
  }

  // Fast-path 2: Unauthenticated user accessing protected route -> Redirect to signin instantly (<10ms)
  if (!isAuthRoute && !hasAuthCookie) {
    const url = request.nextUrl.clone()
    url.pathname = '/auth/signin'
    return NextResponse.redirect(url)
  }

  // Fast-path 3: Authenticated user accessing protected route -> Allow through instantly
  // Server components handle user identity verification via React cache(getCurrentUser)
  if (!isAuthRoute && hasAuthCookie) {
    return supabaseResponse
  }

  // Only run network getUser() lookup if user has auth cookie AND is visiting /auth/signin or /auth/signup
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return allCookies
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value))
          supabaseResponse = NextResponse.next({
            request,
          })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (user && isAuthRoute && !pathname.startsWith('/api/auth')) {
    const url = request.nextUrl.clone()
    url.pathname = '/'
    return NextResponse.redirect(url)
  }

  return supabaseResponse
}
