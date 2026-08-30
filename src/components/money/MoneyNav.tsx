'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'
import { LayoutGrid, Receipt, PieChart, Wallet } from 'lucide-react'

const tabs = [
  { name: 'Overview', href: '/money', icon: LayoutGrid },
  { name: 'Expenses', href: '/money/expenses', icon: Receipt },
  { name: 'Categories', href: '/money/categories', icon: PieChart },
  { name: 'Budgets', href: '/money/budgets', icon: Wallet },
]

export function MoneyNav() {
  const pathname = usePathname()

  return (
    <div className="border-b mb-6">
      <nav className="flex gap-1 overflow-x-auto scrollbar-none -mb-px">
        {tabs.map((tab) => {
          const Icon = tab.icon
          const isActive = pathname === tab.href
          return (
            <Link
              key={tab.name}
              href={tab.href}
              className={cn(
                "flex items-center gap-2 px-4 py-3 text-sm font-medium whitespace-nowrap border-b-2 transition-colors",
                isActive
                  ? "border-primary text-primary"
                  : "border-transparent text-muted-foreground hover:text-foreground hover:border-muted-foreground/30"
              )}
            >
              <Icon className="h-4 w-4" />
              {tab.name}
            </Link>
          )
        })}
      </nav>
    </div>
  )
}
