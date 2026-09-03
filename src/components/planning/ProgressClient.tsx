'use client'

import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Clock, Flame, BookOpen, Target, CheckCircle2, XCircle } from "lucide-react"
import { format, startOfMonth, endOfMonth, eachDayOfInterval } from "date-fns"

export function ProgressClient({ skills }: { skills: any[] }) {
  const now = new Date()
  const daysInMonth = eachDayOfInterval({
    start: startOfMonth(now),
    end: endOfMonth(now)
  })

  // Compute overall stats
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

  const thisWeekCompletedSessions = allSessions.filter((s: any) => s.status === 'completed' && s.scheduled_date >= startOfThisWeekStr)
  const lastWeekCompletedSessions = allSessions.filter((s: any) => s.status === 'completed' && s.scheduled_date >= startOfLastWeekStr && s.scheduled_date < startOfThisWeekStr)

  const thisWeekMinutes = thisWeekCompletedSessions.reduce((sum: number, s: any) => sum + (s.actual_duration || s.planned_duration || 60), 0)
  const lastWeekMinutes = lastWeekCompletedSessions.reduce((sum: number, s: any) => sum + (s.actual_duration || s.planned_duration || 60), 0)

  const sessionDiff = thisWeekCompletedSessions.length - lastWeekCompletedSessions.length
  const timeDiffMinutes = thisWeekMinutes - lastWeekMinutes

  return (
    <div className="space-y-6 sm:space-y-8 min-w-0 w-full animate-in fade-in slide-in-from-bottom-4 duration-500">
      <header className="min-w-0">
        <h1 className="text-2xl sm:text-3xl md:text-4xl font-bold tracking-tight">Progress & Consistency</h1>
        <p className="text-muted-foreground text-xs sm:text-base md:text-lg mt-1">
          Automatic consistency tracking powered by your actual daily practice sessions.
        </p>
      </header>

      {/* Top Stat Cards */}
      <div className="grid grid-cols-2 min-w-0 md:grid-cols-4 gap-3 sm:gap-4">
        <Card className="min-w-0">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 p-3 sm:p-4 pb-1 sm:pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium truncate">Overall Consistency</CardTitle>
            <Target className="h-3.5 w-3.5 sm:h-4 sm:w-4 text-primary shrink-0" />
          </CardHeader>
          <CardContent className="p-3 sm:p-4 pt-0">
            <div className="text-lg sm:text-2xl font-bold text-primary truncate">{overallConsistency}%</div>
            <p className="text-[10px] sm:text-xs text-muted-foreground mt-0.5 truncate">
              across all active skills
            </p>
          </CardContent>
        </Card>

        <Card className="min-w-0">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 p-3 sm:p-4 pb-1 sm:pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium truncate">Learning Time</CardTitle>
            <Clock className="h-3.5 w-3.5 sm:h-4 sm:w-4 text-muted-foreground shrink-0" />
          </CardHeader>
          <CardContent className="p-3 sm:p-4 pt-0">
            <div className="text-lg sm:text-2xl font-bold truncate">{totalLearningHours}h</div>
            <p className="text-[10px] sm:text-xs text-muted-foreground mt-0.5 truncate">
              total time invested
            </p>
          </CardContent>
        </Card>

        <Card className="min-w-0">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 p-3 sm:p-4 pb-1 sm:pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium truncate">Top Session Streak</CardTitle>
            <Flame className="h-3.5 w-3.5 sm:h-4 sm:w-4 text-orange-500 shrink-0" />
          </CardHeader>
          <CardContent className="p-3 sm:p-4 pt-0">
            <div className="text-lg sm:text-2xl font-bold text-orange-500 truncate">{maxSessionStreak} sessions</div>
            <p className="text-[10px] sm:text-xs text-muted-foreground mt-0.5 truncate">
              consecutive sessions
            </p>
          </CardContent>
        </Card>

        <Card className="min-w-0">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 p-3 sm:p-4 pb-1 sm:pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium truncate">This Week</CardTitle>
            <BookOpen className="h-3.5 w-3.5 sm:h-4 sm:w-4 text-emerald-500 shrink-0" />
          </CardHeader>
          <CardContent className="p-3 sm:p-4 pt-0">
            <div className="text-lg sm:text-2xl font-bold text-emerald-500 truncate">{totalWeeklyCompleted} / {totalWeeklyTarget}</div>
            <p className="text-[10px] sm:text-xs text-muted-foreground mt-0.5 truncate">
              sessions completed
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Evidence-Based Weekly Comparison Insights */}
      <Card className="border-emerald-500/30 bg-emerald-500/5 min-w-0">
        <CardHeader className="p-4 sm:p-6 pb-2 sm:pb-3">
          <CardTitle className="text-sm sm:text-base font-semibold text-emerald-500 flex items-center gap-2">
            <CheckCircle2 className="h-4 w-4 sm:h-5 sm:w-5 shrink-0" /> Activity Insights & Weekly Trends
          </CardTitle>
          <CardDescription className="text-xs sm:text-sm">Measured directly from your recorded practice sessions.</CardDescription>
        </CardHeader>
        <CardContent className="p-4 sm:p-6 pt-0 sm:pt-0">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3 sm:gap-4 text-xs sm:text-sm min-w-0">
            <div className="p-3 border rounded-xl bg-card space-y-1 min-w-0">
              <span className="text-[10px] sm:text-xs text-muted-foreground font-medium block">Weekly Comparison</span>
              <p className="font-semibold text-foreground text-xs sm:text-sm">
                {sessionDiff > 0 ? (
                  <span className="text-emerald-500">↑ {sessionDiff} more session{sessionDiff > 1 ? 's' : ''} completed</span>
                ) : sessionDiff === 0 ? (
                  <span>Maintained same session pace</span>
                ) : (
                  <span className="text-muted-foreground">{Math.abs(sessionDiff)} fewer session{Math.abs(sessionDiff) > 1 ? 's' : ''}</span>
                )}
              </p>
              <p className="text-[11px] text-muted-foreground">This week: {thisWeekCompletedSessions.length} | Last week: {lastWeekCompletedSessions.length}</p>
            </div>

            <div className="p-3 border rounded-xl bg-card space-y-1 min-w-0">
              <span className="text-[10px] sm:text-xs text-muted-foreground font-medium block">Time Invested</span>
              <p className="font-semibold text-foreground text-xs sm:text-sm">
                {timeDiffMinutes > 0 ? (
                  <span className="text-emerald-500">↑ {timeDiffMinutes}m more practice time</span>
                ) : timeDiffMinutes === 0 ? (
                  <span>Same learning duration</span>
                ) : (
                  <span className="text-muted-foreground">{Math.abs(timeDiffMinutes)}m less practice time</span>
                )}
              </p>
              <p className="text-[11px] text-muted-foreground">This week: {Math.round(thisWeekMinutes / 60 * 10) / 10}h | Last week: {Math.round(lastWeekMinutes / 60 * 10) / 10}h</p>
            </div>

            <div className="p-3 border rounded-xl bg-card space-y-1 min-w-0">
              <span className="text-[10px] sm:text-xs text-muted-foreground font-medium block">Consistency Rating</span>
              <p className="font-semibold text-emerald-500 text-xs sm:text-sm">
                {overallConsistency >= 80 ? '🔥 Excellent Consistency' : overallConsistency >= 50 ? '⚡ Good Progress' : '🌱 Getting Started'}
              </p>
              <p className="text-[11px] text-muted-foreground">{overallConsistency}% completion rate</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Breakdown per Skill */}
      <Card className="min-w-0">
        <CardHeader className="p-4 sm:p-6 pb-2 sm:pb-3">
          <CardTitle className="text-base sm:text-lg">Skill Performance Breakdown</CardTitle>
          <CardDescription className="text-xs sm:text-sm">Real-time performance metrics automatically updated as you complete practice sessions.</CardDescription>
        </CardHeader>
        <CardContent className="p-4 sm:p-6 pt-0 sm:pt-0">
          {skills.length === 0 ? (
            <div className="py-8 text-center text-xs sm:text-sm text-muted-foreground border border-dashed rounded-xl">
              No skills added yet. Create a skill to start tracking consistency!
            </div>
          ) : (
            <div className="space-y-3 sm:space-y-4 min-w-0">
              {skills.map(skill => (
                <div key={skill.id} className="p-3.5 sm:p-4 border rounded-xl space-y-3 bg-card min-w-0">
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 min-w-0">
                    <div className="min-w-0">
                      <h3 className="font-semibold text-base sm:text-lg truncate">{skill.name}</h3>
                      <p className="text-xs text-muted-foreground truncate">{skill.category} · Target: {skill.weeklyTarget} sessions/wk</p>
                    </div>
                    <div className="flex items-center gap-3 shrink-0">
                      <span className="text-xs sm:text-sm font-bold text-emerald-500 px-2.5 py-0.5 sm:px-3 sm:py-1 bg-emerald-500/10 border border-emerald-500/20 rounded-full">
                        {skill.consistencyPct}% Consistency
                      </span>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs pt-2 border-t min-w-0">
                    <div className="min-w-0">
                      <span className="text-muted-foreground block text-[10px] sm:text-xs">This Week</span>
                      <span className="font-semibold text-xs sm:text-sm truncate block">{skill.weeklyCompleted} / {skill.weeklyTarget}</span>
                    </div>
                    <div className="min-w-0">
                      <span className="text-muted-foreground block text-[10px] sm:text-xs">Streak</span>
                      <span className="font-semibold text-xs sm:text-sm text-orange-500 flex items-center gap-1 truncate">
                        <Flame className="h-3.5 w-3.5 shrink-0 inline" /> {skill.streak} sessions
                      </span>
                    </div>
                    <div className="min-w-0">
                      <span className="text-muted-foreground block text-[10px] sm:text-xs">Learning Time</span>
                      <span className="font-semibold text-xs sm:text-sm truncate block">{skill.learningHours}h total</span>
                    </div>
                    <div className="min-w-0">
                      <span className="text-muted-foreground block text-[10px] sm:text-xs">Month Consistency</span>
                      <span className="font-semibold text-xs sm:text-sm truncate block">{skill.monthConsistencyPct || 100}%</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Monthly Activity Visual Calendar */}
      <Card className="min-w-0">
        <CardHeader className="p-4 sm:p-6 pb-2 sm:pb-3">
          <CardTitle className="text-base sm:text-lg">Monthly Practice Activity ({format(now, 'MMMM yyyy')})</CardTitle>
          <CardDescription className="text-xs sm:text-sm">
            <span className="text-emerald-500 font-medium">✓</span> = Completed &nbsp;|&nbsp; 
            <span className="text-red-500 font-medium"> ✕</span> = Skipped/Missed &nbsp;|&nbsp; 
            <span className="text-muted-foreground font-medium"> -</span> = No session
          </CardDescription>
        </CardHeader>
        <CardContent className="p-3 sm:p-6 pt-0 sm:pt-0 min-w-0">
          <div className="grid grid-cols-7 gap-1 sm:gap-2 text-center text-[10px] sm:text-xs font-semibold pb-2 border-b">
            <div>Mon</div><div>Tue</div><div>Wed</div><div>Thu</div><div>Fri</div><div>Sat</div><div>Sun</div>
          </div>

          <div className="grid grid-cols-7 gap-1 sm:gap-2 text-center pt-2 sm:pt-3 text-xs min-w-0">
            {/* Offset for start of month */}
            {Array.from({ length: (startOfMonth(now).getDay() || 7) - 1 }).map((_, i) => (
              <div key={`offset-${i}`} className="h-9 sm:h-12 border border-transparent"></div>
            ))}

            {daysInMonth.map((day) => {
              const dayStr = format(day, 'yyyy-MM-dd')
              const daySessions = allSessions.filter(s => s.scheduled_date === dayStr)
              const hasCompleted = daySessions.some(s => s.status === 'completed')
              const hasSkipped = daySessions.some(s => s.status === 'skipped' || s.status === 'missed')

              return (
                <div key={dayStr} className="h-9 sm:h-12 border rounded-lg p-0.5 sm:p-1 flex flex-col items-center justify-between bg-card min-w-0">
                  <span className="text-[10px] sm:text-[11px] text-muted-foreground font-mono">{format(day, 'd')}</span>
                  {hasCompleted ? (
                    <span className="text-emerald-500 font-bold text-[10px] sm:text-xs flex items-center justify-center">
                      <CheckCircle2 className="h-3 w-3 sm:h-3.5 sm:w-3.5" />
                    </span>
                  ) : hasSkipped ? (
                    <span className="text-red-500 font-bold text-[10px] sm:text-xs flex items-center justify-center">
                      <XCircle className="h-3 w-3 sm:h-3.5 sm:w-3.5" />
                    </span>
                  ) : (
                    <span className="text-muted-foreground text-[10px] sm:text-xs font-bold">-</span>
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
