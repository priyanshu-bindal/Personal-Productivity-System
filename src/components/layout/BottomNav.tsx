'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { 
  LayoutDashboard, 
  CheckSquare, 
  Calendar, 
  Menu,
  IndianRupee,
  Search
} from 'lucide-react'
import { cn } from '@/lib/utils'
import {
  Sheet,
  SheetContent,
  SheetTrigger,
} from "@/components/ui/sheet"
import { BookOpen, Settings, LogOut, Target, TrendingUp, StickyNote } from 'lucide-react'
import { signout } from '@/app/auth/actions'
import { GlobalSearch } from '@/components/GlobalSearch'

const mainNavItems = [
  { name: 'Today', href: '/', icon: LayoutDashboard },
  { name: 'Skills', href: '/skills', icon: BookOpen },
]

const rightNavItems = [
  { name: 'Money', href: '/money', icon: IndianRupee },
]

const moreNavItems = [
  { name: 'Calendar', href: '/calendar', icon: Calendar },
  { name: 'Progress', href: '/progress', icon: TrendingUp },
  { name: 'Notes', href: '/notes', icon: StickyNote },
]

export function BottomNav() {
  const pathname = usePathname()

  return (
    <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-background border-t pb-safe z-50">
      <div className="flex justify-around items-center h-16">
        {mainNavItems.map((item) => {
          const Icon = item.icon
          const isActive = pathname === item.href || pathname.startsWith(item.href + '/')
          
          return (
            <Link
              key={item.name}
              href={item.href}
              className={cn(
                "flex flex-col items-center justify-center w-full h-full space-y-1 text-xs font-medium transition-colors",
                isActive ? "text-primary" : "text-muted-foreground hover:text-foreground"
              )}
            >
              <Icon className="h-5 w-5" />
              <span>{item.name}</span>
            </Link>
          )
        })}
        
        <div className="flex flex-col items-center justify-center w-full h-full">
          <GlobalSearch variant="icon" />
        </div>

        {rightNavItems.map((item) => {
          const Icon = item.icon
          const isActive = pathname === item.href || pathname.startsWith(item.href + '/')
          
          return (
            <Link
              key={item.name}
              href={item.href}
              className={cn(
                "flex flex-col items-center justify-center w-full h-full space-y-1 text-xs font-medium transition-colors",
                isActive ? "text-primary" : "text-muted-foreground hover:text-foreground"
              )}
            >
              <Icon className="h-5 w-5" />
              <span>{item.name}</span>
            </Link>
          )
        })}
        
        <Sheet>
          <SheetTrigger className="flex flex-col items-center justify-center w-full h-full space-y-1 text-xs font-medium text-muted-foreground hover:text-foreground transition-colors">
            <Menu className="h-5 w-5" />
            <span>More</span>
          </SheetTrigger>
          <SheetContent side="bottom" className="h-[80vh] rounded-t-xl">
            <div className="flex flex-col h-full py-4">
              <h2 className="text-lg font-semibold mb-4 px-4">Menu</h2>
              <div className="space-y-1 px-2 flex-1">
                {moreNavItems.map((item) => {
                  const Icon = item.icon
                  const isActive = pathname === item.href
                  
                  return (
                    <Link
                      key={item.name}
                      href={item.href}
                      className={cn(
                        "flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition-colors",
                        isActive 
                          ? "bg-primary/10 text-primary" 
                          : "text-muted-foreground hover:bg-muted hover:text-foreground"
                      )}
                    >
                      <Icon className="h-5 w-5" />
                      {item.name}
                    </Link>
                  )
                })}
              </div>
              
              <div className="mt-auto px-2 space-y-1 border-t pt-4">
                <Link
                  href="/settings"
                  className="flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium text-muted-foreground hover:bg-muted hover:text-foreground transition-colors"
                >
                  <Settings className="h-5 w-5" />
                  Settings
                </Link>
                <form action={signout} className="w-full">
                  <button type="submit" className="w-full flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium text-muted-foreground hover:bg-muted hover:text-destructive transition-colors">
                    <LogOut className="h-5 w-5" />
                    Logout
                  </button>
                </form>
              </div>
            </div>
          </SheetContent>
        </Sheet>
      </div>
    </nav>
  )
}
