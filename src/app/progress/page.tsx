import { Suspense } from "react"
import { createClient } from '@/lib/supabase/server'
import { getProgressStats, getSkills } from "@/lib/actions"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { redirect } from "next/navigation"
import { Activity, Target, Clock, Trophy, Flame } from "lucide-react"
import { ProgressCharts } from "@/components/planning/ProgressCharts"

async function ProgressContent() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    redirect('/auth/signin')
  }

  const [stats, skills] = await Promise.all([
    getProgressStats(),
    getSkills()
  ])

  if (!stats) return null

  // Transform skills into chart data
  const chartData = skills.map((s: any) => ({
    name: s.name,
    level: s.level, // 1-5 or similar if we had a numerical scale, let's use session count for now
    sessions: s.learningSessions?.length || 0,
    hours: Math.round((s.learningSessions?.reduce((acc: number, sess: any) => acc + sess.duration, 0) || 0) / 60)
  })).sort((a: any, b: any) => b.hours - a.hours)

  return (
    <div className="p-6 md:p-10 max-w-6xl mx-auto space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700 pb-24 md:pb-10">
      <header>
        <h1 className="text-3xl md:text-4xl font-bold tracking-tight">Progress & Analytics</h1>
        <p className="text-muted-foreground text-lg mt-2">Track your learning journey and stay consistent.</p>
      </header>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Tasks Completed</CardTitle>
            <Target className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.tasksCompleted}</div>
            <p className="text-xs text-muted-foreground mt-1">
              out of {stats.totalTasks} total tasks
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Learning Hours</CardTitle>
            <Clock className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.learningHours}h</div>
            <p className="text-xs text-muted-foreground mt-1">
              total invested time
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Current Streak</CardTitle>
            <Flame className="h-4 w-4 text-orange-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.streak} days</div>
            <p className="text-xs text-muted-foreground mt-1">
              keep the momentum going
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Skills Tracked</CardTitle>
            <Trophy className="h-4 w-4 text-emerald-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalSkills}</div>
            <p className="text-xs text-muted-foreground mt-1">
              active skills
            </p>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Skill Investment</CardTitle>
            <CardDescription>Hours invested per skill</CardDescription>
          </CardHeader>
          <CardContent>
            {chartData.length > 0 ? (
              <ProgressCharts data={chartData} />
            ) : (
              <div className="py-12 text-center text-muted-foreground flex flex-col items-center">
                <Activity className="h-10 w-10 mb-2 opacity-20" />
                No activity yet. Start logging learning sessions from the Skills page.
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

export default function ProgressPage() {
  return (
    <Suspense fallback={<div className="p-10 flex justify-center"><div className="animate-pulse h-8 w-32 bg-muted rounded"></div></div>}>
      <ProgressContent />
    </Suspense>
  )
}
