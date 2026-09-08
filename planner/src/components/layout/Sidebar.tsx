'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { 
  LayoutDashboard, 
  BookOpen, 
  CheckSquare, 
  Calendar, 
  Target, 
  TrendingUp, 
  StickyNote, 
  Settings,
  LogOut,
  IndianRupee,
  MessageSquare
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { signout } from '@/app/auth/actions'
import { GlobalSearch } from '@/components/GlobalSearch'

const navItems = [
  { name: 'Today', href: '/', icon: LayoutDashboard },
  { name: 'Messages', href: '/messages', icon: MessageSquare },
  { name: 'My Skills', href: '/skills', icon: BookOpen },
  { name: 'Calendar', href: '/calendar', icon: Calendar },
  { name: 'Progress', href: '/progress', icon: TrendingUp },
  { name: 'Notes', href: '/notes', icon: StickyNote },
  { name: 'Money', href: '/money', icon: IndianRupee },
]

export function Sidebar() {
  const pathname = usePathname()

  return (
    <aside className="hidden md:flex flex-col w-64 bg-card border-r h-screen sticky top-0">
      <div className="p-6">
        <h1 className="text-xl font-bold tracking-tight">FocusFlow</h1>
      </div>
      
      <div className="px-4 mb-4">
        <GlobalSearch />
      </div>
      
      <nav className="flex-1 px-4 space-y-1 overflow-y-auto">
        {navItems.map((item) => {
          const Icon = item.icon
          const isActive = pathname === item.href
          
          return (
            <Link
              key={item.name}
              href={item.href}
              className={cn(
                "flex items-center gap-3 px-3 py-2.5 rounded-md text-sm font-medium transition-colors",
                isActive 
                  ? "bg-primary text-primary-foreground" 
                  : "text-muted-foreground hover:bg-muted hover:text-foreground"
              )}
            >
              <Icon className="h-5 w-5" />
              {item.name}
            </Link>
          )
        })}
      </nav>
      
      <div className="p-4 border-t space-y-1">
        <Link
          href="/settings"
          className="flex items-center gap-3 px-3 py-2.5 rounded-md text-sm font-medium text-muted-foreground hover:bg-muted hover:text-foreground transition-colors"
        >
          <Settings className="h-5 w-5" />
          Settings
        </Link>
        <form action={signout} className="w-full">
          <button
            type="submit"
            className="w-full flex items-center gap-3 px-3 py-2.5 rounded-md text-sm font-medium text-muted-foreground hover:bg-muted hover:text-destructive transition-colors"
          >
            <LogOut className="h-5 w-5" />
            Logout
          </button>
        </form>
      </div>
    </aside>
  )
}
