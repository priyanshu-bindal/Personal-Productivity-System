import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request,
  })

  const { pathname } = request.nextUrl

  // Ignore static assets or file paths containing file extension dot
  if (
    pathname.startsWith('/_next') || 
    pathname.startsWith('/api') || 
    pathname === '/favicon.ico' || 
    pathname === '/icon.png' ||
    /\.[a-zA-Z0-9]+$/.test(pathname)
  ) {
    return supabaseResponse
  }

  const isAuthRoute = pathname.startsWith('/auth') || pathname.startsWith('/api/auth')
  const allCookies = request.cookies.getAll()
  const hasAuthCookie = allCookies.some(c => 
    c.name.includes('sb-') || 
    c.name.includes('auth-token') || 
    c.name.includes('supabase')
  )

  // Fast-path 1: Unauthenticated user accessing public auth route -> Allow through instantly
  if (isAuthRoute && !hasAuthCookie) {
    return supabaseResponse
  }

  // Fast-path 2: Unauthenticated user accessing protected route -> Redirect to signin
  if (!isAuthRoute && !hasAuthCookie) {
    return NextResponse.redirect(new URL('/auth/signin', request.url))
  }

  // Fast-path 3: Authenticated user accessing protected route -> Allow through instantly
  if (!isAuthRoute && hasAuthCookie) {
    return supabaseResponse
  }

  // Environment variable fail-safe check to prevent runtime crashes on Vercel
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

  if (!supabaseUrl || !supabaseAnonKey) {
    return supabaseResponse
  }

  try {
    // Only run network getUser() lookup if user has auth cookie AND is visiting /auth/signin or /auth/signup
    const supabase = createServerClient(
      supabaseUrl,
      supabaseAnonKey,
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
      return NextResponse.redirect(new URL('/', request.url))
    }
  } catch (error) {
    console.error('[SUPABASE PROXY ERROR]', error)
    return supabaseResponse
  }

  return supabaseResponse
}
