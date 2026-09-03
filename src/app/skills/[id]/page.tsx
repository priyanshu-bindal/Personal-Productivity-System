import { Suspense } from "react"
import { createClient } from '@/lib/supabase/server'
import { getSkillById } from "@/lib/actions"
import { redirect, notFound } from "next/navigation"
import { Card, CardContent } from "@/components/ui/card"
import { Progress } from "@/components/ui/progress"
import { Badge } from "@/components/ui/badge"
import { ArrowLeft, Target, Clock, Flame, Calendar as CalendarIcon, CheckCircle2 } from "lucide-react"
import Link from "next/link"
import { format } from "date-fns"
import { TopicsManager, MarkPracticedInline } from "@/components/skills/SkillDetailsClient"

async function SkillDetailsContent({ id }: { id: string }) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/signin')

  const skill = await getSkillById(id)
  if (!skill) notFound()

  const totalSessions = skill.learningSessions?.length || 0
  const totalMinutes = skill.learningSessions?.reduce((acc: number, s: any) => acc + s.duration, 0) || 0
  const learningHours = Math.round(totalMinutes / 60 * 10) / 10

  // Calculate streak: count consecutive days with sessions
  let currentStreak = 0
  if (skill.learningSessions && skill.learningSessions.length > 0) {
    const sortedSessions = [...skill.learningSessions].sort((a: any, b: any) => 
      new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    )
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    let checkDate = new Date(today)
    
    for (let i = 0; i < 365; i++) {
      const dayStart = new Date(checkDate)
      const dayEnd = new Date(checkDate)
      dayEnd.setHours(23, 59, 59, 999)
      
      const hasSession = sortedSessions.some((s: any) => {
        const d = new Date(s.createdAt)
        return d >= dayStart && d <= dayEnd
      })
      
      if (hasSession) {
        currentStreak++
        checkDate.setDate(checkDate.getDate() - 1)
      } else if (i === 0) {
        // Today has no session yet, check from yesterday
        checkDate.setDate(checkDate.getDate() - 1)
      } else {
        break
      }
    }
  }

  // Calculate automatic activity progress
  const weeklyCompleted = skill.weeklyCompleted || 0
  const weeklyTarget = skill.weeklyTarget || 3
  const weeklyProgress = Math.min(100, Math.round((weeklyCompleted / (weeklyTarget || 1)) * 100))

  // Last practiced
  const lastSession = skill.learningSessions?.[0]
  const lastPracticed = lastSession ? format(new Date(lastSession.createdAt), 'MMM d, yyyy') : 'Never'

  return (
    <div className="p-6 md:p-10 max-w-5xl mx-auto space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
      {/* Header */}
      <header className="space-y-4">
        <Link href="/skills" className="inline-flex items-center text-sm font-medium text-muted-foreground hover:text-foreground transition-colors">
          <ArrowLeft className="mr-2 h-4 w-4" /> Back to Skills
        </Link>
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
          <div>
            <div className="flex items-center gap-3 mb-2">
              <Badge variant="secondary" className="px-3 py-1 rounded-full">{skill.category}</Badge>
              <Badge variant="outline" className="px-3 py-1 rounded-full">{skill.level}</Badge>
              <Badge variant="outline" className="px-3 py-1 rounded-full text-emerald-500 border-emerald-500/30 bg-emerald-500/10">
                {skill.consistencyPct || 100}% Consistency
              </Badge>
            </div>
            <h1 className="text-3xl md:text-5xl font-bold tracking-tight">{skill.name}</h1>
            {skill.target && (
              <p className="text-lg text-muted-foreground mt-2 flex items-center gap-2">
                <Target className="h-5 w-5 text-primary" /> {skill.target}
              </p>
            )}
            {skill.description && (
              <p className="text-muted-foreground mt-1">{skill.description}</p>
            )}
          </div>
          <div className="flex flex-col items-end gap-3">
            <div className="text-right">
              <div className="text-4xl font-bold text-emerald-500 tabular-nums">{weeklyCompleted} / {weeklyTarget}</div>
              <div className="text-sm font-medium text-muted-foreground">Sessions This Week</div>
            </div>
            <MarkPracticedInline skillId={skill.id} skillName={skill.name} />
          </div>
        </div>
      </header>

      {/* Activity Progress Bar */}
      <Progress value={weeklyProgress} className="h-3 bg-muted" />

      {/* Stats Grid */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
        <Card className="shadow-sm">
          <CardContent className="p-5 flex flex-col items-center justify-center text-center space-y-1">
            <CheckCircle2 className="h-5 w-5 text-emerald-500" />
            <div className="text-2xl font-bold tabular-nums">{totalSessions}</div>
            <div className="text-[11px] text-muted-foreground font-medium uppercase tracking-wider">Sessions</div>
          </CardContent>
        </Card>
        <Card className="shadow-sm">
          <CardContent className="p-5 flex flex-col items-center justify-center text-center space-y-1">
            <Clock className="h-5 w-5 text-blue-500" />
            <div className="text-2xl font-bold tabular-nums">{learningHours}h</div>
            <div className="text-[11px] text-muted-foreground font-medium uppercase tracking-wider">Hours</div>
          </CardContent>
        </Card>
        <Card className="shadow-sm">
          <CardContent className="p-5 flex flex-col items-center justify-center text-center space-y-1">
            <Flame className="h-5 w-5 text-orange-500" />
            <div className="text-2xl font-bold tabular-nums">{currentStreak}</div>
            <div className="text-[11px] text-muted-foreground font-medium uppercase tracking-wider">Streak</div>
          </CardContent>
        </Card>
        <Card className="shadow-sm">
          <CardContent className="p-5 flex flex-col items-center justify-center text-center space-y-1">
            <CalendarIcon className="h-5 w-5 text-purple-500" />
            <div className="text-2xl font-bold tabular-nums">{skill.weeklyTarget}</div>
            <div className="text-[11px] text-muted-foreground font-medium uppercase tracking-wider">Weekly Goal</div>
          </CardContent>
        </Card>
        <Card className="shadow-sm">
          <CardContent className="p-5 flex flex-col items-center justify-center text-center space-y-1">
            <Target className="h-5 w-5 text-cyan-500" />
            <div className="text-2xl font-bold tabular-nums">{skill.topics?.length || 0}</div>
            <div className="text-[11px] text-muted-foreground font-medium uppercase tracking-wider">Topics</div>
          </CardContent>
        </Card>
      </div>

      {/* Main Content */}
      <div className="grid grid-cols-1 md:grid-cols-12 gap-8">
        {/* Topics */}
        <div className="md:col-span-8">
          <TopicsManager skillId={skill.id} topics={skill.topics || []} />
        </div>

        {/* Recent Sessions */}
        <div className="md:col-span-4 space-y-6">
          <section>
            <h2 className="text-xl font-semibold tracking-tight mb-4">Recent Sessions</h2>
            <div className="space-y-4">
              {(!skill.learningSessions || skill.learningSessions.length === 0) ? (
                <div className="p-6 text-center text-muted-foreground border rounded-lg border-dashed">
                  No practice sessions yet. Click &quot;Mark as Practiced&quot; to log your first session.
                </div>
              ) : (
                skill.learningSessions.slice(0, 8).map((ls: any, i: number) => (
                  <div key={ls.id} className="flex gap-4">
                    <div className="flex flex-col items-center">
                      <div className="w-8 h-8 rounded-full bg-primary/10 text-primary flex items-center justify-center shrink-0">
                        <CheckCircle2 className="h-4 w-4" />
                      </div>
                      {i < Math.min(skill.learningSessions!.length - 1, 7) && (
                        <div className="w-px flex-1 bg-border my-1" />
                      )}
                    </div>
                    <div className="pb-4 flex-1 min-w-0">
                      <div className="text-sm font-medium">{format(new Date(ls.createdAt), 'MMM d, yyyy')}</div>
                      <div className="text-xs text-muted-foreground">{ls.duration} minutes</div>
                      {ls.topics && (
                        <div className="text-xs text-muted-foreground mt-1 truncate">
                          <span className="font-medium">Topics:</span> {ls.topics}
                        </div>
                      )}
                      {ls.notes && (
                        <div className="text-xs text-muted-foreground mt-0.5 truncate">
                          {ls.notes}
                        </div>
                      )}
                    </div>
                  </div>
                ))
              )}
            </div>
          </section>

          <section className="border-t pt-6">
            <h2 className="text-lg font-semibold tracking-tight mb-3">Info</h2>
            <dl className="space-y-3 text-sm">
              <div className="flex justify-between">
                <dt className="text-muted-foreground">Last Practiced</dt>
                <dd className="font-medium">{lastPracticed}</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-muted-foreground">Total Time</dt>
                <dd className="font-medium">{totalMinutes} min</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-muted-foreground">Created</dt>
                <dd className="font-medium">{format(new Date(skill.createdAt), 'MMM d, yyyy')}</dd>
              </div>
            </dl>
          </section>
        </div>
      </div>
    </div>
  )
}

import { TrafficLoader } from "@/components/ui/traffic-loader"

export default async function SkillDetailsPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  return (
    <Suspense fallback={<div className="p-10 flex justify-center items-center min-h-[40vh]"><TrafficLoader size="md" /></div>}>
      <SkillDetailsContent id={id} />
    </Suspense>
  )
}
