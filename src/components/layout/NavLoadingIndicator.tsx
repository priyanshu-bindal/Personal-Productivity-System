'use client'

import { useState, useEffect, useRef, Suspense } from 'react'
import { usePathname, useSearchParams } from 'next/navigation'
import { TrafficLoader } from '@/components/ui/traffic-loader'

function NavLoadingContent() {
  const pathname = usePathname()
  const searchParams = useSearchParams()
  const [isVisible, setIsVisible] = useState(false)
  const timerRef = useRef<NodeJS.Timeout | null>(null)

  const startLoading = (delay = 120) => {
    if (timerRef.current) clearTimeout(timerRef.current)
    timerRef.current = setTimeout(() => {
      setIsVisible(true)
    }, delay)
  }

  const stopLoading = () => {
    if (timerRef.current) {
      clearTimeout(timerRef.current)
      timerRef.current = null
    }
    setIsVisible(false)
  }

  // Hide loader as soon as pathname or searchParams change
  useEffect(() => {
    stopLoading()
  }, [pathname, searchParams])

  // Listen to clicks on internal <a> links to show loader on route / tab navigation
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
        
        // Show traffic loader when navigating to any different route or tab
        if (href !== currentPath && !href.startsWith(currentPath + '#')) {
          startLoading(120)
        }
      }
    }

    const handleVisibilityChange = () => {
      if (document.hidden) {
        startLoading(100)
      } else {
        stopLoading()
      }
    }

    document.addEventListener('click', handleAnchorClick, { capture: true })
    document.addEventListener('visibilitychange', handleVisibilityChange)

    return () => {
      document.removeEventListener('click', handleAnchorClick, { capture: true })
      document.removeEventListener('visibilitychange', handleVisibilityChange)
      if (timerRef.current) clearTimeout(timerRef.current)
    }
  }, [])

  return (
    <div
      aria-live="polite"
      aria-busy={isVisible}
      className={`fixed inset-0 md:left-64 z-50 flex items-center justify-center pb-[20vh] bg-background/60 backdrop-blur-xs pointer-events-none transition-opacity duration-200 ease-in-out ${
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
