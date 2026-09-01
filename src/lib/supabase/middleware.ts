import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request,
  })

  const isAuthRoute = request.nextUrl.pathname.startsWith('/auth') || request.nextUrl.pathname.startsWith('/api/auth')
  const allCookies = request.cookies.getAll()
  const hasAuthCookie = allCookies.some(c => c.name.includes('sb-') || c.name.includes('auth-token'))

  // Fast-path: Unauthenticated visitor accessing /auth/signin or /auth/signup requires no HTTPS user lookup
  if (isAuthRoute && !hasAuthCookie) {
    return supabaseResponse
  }

  // Fast-path: If user has an auth cookie and is accessing a protected route, skip the blocking `getUser()` 
  // network call in middleware. We rely on the Server Components to securely validate the session.
  if (hasAuthCookie && !isAuthRoute) {
    return supabaseResponse
  }

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return allCookies
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => request.cookies.set(name, value))
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

  // Verify and refresh session securely with Supabase Auth (Fallback for auth routes)
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user && !isAuthRoute) {
    const url = request.nextUrl.clone()
    url.pathname = '/auth/signin'
    return NextResponse.redirect(url)
  }

  // If user is already signed in and accesses /auth/signin or /auth/signup, redirect to /
  if (user && isAuthRoute && !request.nextUrl.pathname.startsWith('/api/auth')) {
    const url = request.nextUrl.clone()
    url.pathname = '/'
    return NextResponse.redirect(url)
  }

  return supabaseResponse
}
