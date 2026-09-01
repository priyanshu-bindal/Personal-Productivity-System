import { Suspense } from "react"
import { getCurrentUser } from '@/lib/auth'
import { getTodaySessions, getSkills } from "@/lib/actions"
import { redirect } from "next/navigation"
import { TodayDashboardClient } from "@/components/dashboard/TodayDashboardClient"

export const metadata = {
  title: 'Today | FocusFlow',
}

async function DashboardContent() {
  const user = await getCurrentUser()
  if (!user) {
    redirect('/auth/signin')
  }

  const [todaySessions, skills] = await Promise.all([
    getTodaySessions(),
    getSkills()
  ])

  const userFirstName = user?.user_metadata?.full_name?.split(' ')[0] || 'there'

  return (
    <div className="p-4 md:p-10 max-w-6xl mx-auto space-y-8 pb-24 md:pb-10">
      <TodayDashboardClient 
        todaySessions={todaySessions} 
        skills={skills} 
        userFirstName={userFirstName} 
      />
    </div>
  )
}

export default function DashboardPage() {
  return (
    <Suspense fallback={<div className="p-10 flex justify-center"><div className="animate-pulse h-8 w-32 bg-muted rounded"></div></div>}>
      <DashboardContent />
    </Suspense>
  )
}
