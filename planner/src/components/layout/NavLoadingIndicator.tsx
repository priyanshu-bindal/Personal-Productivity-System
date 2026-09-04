'use client'

import { useState, useEffect, useRef, Suspense } from 'react'
import { usePathname, useSearchParams } from 'next/navigation'
import { TrafficLoader } from '@/components/ui/traffic-loader'

function NavLoadingContent() {
  const pathname = usePathname()
  const searchParams = useSearchParams()
  const [isVisible, setIsVisible] = useState(false)
  const timerRef = useRef<NodeJS.Timeout | null>(null)
  const maxTimeoutRef = useRef<NodeJS.Timeout | null>(null)

  const stopLoading = () => {
    if (timerRef.current) {
      clearTimeout(timerRef.current)
      timerRef.current = null
    }
    if (maxTimeoutRef.current) {
      clearTimeout(maxTimeoutRef.current)
      maxTimeoutRef.current = null
    }
    setIsVisible(false)
  }

  const startLoading = (delay = 120) => {
    stopLoading()

    // 1. Show loader after short debounce delay
    timerRef.current = setTimeout(() => {
      setIsVisible(true)
    }, delay)

    // 2. Safety Fallback: Force stop loader after 3.5s to prevent infinite spinning
    maxTimeoutRef.current = setTimeout(() => {
      stopLoading()
    }, 3500)
  }

  // Always stop loader whenever pathname or searchParams change
  useEffect(() => {
    stopLoading()
  }, [pathname, searchParams])

  // Stop loader if user is on an auth route
  useEffect(() => {
    if (pathname?.startsWith('/auth')) {
      stopLoading()
    }
  }, [pathname])

  // Listen to link clicks
  useEffect(() => {
    const handleAnchorClick = (e: MouseEvent) => {
      const target = e.target as HTMLElement | null
      const anchor = target?.closest('a')
      if (!anchor) return

      const href = anchor.getAttribute('href')
      const targetAttr = anchor.getAttribute('target')

      if (
        href && 
        href.startsWith('/') && 
        !href.startsWith('#') &&
        targetAttr !== '_blank' &&
        !e.ctrlKey && 
        !e.metaKey && 
        !e.shiftKey && 
        !e.altKey
      ) {
        const currentPath = window.location.pathname

        // Do not trigger the global traffic loader for links clicked from auth pages (/auth/signin, /auth/signup)
        if (currentPath.startsWith('/auth')) {
          return
        }

        // Show traffic loader when navigating to any different route or tab
        if (href !== currentPath && !href.startsWith(currentPath + '#')) {
          startLoading(120)
        }
      }
    }

    const handlePopState = () => {
      stopLoading()
    }

    const handlePageShow = () => {
      stopLoading()
    }

    document.addEventListener('click', handleAnchorClick, { capture: true })
    window.addEventListener('popstate', handlePopState)
    window.addEventListener('pageshow', handlePageShow)

    return () => {
      document.removeEventListener('click', handleAnchorClick, { capture: true })
      window.removeEventListener('popstate', handlePopState)
      window.removeEventListener('pageshow', handlePageShow)
      stopLoading()
    }
  }, [])

  const isAuthPage = pathname?.startsWith('/auth')

  return (
    <div
      aria-live="polite"
      aria-busy={isVisible}
      className={`fixed inset-0 ${isAuthPage ? '' : 'md:left-64'} z-50 flex items-center justify-center pb-[20vh] bg-background/60 backdrop-blur-xs pointer-events-none transition-opacity duration-200 ease-in-out ${
        isVisible ? 'opacity-100' : 'opacity-0 pointer-events-none'
      }`}
    >
      <TrafficLoader size="md" />
    </div>
  )
}

export function NavLoadingIndicator() {
  return (
    <Suspense fallback={null}>
      <NavLoadingContent />
    </Suspense>
  )
}
