'use client'

import { useState, useEffect, Suspense } from 'react'
import { usePathname, useSearchParams } from 'next/navigation'
import { Loader2 } from 'lucide-react'

function NavLoadingContent() {
  const pathname = usePathname()
  const searchParams = useSearchParams()
  const [isNavigating, setIsNavigating] = useState(false)

  // Hide loader as soon as pathname or searchParams change (page finished loading)
  useEffect(() => {
    setIsNavigating(false)
  }, [pathname, searchParams])

  // Listen to clicks on internal <a> links to show loader immediately
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
        if (href !== currentPath && !href.startsWith(currentPath + '#')) {
          setIsNavigating(true)
        }
      }
    }

    document.addEventListener('click', handleAnchorClick, { capture: true })
    return () => {
      document.removeEventListener('click', handleAnchorClick, { capture: true })
    }
  }, [])

  return (
    <div
      aria-live="polite"
      aria-busy={isNavigating}
      className={`fixed top-4 left-1/2 -translate-x-1/2 z-[60] pointer-events-none transition-all duration-200 ease-in-out ${
        isNavigating 
          ? 'opacity-100 translate-y-0 scale-100' 
          : 'opacity-0 -translate-y-2 scale-95'
      }`}
    >
      <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-card/95 border shadow-md backdrop-blur-md text-foreground">
        <Loader2 className="w-4 h-4 text-primary animate-[spin_0.7s_linear_infinite] motion-reduce:animate-none shrink-0" />
        <span className="text-xs font-medium text-muted-foreground">Loading...</span>
      </div>
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
