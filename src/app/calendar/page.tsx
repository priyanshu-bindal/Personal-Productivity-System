import { Suspense } from "react"
import { getCurrentUser } from '@/lib/auth'
import { getCalendarSessions } from "@/lib/actions"
import { redirect } from "next/navigation"
import { CalendarClient } from "@/components/calendar/CalendarClient"
import { startOfWeek, endOfWeek, format } from "date-fns"

async function CalendarContent() {
  const user = await getCurrentUser()
  if (!user) {
    redirect('/auth/signin')
  }

  const now = new Date()
  const monday = startOfWeek(now, { weekStartsOn: 1 })
  const sunday = endOfWeek(now, { weekStartsOn: 1 })
  const startDateStr = format(monday, 'yyyy-MM-dd')
  const endDateStr = format(sunday, 'yyyy-MM-dd')

  const initialSessions = await getCalendarSessions(startDateStr, endDateStr)

  return (
    <div className="p-6 md:p-10 max-w-7xl mx-auto space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700 pb-24 md:pb-10">
      <CalendarClient initialSessions={initialSessions} />
    </div>
  )
}

import { TrafficLoader } from "@/components/ui/traffic-loader"

export default function CalendarPage() {
  return (
    <Suspense fallback={<div className="p-10 flex justify-center items-center min-h-[40vh]"><TrafficLoader size="md" /></div>}>
      <CalendarContent />
    </Suspense>
  )
}
