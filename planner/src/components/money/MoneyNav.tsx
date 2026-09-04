'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'
import { LayoutGrid, Receipt, PieChart, Wallet } from 'lucide-react'
import { motion } from 'framer-motion'

const tabs = [
  { name: 'Overview', href: '/money', icon: LayoutGrid },
  { name: 'Expenses', href: '/money/expenses', icon: Receipt },
  { name: 'Categories', href: '/money/categories', icon: PieChart },
  { name: 'Budgets', href: '/money/budgets', icon: Wallet },
]

export function MoneyNav() {
  const pathname = usePathname()

  return (
    <div className="border-b mb-6 min-w-0 w-full">
      <nav className="flex gap-1 overflow-x-auto scrollbar-none -mb-px relative min-w-0 w-full py-0.5">
        {tabs.map((tab) => {
          const Icon = tab.icon
          const isActive = pathname === tab.href

          return (
            <Link
              key={tab.name}
              href={tab.href}
              className={cn(
                "relative flex items-center gap-1.5 px-3 py-2 sm:px-4 sm:py-3 text-xs sm:text-sm font-medium whitespace-nowrap transition-colors rounded-t-md shrink-0",
                isActive
                  ? "text-primary font-semibold"
                  : "text-muted-foreground hover:text-foreground"
              )}
            >
              <Icon className="h-3.5 w-3.5 sm:h-4 sm:w-4" />
              <span>{tab.name}</span>

              {isActive && (
                <motion.div
                  layoutId="money-tab-active-indicator"
                  className="absolute bottom-0 left-0 right-0 h-0.5 bg-primary rounded-full"
                  transition={{
                    type: "spring",
                    stiffness: 400,
                    damping: 30,
                  }}
                />
              )}
            </Link>
          )
        })}
      </nav>
    </div>
  )
}
