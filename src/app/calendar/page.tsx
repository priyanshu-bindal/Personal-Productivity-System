import { Suspense } from "react"
import { createClient } from '@/lib/supabase/server'
import { getSkills, getWeeklyPlans } from "@/lib/actions"
import { redirect } from "next/navigation"
import { Card, CardContent } from "@/components/ui/card"
import { Calendar } from "@/components/ui/calendar"
import { format } from "date-fns"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { WeeklyPlanner } from "@/components/planning/WeeklyPlanner"

// Temporary client component just for the standard Calendar state
// In a full implementation, this would fetch tasks for the selected date
import CalendarClient from "./CalendarClient"

async function CalendarContent() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    redirect('/auth/signin')
  }

  const skills = await getSkills()
  const weeklyPlans = await getWeeklyPlans()

  return (
    <div className="p-6 md:p-10 max-w-7xl mx-auto space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <header>
        <h1 className="text-3xl md:text-4xl font-bold tracking-tight">Planning & Schedule</h1>
        <p className="text-muted-foreground text-lg mt-2">Manage your calendar and design your weekly routine.</p>
      </header>

      <Tabs defaultValue="routine" className="w-full">
        <TabsList className="mb-6">
          <TabsTrigger value="routine">Weekly Routine</TabsTrigger>
          <TabsTrigger value="calendar">Calendar</TabsTrigger>
        </TabsList>
        
        <TabsContent value="routine" className="outline-none">
          <WeeklyPlanner skills={skills} initialPlans={weeklyPlans} />
        </TabsContent>
        
        <TabsContent value="calendar" className="outline-none">
          <CalendarClient />
        </TabsContent>
      </Tabs>
    </div>
  )
}

export default function CalendarPage() {
  return (
    <Suspense fallback={<div className="p-10 flex justify-center"><div className="animate-pulse h-8 w-32 bg-muted rounded"></div></div>}>
      <CalendarContent />
    </Suspense>
  )
}
