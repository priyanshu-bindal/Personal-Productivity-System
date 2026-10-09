'use client'

import React from 'react'
import { usePathname } from 'next/navigation'
import { Sidebar } from '@/components/layout/Sidebar'
import { BottomNav } from '@/components/layout/BottomNav'
import { QuickAdd } from '@/components/QuickAdd'

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname()
  const isAuthPage = pathname?.startsWith('/auth')

  if (isAuthPage) {
    return (
      <main className="min-h-screen w-full max-w-full">
        {children}
      </main>
    )
  }

  return (
    <>
      <Sidebar />
      <div className="flex-1 flex flex-col min-h-screen min-w-0 w-full max-w-full md:pl-64 pb-16 md:pb-0">
        <main className="flex-1 min-w-0 w-full max-w-full">
          {children}
        </main>
      </div>
      <BottomNav />
      <QuickAdd />
    </>
  )
}
