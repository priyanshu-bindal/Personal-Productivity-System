import { Suspense } from "react"
import { getCurrentUser } from '@/lib/auth'
import { getProgressStats, getSkills, getWeeklyPlans } from "@/lib/actions"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { redirect } from "next/navigation"
import { CheckCircle2, Flame, Trophy, Clock } from "lucide-react"
import { WeeklyPlanner } from "@/components/planning/WeeklyPlanner"

async function ReviewContent() {
  const user = await getCurrentUser()
  if (!user) {
    redirect('/auth/signin')
  }

  const [stats, skills, initialPlans] = await Promise.all([
    getProgressStats(),
    getSkills(),
    getWeeklyPlans()
  ])

  if (!stats) return null

  // For the weekly review, we typically show this week's stats.
  // We use the global stats as a proxy for the demo, but in a real app,
  // we would fetch stats strictly for the last 7 days.
  
  return (
    <div className="p-6 md:p-10 max-w-6xl mx-auto space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700 pb-24 md:pb-10">
      <header>
        <h1 className="text-3xl md:text-4xl font-bold tracking-tight">Weekly Review</h1>
        <p className="text-muted-foreground text-lg mt-2">Reflect on your past week and plan the next.</p>
      </header>

      <section className="space-y-4">
        <h2 className="text-xl font-semibold">Last Week's Accomplishments</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <Card className="bg-emerald-500/5 border-emerald-500/20">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Tasks Completed</CardTitle>
              <CheckCircle2 className="h-4 w-4 text-emerald-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.tasksCompleted}</div>
            </CardContent>
          </Card>

          <Card className="bg-blue-500/5 border-blue-500/20">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Learning Hours</CardTitle>
              <Clock className="h-4 w-4 text-blue-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.learningHours}h</div>
            </CardContent>
          </Card>

          <Card className="bg-orange-500/5 border-orange-500/20">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Current Streak</CardTitle>
              <Flame className="h-4 w-4 text-orange-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.streak} days</div>
            </CardContent>
          </Card>

          <Card className="bg-primary/5 border-primary/20">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Active Skills</CardTitle>
              <Trophy className="h-4 w-4 text-primary" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalSkills}</div>
            </CardContent>
          </Card>
        </div>
      </section>

      <hr className="my-8" />

      <section className="space-y-4">
        <div className="flex justify-between items-end">
          <div>
            <h2 className="text-xl font-semibold">Plan Next Week</h2>
            <p className="text-muted-foreground text-sm">Drag your skills onto the days you want to practice them.</p>
          </div>
        </div>
        
        <WeeklyPlanner skills={skills} initialPlans={initialPlans} />
      </section>
    </div>
  )
}

export default function ReviewPage() {
  return (
    <Suspense fallback={<div className="p-10 flex justify-center"><div className="animate-pulse h-8 w-32 bg-muted rounded"></div></div>}>
      <ReviewContent />
    </Suspense>
  )
}
