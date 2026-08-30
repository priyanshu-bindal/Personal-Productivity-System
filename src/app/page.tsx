import { Suspense } from "react"
import { createClient } from '@/lib/supabase/server'
import { getTasks, getProgressStats, getGoals } from "@/lib/actions"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { format, isToday, isTomorrow, isAfter, startOfToday, endOfToday, addDays, endOfDay } from "date-fns"
import { redirect } from "next/navigation"
import { Calendar, Clock, AlertTriangle, Target, Flame, CheckCircle2 } from "lucide-react"
import { Progress } from "@/components/ui/progress"
import Link from "next/link"

async function DashboardContent() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    redirect('/auth/signin')
  }

  const today = startOfToday()
  const endOfNextWeek = endOfDay(addDays(today, 14))
  
  const [allTasks, stats, goals] = await Promise.all([
    getTasks({ start: today, end: endOfNextWeek }),
    getProgressStats(),
    getGoals()
  ])
  
  const todaysTasks = allTasks.filter(t => t.scheduledDate && isToday(t.scheduledDate))
  const upcomingTasks = allTasks.filter(t => t.scheduledDate && isAfter(t.scheduledDate, endOfToday()))
  
  const completedTodayCount = todaysTasks.filter(t => t.status === 'Completed').length
  const totalTodayCount = todaysTasks.length
  const remainingCount = totalTodayCount - completedTodayCount
  
  // Smart Overload Warning
  const todayTotalMinutes = todaysTasks.reduce((acc, t) => acc + (t.duration || 0), 0)
  const todayTotalHours = Math.round(todayTotalMinutes / 60 * 10) / 10
  const isOverloaded = todayTotalMinutes > 180 // 3 hours

  // Greeting based on time
  const hour = new Date().getHours()
  const greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening'

  return (
    <div className="p-6 md:p-10 max-w-6xl mx-auto space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700 pb-24 md:pb-10">
      <header className="space-y-2 flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl md:text-4xl font-bold tracking-tight">{greeting}, {user?.user_metadata?.full_name?.split(' ')[0] || 'there'}</h1>
          <p className="text-muted-foreground text-lg mt-1">
            {remainingCount > 0 
              ? `You have ${remainingCount} task${remainingCount !== 1 ? 's' : ''} remaining today.`
              : totalTodayCount > 0
                ? 'All tasks completed for today! Great work.'
                : 'No tasks scheduled today. Pick up some upcoming work.'}
          </p>
        </div>
        {stats && (
          <div className="flex gap-4">
            <div className="bg-orange-500/10 text-orange-500 px-4 py-2 rounded-lg flex items-center gap-2">
              <Flame className="h-5 w-5" />
              <div>
                <div className="text-xs font-semibold uppercase tracking-wider">Streak</div>
                <div className="font-bold">{stats.streak} days</div>
              </div>
            </div>
            <div className="bg-emerald-500/10 text-emerald-600 px-4 py-2 rounded-lg flex items-center gap-2 hidden sm:flex">
              <CheckCircle2 className="h-5 w-5" />
              <div>
                <div className="text-xs font-semibold uppercase tracking-wider">Tasks Done</div>
                <div className="font-bold">{stats.tasksCompleted}</div>
              </div>
            </div>
          </div>
        )}
      </header>

      {/* Smart Overload Warning */}
      {isOverloaded && (
        <div className="flex items-start gap-3 p-4 rounded-lg border border-amber-500/30 bg-amber-500/5">
          <AlertTriangle className="h-5 w-5 text-amber-500 mt-0.5 shrink-0" />
          <div>
            <p className="font-medium text-sm">You have {todayTotalHours}h planned today.</p>
            <p className="text-sm text-muted-foreground mt-0.5">Consider moving some tasks to another day to avoid burnout. Consistency over intensity.</p>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
        
        {/* Left Column: Today & Goals */}
        <div className="lg:col-span-8 space-y-8">
          <section>
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-2xl font-semibold tracking-tight">Today&apos;s Focus</h2>
              <span className="text-sm font-medium text-muted-foreground uppercase tracking-wider">{format(new Date(), 'EEEE')}</span>
            </div>
            
            <div className="space-y-4">
              {todaysTasks.length === 0 ? (
                <Card className="border-dashed shadow-none bg-muted/30">
                  <CardContent className="flex flex-col items-center justify-center p-12 text-center">
                    <div className="rounded-full bg-muted p-3 mb-4">
                      <Calendar className="h-6 w-6 text-muted-foreground" />
                    </div>
                    <h3 className="font-semibold text-lg mb-1">No tasks for today</h3>
                    <p className="text-muted-foreground text-sm max-w-sm">Enjoy your day off or schedule a session from your Skills page!</p>
                  </CardContent>
                </Card>
              ) : (
                todaysTasks.map(task => (
                  <Card key={task.id} className="transition-all hover:shadow-md relative overflow-hidden group">
                    <div className={`absolute left-0 top-0 bottom-0 w-1 ${
                      task.status === 'Completed' ? 'bg-emerald-500' : 
                      task.priority === 'High' ? 'bg-red-500' :
                      'bg-primary/80'
                    }`} />
                    <CardContent className="p-5 flex gap-4">
                      <div className="flex-1 space-y-1">
                        <div className="flex items-center gap-2">
                          <span className="font-medium text-sm text-primary">{task.skill?.name || 'General'}</span>
                          <span className="text-muted-foreground text-xs">•</span>
                          {task.duration && (
                            <span className="text-muted-foreground text-xs flex items-center gap-1">
                              <Clock className="w-3 h-3" />
                              {task.duration} min
                            </span>
                          )}
                        </div>
                        <h3 className={`font-semibold text-lg ${task.status === 'Completed' ? 'line-through text-muted-foreground' : ''}`}>
                          {task.title}
                        </h3>
                        {task.description && (
                          <p className="text-muted-foreground text-sm">{task.description}</p>
                        )}
                      </div>
                      <div className="flex items-start gap-2">
                        {task.priority === 'High' && <Badge variant="destructive">High</Badge>}
                        {task.priority === 'Medium' && <Badge variant="secondary">Medium</Badge>}
                        {task.status === 'Completed' && <Badge className="bg-emerald-500/10 text-emerald-600 border-emerald-500/20">Done</Badge>}
                      </div>
                    </CardContent>
                  </Card>
                ))
              )}
            </div>
          </section>

          <section>
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-2xl font-semibold tracking-tight">Active Goals</h2>
              <Link href="/goals" className="text-sm font-medium text-primary hover:underline">View All</Link>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {goals.slice(0, 2).map((goal: any) => (
                <Card key={goal.id} className="hover:border-primary/50 transition-colors">
                  <CardContent className="p-5">
                    <div className="flex items-center gap-2 mb-3">
                      <Target className="h-4 w-4 text-orange-500" />
                      <h3 className="font-semibold line-clamp-1">{goal.title}</h3>
                    </div>
                    <div className="space-y-1.5">
                      <div className="flex justify-between text-xs font-medium text-muted-foreground">
                        <span>Progress</span>
                        <span>{goal.progress}%</span>
                      </div>
                      <Progress value={goal.progress} className="h-1.5" />
                    </div>
                  </CardContent>
                </Card>
              ))}
              {goals.length === 0 && (
                <div className="col-span-full text-sm text-muted-foreground p-4 text-center border rounded-lg border-dashed">
                  No active goals. Track your long-term objectives here.
                </div>
              )}
            </div>
          </section>
        </div>

        {/* Right Column: Upcoming */}
        <div className="lg:col-span-4 space-y-8">
          <section>
            <h2 className="text-xl font-semibold tracking-tight mb-4">Upcoming Tasks</h2>
            
            <div className="space-y-4 relative">
              <div className="absolute left-[15px] top-4 bottom-4 w-px bg-border -z-10" />
              
              {upcomingTasks.slice(0, 5).map((task) => {
                const isTmrw = task.scheduledDate ? isTomorrow(task.scheduledDate) : false
                return (
                  <div key={task.id} className="flex gap-4 relative">
                    <div className="w-8 h-8 rounded-full bg-background border shadow-sm flex items-center justify-center shrink-0 mt-0.5">
                      <div className="w-2.5 h-2.5 rounded-full bg-primary/60" />
                    </div>
                    <div className="flex-1 bg-card border rounded-lg p-4 shadow-sm group hover:border-primary/50 transition-colors">
                      <div className="text-xs font-medium text-muted-foreground mb-1 uppercase tracking-wider">
                        {isTmrw ? 'Tomorrow' : task.scheduledDate ? format(task.scheduledDate, 'EEEE') : 'Later'}
                      </div>
                      <div className="font-medium">{task.skill?.name || 'General'}</div>
                      <div className="text-sm text-muted-foreground line-clamp-1">{task.title}</div>
                      {task.duration && (
                        <div className="text-xs text-muted-foreground mt-2 flex items-center gap-1">
                          <Clock className="w-3 h-3" />
                          {task.duration} min
                        </div>
                      )}
                    </div>
                  </div>
                )
              })}
              
              {upcomingTasks.length === 0 && (
                <div className="text-sm text-muted-foreground p-4 text-center border rounded-lg border-dashed bg-card">
                  Nothing scheduled for later this week.
                </div>
              )}
            </div>
          </section>
        </div>
      </div>
    </div>
  )
}

export default function Dashboard() {
  return (
    <Suspense fallback={<div className="p-10 flex justify-center"><div className="animate-pulse h-8 w-32 bg-muted rounded"></div></div>}>
      <DashboardContent />
    </Suspense>
  )
}
