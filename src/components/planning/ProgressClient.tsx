'use client'

import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Clock, Flame, BookOpen, Target, CheckCircle2, XCircle, Minus } from "lucide-react"
import { format, startOfMonth, endOfMonth, eachDayOfInterval } from "date-fns"

export function ProgressClient({ skills }: { skills: any[] }) {
  const now = new Date()
  const daysInMonth = eachDayOfInterval({
    start: startOfMonth(now),
    end: endOfMonth(now)
  })

  // Compute overall stats
  const totalPlanned = skills.reduce((sum, s) => sum + (s.learningSessions?.length || 0), 0)
  const totalCompleted = skills.reduce((sum, s) => sum + (s.learningSessions?.filter((ls: any) => ls.status === 'completed').length || 0), 0)
  const overallConsistency = skills.length > 0
    ? Math.round(skills.reduce((acc, s) => acc + (s.consistencyPct || 100), 0) / skills.length)
    : 100

  const totalLearningHours = Math.round(skills.reduce((acc, s) => acc + (s.learningHours || 0), 0) * 10) / 10
  const maxSessionStreak = skills.reduce((max, s) => Math.max(max, s.streak || 0), 0)
  const totalWeeklyCompleted = skills.reduce((sum, s) => sum + (s.weeklyCompleted || 0), 0)
  const totalWeeklyTarget = skills.reduce((sum, s) => sum + (s.weeklyTarget || 3), 0)

  // Map all sessions by date for Monthly Activity Calendar & Weekly Comparisons
  const allSessions: any[] = skills.flatMap(s => s.learningSessions || [])

  // Weekly Comparison calculations (this week vs last week)
  const dayOfWeek = now.getDay() || 7
  const monday = new Date(now)
  monday.setDate(now.getDate() - dayOfWeek + 1)
  const startOfThisWeekStr = format(monday, 'yyyy-MM-dd')
  
  const lastMonday = new Date(monday)
  lastMonday.setDate(monday.getDate() - 7)
  const startOfLastWeekStr = format(lastMonday, 'yyyy-MM-dd')
  const endOfLastWeekStr = format(monday, 'yyyy-MM-dd')

  const thisWeekCompletedSessions = allSessions.filter((s: any) => s.status === 'completed' && s.scheduled_date >= startOfThisWeekStr)
  const lastWeekCompletedSessions = allSessions.filter((s: any) => s.status === 'completed' && s.scheduled_date >= startOfLastWeekStr && s.scheduled_date < startOfThisWeekStr)

  const thisWeekMinutes = thisWeekCompletedSessions.reduce((sum: number, s: any) => sum + (s.actual_duration || s.planned_duration || 60), 0)
  const lastWeekMinutes = lastWeekCompletedSessions.reduce((sum: number, s: any) => sum + (s.actual_duration || s.planned_duration || 60), 0)

  const sessionDiff = thisWeekCompletedSessions.length - lastWeekCompletedSessions.length
  const timeDiffMinutes = thisWeekMinutes - lastWeekMinutes

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <header>
        <h1 className="text-3xl md:text-4xl font-bold tracking-tight">Progress & Consistency</h1>
        <p className="text-muted-foreground text-lg mt-1">
          Automatic consistency tracking powered by your actual daily practice sessions.
        </p>
      </header>

      {/* Top Stat Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Overall Consistency</CardTitle>
            <Target className="h-4 w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-primary">{overallConsistency}%</div>
            <p className="text-xs text-muted-foreground mt-1">
              across all active skills
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Learning Time</CardTitle>
            <Clock className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalLearningHours}h</div>
            <p className="text-xs text-muted-foreground mt-1">
              total time invested
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Top Session Streak</CardTitle>
            <Flame className="h-4 w-4 text-orange-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-orange-500">{maxSessionStreak} sessions</div>
            <p className="text-xs text-muted-foreground mt-1">
              consecutive planned sessions
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">This Week</CardTitle>
            <BookOpen className="h-4 w-4 text-emerald-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-emerald-500">{totalWeeklyCompleted} / {totalWeeklyTarget}</div>
            <p className="text-xs text-muted-foreground mt-1">
              sessions completed
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Evidence-Based Weekly Comparison Insights */}
      <Card className="border-emerald-500/30 bg-emerald-500/5">
        <CardHeader className="pb-3">
          <CardTitle className="text-base font-semibold text-emerald-500 flex items-center gap-2">
            <CheckCircle2 className="h-5 w-5" /> Activity Insights & Weekly Trends
          </CardTitle>
          <CardDescription>Measured directly from your recorded practice sessions.</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
            <div className="p-3 border rounded-xl bg-card space-y-1">
              <span className="text-xs text-muted-foreground font-medium">Weekly Comparison</span>
              <p className="font-semibold text-foreground">
                {sessionDiff > 0 ? (
                  <span className="text-emerald-500">↑ {sessionDiff} more session{sessionDiff > 1 ? 's' : ''} completed than last week</span>
                ) : sessionDiff === 0 ? (
                  <span>Maintained same session pace as last week</span>
                ) : (
                  <span className="text-muted-foreground">{Math.abs(sessionDiff)} fewer session{Math.abs(sessionDiff) > 1 ? 's' : ''} than last week</span>
                )}
              </p>
              <p className="text-xs text-muted-foreground">This week: {thisWeekCompletedSessions.length} | Last week: {lastWeekCompletedSessions.length}</p>
            </div>

            <div className="p-3 border rounded-xl bg-card space-y-1">
              <span className="text-xs text-muted-foreground font-medium">Time Invested</span>
              <p className="font-semibold text-foreground">
                {timeDiffMinutes > 0 ? (
                  <span className="text-emerald-500">↑ {timeDiffMinutes}m more practice time than last week</span>
                ) : timeDiffMinutes === 0 ? (
                  <span>Same learning duration as last week</span>
                ) : (
                  <span className="text-muted-foreground">{Math.abs(timeDiffMinutes)}m less practice time than last week</span>
                )}
              </p>
              <p className="text-xs text-muted-foreground">This week: {Math.round(thisWeekMinutes / 60 * 10) / 10}h | Last week: {Math.round(lastWeekMinutes / 60 * 10) / 10}h</p>
            </div>

            <div className="p-3 border rounded-xl bg-card space-y-1">
              <span className="text-xs text-muted-foreground font-medium">Consistency Rating</span>
              <p className="font-semibold text-emerald-500">
                {overallConsistency >= 80 ? '🔥 Excellent Consistency' : overallConsistency >= 50 ? '⚡ Good Progress' : '🌱 Getting Started'}
              </p>
              <p className="text-xs text-muted-foreground">{overallConsistency}% completion across {skills.length} active skill{skills.length !== 1 ? 's' : ''}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Breakdown per Skill */}
      <Card>
        <CardHeader>
          <CardTitle>Skill Performance Breakdown</CardTitle>
          <CardDescription>Real-time performance metrics automatically updated as you complete practice sessions.</CardDescription>
        </CardHeader>
        <CardContent>
          {skills.length === 0 ? (
            <div className="py-8 text-center text-muted-foreground border border-dashed rounded-xl">
              No skills added yet. Create a skill to start tracking consistency!
            </div>
          ) : (
            <div className="space-y-4">
              {skills.map(skill => (
                <div key={skill.id} className="p-4 border rounded-xl space-y-3 bg-card">
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                    <div>
                      <h3 className="font-semibold text-lg">{skill.name}</h3>
                      <p className="text-xs text-muted-foreground">{skill.category} · Target: {skill.weeklyTarget} sessions/wk</p>
                    </div>
                    <div className="flex items-center gap-3">
                      <span className="text-sm font-bold text-emerald-500 px-3 py-1 bg-emerald-500/10 border border-emerald-500/20 rounded-full">
                        {skill.consistencyPct}% Consistency
                      </span>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs pt-1 border-t">
                    <div>
                      <span className="text-muted-foreground block">This Week</span>
                      <span className="font-semibold text-sm">{skill.weeklyCompleted} / {skill.weeklyTarget} sessions</span>
                    </div>
                    <div>
                      <span className="text-muted-foreground block">Session Streak</span>
                      <span className="font-semibold text-sm text-orange-500 flex items-center gap-1">
                        <Flame className="h-3.5 w-3.5 inline" /> {skill.streak} sessions
                      </span>
                    </div>
                    <div>
                      <span className="text-muted-foreground block">Learning Time</span>
                      <span className="font-semibold text-sm">{skill.learningHours}h total</span>
                    </div>
                    <div>
                      <span className="text-muted-foreground block">Month Consistency</span>
                      <span className="font-semibold text-sm">{skill.monthConsistencyPct || 100}%</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Monthly Activity Visual Calendar */}
      <Card>
        <CardHeader>
          <CardTitle>Monthly Practice Activity ({format(now, 'MMMM yyyy')})</CardTitle>
          <CardDescription>
            <span className="text-emerald-500 font-medium">✓</span> = Completed scheduled session &nbsp;|&nbsp; 
            <span className="text-red-500 font-medium"> ✕</span> = Missed/Skipped session &nbsp;|&nbsp; 
            <span className="text-muted-foreground font-medium"> -</span> = No session scheduled
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-7 gap-2 text-center text-xs font-semibold pb-2 border-b">
            <div>Mon</div><div>Tue</div><div>Wed</div><div>Thu</div><div>Fri</div><div>Sat</div><div>Sun</div>
          </div>

          <div className="grid grid-cols-7 gap-2 text-center pt-3 text-sm">
            {/* Offset for start of month */}
            {Array.from({ length: (startOfMonth(now).getDay() || 7) - 1 }).map((_, i) => (
              <div key={`offset-${i}`} className="h-10 border border-transparent"></div>
            ))}

            {daysInMonth.map((day) => {
              const dayStr = format(day, 'yyyy-MM-dd')
              const daySessions = allSessions.filter(s => s.scheduled_date === dayStr)
              const hasCompleted = daySessions.some(s => s.status === 'completed')
              const hasSkipped = daySessions.some(s => s.status === 'skipped' || s.status === 'missed')
              const isPast = dayStr <= format(now, 'yyyy-MM-dd')

              return (
                <div key={dayStr} className="h-12 border rounded-lg p-1 flex flex-col items-center justify-between bg-card">
                  <span className="text-[11px] text-muted-foreground font-mono">{format(day, 'd')}</span>
                  {hasCompleted ? (
                    <span className="text-emerald-500 font-bold text-xs flex items-center justify-center">
                      <CheckCircle2 className="h-3.5 w-3.5" />
                    </span>
                  ) : hasSkipped ? (
                    <span className="text-red-500 font-bold text-xs flex items-center justify-center">
                      <XCircle className="h-3.5 w-3.5" />
                    </span>
                  ) : (
                    <span className="text-muted-foreground text-xs font-bold">-</span>
                  )}
                </div>
              )
            })}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
