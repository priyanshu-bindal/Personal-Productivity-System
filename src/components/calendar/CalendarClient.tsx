'use client'

import { useState, useTransition, useEffect, useCallback, useRef } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { Label } from '@/components/ui/label'
import { Input } from '@/components/ui/input'
import { useToast } from '@/components/ui/toast-provider'
import { 
  ChevronLeft, 
  ChevronRight, 
  Calendar as CalendarIcon, 
  CheckCircle2, 
  XCircle, 
  Clock, 
  Plus, 
  Loader2, 
  ArrowRight,
  BookOpen
} from 'lucide-react'
import { 
  format, 
  addWeeks, 
  subWeeks, 
  startOfWeek, 
  endOfWeek, 
  eachDayOfInterval, 
  isSameDay, 
  isToday, 
  parseISO 
} from 'date-fns'
import Link from 'next/link'
import { 
  getCalendarSessions, 
  completeLearningSession, 
  skipLearningSession, 
  rescheduleLearningSession 
} from '@/lib/actions'

interface SessionItem {
  id: string
  skillId: string
  skillName: string
  category: string
  level: string
  scheduledDate: string
  plannedDuration: number
  actualDuration?: number
  status: 'planned' | 'completed' | 'skipped'
  notes?: string
}

export function CalendarClient({ initialSessions = [] }: { initialSessions?: SessionItem[] }) {
  const [currentWeekDate, setCurrentWeekDate] = useState<Date>(new Date())
  const [sessions, setSessions] = useState<SessionItem[]>(initialSessions)
  const [selectedSession, setSelectedSession] = useState<SessionItem | null>(null)
  const [isRescheduling, setIsRescheduling] = useState(false)
  const [rescheduleDate, setRescheduleDate] = useState<string>('')
  
  const [isPending, startTransition] = useTransition()
  const [loadingSessionId, setLoadingSessionId] = useState<string | null>(null)
  const { success, error: showError } = useToast()

  // Calculate week start (Monday) and end (Sunday)
  const monday = startOfWeek(currentWeekDate, { weekStartsOn: 1 })
  const sunday = endOfWeek(currentWeekDate, { weekStartsOn: 1 })
  const weekDays = eachDayOfInterval({ start: monday, end: sunday })

  const startDateStr = format(monday, 'yyyy-MM-dd')
  const endDateStr = format(sunday, 'yyyy-MM-dd')

  // Fetch sessions when week changes
  const fetchSessions = useCallback(async () => {
    try {
      const data = await getCalendarSessions(startDateStr, endDateStr)
      setSessions(data)
    } catch (err) {
      console.error(err)
    }
  }, [startDateStr, endDateStr])

  const isInitialMount = useRef(true)

  useEffect(() => {
    if (isInitialMount.current) {
      isInitialMount.current = false
      return
    }
    fetchSessions()
  }, [fetchSessions])

  const handlePrevWeek = () => setCurrentWeekDate(prev => subWeeks(prev, 1))
  const handleNextWeek = () => setCurrentWeekDate(prev => addWeeks(prev, 1))
  const handleTodayWeek = () => setCurrentWeekDate(new Date())

  const handleComplete = async (session: SessionItem) => {
    setLoadingSessionId(session.id)
    startTransition(async () => {
      try {
        await completeLearningSession(session.id, session.plannedDuration)
        success(`${session.skillName} completed!`, 'Great practice session!')
        setSelectedSession(null)
        await fetchSessions()
      } catch (err) {
        showError("Couldn't complete session", "Please try again.")
      } finally {
        setLoadingSessionId(null)
      }
    })
  }

  const handleSkip = async (session: SessionItem) => {
    setLoadingSessionId(session.id)
    startTransition(async () => {
      try {
        await skipLearningSession(session.id)
        success(`${session.skillName} skipped`)
        setSelectedSession(null)
        await fetchSessions()
      } catch (err) {
        showError("Couldn't skip session", "Please try again.")
      } finally {
        setLoadingSessionId(null)
      }
    })
  }

  const handleReschedule = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!selectedSession || !rescheduleDate) return
    setLoadingSessionId(selectedSession.id)
    startTransition(async () => {
      try {
        await rescheduleLearningSession(selectedSession.id, rescheduleDate)
        success(`Rescheduled to ${format(parseISO(rescheduleDate), 'EEE, MMM d')}`)
        setSelectedSession(null)
        setIsRescheduling(false)
        await fetchSessions()
      } catch (err) {
        showError("Couldn't reschedule", "Please try again.")
      } finally {
        setLoadingSessionId(null)
      }
    })
  }

  const openSessionDetail = (session: SessionItem) => {
    setSelectedSession(session)
    setRescheduleDate(session.scheduledDate)
    setIsRescheduling(false)
  }

  const totalSessionsThisWeek = sessions.length
  const completedSessionsThisWeek = sessions.filter(s => s.status === 'completed').length
  const weeklyPct = totalSessionsThisWeek > 0 
    ? Math.round((completedSessionsThisWeek / totalSessionsThisWeek) * 100) 
    : 0

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
      {/* Calendar Header & Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b pb-6">
        <div>
          <h1 className="text-3xl md:text-4xl font-bold tracking-tight">Calendar</h1>
          <p className="text-muted-foreground text-base md:text-lg mt-1">
            See your learning schedule for the week.
          </p>
        </div>

        <div className="flex items-center gap-2 self-start sm:self-auto">
          <Button variant="outline" size="sm" onClick={handlePrevWeek} aria-label="Previous Week">
            <ChevronLeft className="h-4 w-4" />
          </Button>
          <Button variant="outline" size="sm" onClick={handleTodayWeek}>
            Today
          </Button>
          <Button variant="outline" size="sm" onClick={handleNextWeek} aria-label="Next Week">
            <ChevronRight className="h-4 w-4" />
          </Button>
          <span className="text-sm font-semibold ml-2 text-foreground">
            {format(monday, 'MMM d')} – {format(sunday, 'MMM d, yyyy')}
          </span>
        </div>
      </div>

      {/* Week Progress Summary Banner */}
      <div className="flex items-center justify-between p-4 border rounded-xl bg-card">
        <div className="flex items-center gap-3">
          <div className="p-2.5 bg-primary/10 rounded-lg text-primary">
            <CalendarIcon className="h-5 w-5" />
          </div>
          <div>
            <p className="font-semibold text-sm">Weekly Progress</p>
            <p className="text-xs text-muted-foreground">
              {completedSessionsThisWeek} / {totalSessionsThisWeek} sessions completed · {weeklyPct}%
            </p>
          </div>
        </div>
        <Link href="/skills">
          <Button size="sm" variant="ghost" className="text-xs gap-1 hover:text-primary">
            Manage Skills <ArrowRight className="h-3.5 w-3.5" />
          </Button>
        </Link>
      </div>

      {/* Desktop Weekly View: Compact 7-Column Grid */}
      <div className="hidden md:grid grid-cols-7 gap-3 items-start">
        {weekDays.map((day) => {
          const dayStr = format(day, 'yyyy-MM-dd')
          const daySessions = sessions.filter(s => s.scheduledDate === dayStr)
          const isCurrentDay = isToday(day)

          return (
            <div 
              key={dayStr} 
              className={`flex flex-col border rounded-xl p-3 bg-card min-h-[160px] ${
                isCurrentDay ? 'ring-2 ring-primary border-primary/50 bg-primary/5' : ''
              }`}
            >
              <div className="border-b pb-2 mb-2.5 text-center">
                <p className={`text-xs font-semibold uppercase ${isCurrentDay ? 'text-primary font-bold' : 'text-muted-foreground'}`}>
                  {format(day, 'EEE')}
                </p>
                <p className={`text-lg font-bold ${isCurrentDay ? 'text-primary' : ''}`}>
                  {format(day, 'd')}
                </p>
              </div>

              <div className="space-y-2 flex-1 flex flex-col justify-start">
                {daySessions.length === 0 ? (
                  <div className="py-6 flex items-center justify-center text-center">
                    <span className="text-xs text-muted-foreground font-normal">Nothing scheduled</span>
                  </div>
                ) : (
                  daySessions.map(session => {
                    const isCompleted = session.status === 'completed'
                    const isSkipped = session.status === 'skipped'

                    return (
                      <button
                        key={session.id}
                        onClick={() => openSessionDetail(session)}
                        className={`w-full text-left p-3 rounded-lg border transition-all hover:scale-[1.02] flex flex-col justify-between gap-1.5 ${
                          isCompleted
                            ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400'
                            : isSkipped
                            ? 'bg-muted/40 border-muted text-muted-foreground line-through opacity-70'
                            : 'bg-card border-border hover:border-primary/50 text-foreground'
                        }`}
                      >
                        <div className="flex items-center justify-between w-full">
                          <span className="font-semibold text-xs truncate max-w-[90px]">
                            {session.skillName}
                          </span>
                          <span className="text-[10px] font-mono opacity-80">
                            {session.plannedDuration}m
                          </span>
                        </div>

                        <div className="flex items-center gap-1 text-[11px] font-medium">
                          {isCompleted ? (
                            <span className="flex items-center gap-1 text-emerald-500 font-semibold">
                              <CheckCircle2 className="h-3 w-3" /> Completed
                            </span>
                          ) : isSkipped ? (
                            <span className="flex items-center gap-1 text-muted-foreground">
                              <XCircle className="h-3 w-3" /> Skipped
                            </span>
                          ) : (
                            <span className="flex items-center gap-1 text-blue-400">
                              <Clock className="h-3 w-3" /> Scheduled
                            </span>
                          )}
                        </div>
                      </button>
                    )
                  })
                )}
              </div>
            </div>
          )
        })}
      </div>

      {/* Mobile Weekly View: Vertically Stacked List */}
      <div className="md:hidden space-y-4">
        {weekDays.map((day) => {
          const dayStr = format(day, 'yyyy-MM-dd')
          const daySessions = sessions.filter(s => s.scheduledDate === dayStr)
          const isCurrentDay = isToday(day)

          return (
            <div 
              key={dayStr} 
              className={`border rounded-xl p-4 bg-card space-y-3 ${
                isCurrentDay ? 'ring-2 ring-primary border-primary/50 bg-primary/5' : ''
              }`}
            >
              <div className="flex justify-between items-center border-b pb-2">
                <div className="flex items-center gap-2">
                  <span className={`text-base font-bold ${isCurrentDay ? 'text-primary' : ''}`}>
                    {format(day, 'EEEE, MMM d')}
                  </span>
                  {isCurrentDay && (
                    <Badge variant="default" className="text-[10px] px-2 py-0.5">Today</Badge>
                  )}
                </div>
                <span className="text-xs text-muted-foreground font-medium">
                  {daySessions.length} session{daySessions.length !== 1 ? 's' : ''}
                </span>
              </div>

              {daySessions.length === 0 ? (
                <p className="text-xs text-muted-foreground py-2 font-medium">— Nothing scheduled</p>
              ) : (
                <div className="space-y-2">
                  {daySessions.map(session => {
                    const isCompleted = session.status === 'completed'
                    const isSkipped = session.status === 'skipped'

                    return (
                      <div
                        key={session.id}
                        onClick={() => openSessionDetail(session)}
                        className={`p-3 rounded-lg border flex items-center justify-between cursor-pointer active:scale-[0.99] transition-all ${
                          isCompleted
                            ? 'bg-emerald-500/10 border-emerald-500/30'
                            : isSkipped
                            ? 'bg-muted/40 border-muted opacity-70'
                            : 'bg-card border-border hover:border-primary/50'
                        }`}
                      >
                        <div className="space-y-0.5">
                          <div className="flex items-center gap-2">
                            <span className="font-semibold text-sm">{session.skillName}</span>
                            <Badge variant="outline" className="text-[10px] px-2 py-0 font-normal">
                              {session.category}
                            </Badge>
                          </div>
                          <span className="text-xs text-muted-foreground flex items-center gap-1">
                            <Clock className="h-3 w-3" /> {session.plannedDuration} minutes
                          </span>
                        </div>

                        <div className="flex items-center gap-2">
                          {isCompleted ? (
                            <Badge className="bg-emerald-600 text-white gap-1 text-xs">
                              <CheckCircle2 className="h-3 w-3" /> Completed
                            </Badge>
                          ) : isSkipped ? (
                            <Badge variant="secondary" className="gap-1 text-xs">
                              <XCircle className="h-3 w-3" /> Skipped
                            </Badge>
                          ) : (
                            <Button size="sm" variant="outline" className="h-8 text-xs font-medium">
                              Manage
                            </Button>
                          )}
                        </div>
                      </div>
                    )
                  })}
                </div>
              )}
            </div>
          )
        })}
      </div>

      {/* Empty State when no sessions at all in the week */}
      {sessions.length === 0 && (
        <Card className="border-dashed py-12 text-center">
          <CardContent className="space-y-4">
            <div className="mx-auto w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center text-primary">
              <BookOpen className="h-6 w-6" />
            </div>
            <div>
              <h3 className="text-lg font-semibold">No learning sessions scheduled for this week</h3>
              <p className="text-muted-foreground text-sm max-w-sm mx-auto mt-1">
                Add skills and set your practice days in My Skills to automatically generate your weekly schedule.
              </p>
            </div>
            <Link href="/skills">
              <Button className="gap-2">
                <Plus className="h-4 w-4" /> Go to My Skills
              </Button>
            </Link>
          </CardContent>
        </Card>
      )}

      {/* Session Detail & Action Modal */}
      {selectedSession && (
        <Dialog open={!!selectedSession} onOpenChange={(open) => !open && setSelectedSession(null)}>
          <DialogContent className="sm:max-w-[420px]">
            <DialogHeader>
              <DialogTitle className="flex items-center justify-between">
                <span>{selectedSession.skillName}</span>
                <Badge 
                  variant={
                    selectedSession.status === 'completed' ? 'default' : 
                    selectedSession.status === 'skipped' ? 'secondary' : 'outline'
                  }
                >
                  {selectedSession.status}
                </Badge>
              </DialogTitle>
            </DialogHeader>

            {!isRescheduling ? (
              <div className="space-y-4 py-2">
                <div className="grid grid-cols-2 gap-3 text-xs">
                  <div className="p-2.5 rounded-lg border bg-muted/30">
                    <span className="text-muted-foreground block mb-0.5">Date</span>
                    <span className="font-semibold text-foreground text-sm">
                      {format(parseISO(selectedSession.scheduledDate), 'EEEE, MMM d')}
                    </span>
                  </div>
                  <div className="p-2.5 rounded-lg border bg-muted/30">
                    <span className="text-muted-foreground block mb-0.5">Duration</span>
                    <span className="font-semibold text-foreground text-sm">
                      {selectedSession.plannedDuration} minutes
                    </span>
                  </div>
                  <div className="p-2.5 rounded-lg border bg-muted/30">
                    <span className="text-muted-foreground block mb-0.5">Category</span>
                    <span className="font-semibold text-foreground text-sm">
                      {selectedSession.category}
                    </span>
                  </div>
                  <div className="p-2.5 rounded-lg border bg-muted/30">
                    <span className="text-muted-foreground block mb-0.5">Level</span>
                    <span className="font-semibold text-foreground text-sm">
                      {selectedSession.level}
                    </span>
                  </div>
                </div>

                <DialogFooter className="gap-2 sm:gap-0 pt-2 border-t">
                  {selectedSession.status === 'planned' && (
                    <>
                      <Button 
                        size="sm" 
                        variant="outline" 
                        onClick={() => setIsRescheduling(true)}
                        disabled={isPending}
                      >
                        Reschedule
                      </Button>
                      <Button 
                        size="sm" 
                        variant="secondary" 
                        onClick={() => handleSkip(selectedSession)}
                        disabled={isPending}
                      >
                        Skip
                      </Button>
                      <Button 
                        size="sm" 
                        className="bg-emerald-600 hover:bg-emerald-700 text-white gap-1.5"
                        onClick={() => handleComplete(selectedSession)}
                        disabled={isPending || loadingSessionId === selectedSession.id}
                      >
                        {loadingSessionId === selectedSession.id ? (
                          <Loader2 className="h-4 w-4 animate-spin" />
                        ) : (
                          <>
                            <CheckCircle2 className="h-4 w-4" /> Complete
                          </>
                        )}
                      </Button>
                    </>
                  )}
                  {selectedSession.status !== 'planned' && (
                    <Button variant="outline" size="sm" onClick={() => setSelectedSession(null)}>
                      Close
                    </Button>
                  )}
                </DialogFooter>
              </div>
            ) : (
              <form onSubmit={handleReschedule} className="space-y-4 py-2">
                <div className="space-y-2">
                  <Label htmlFor="rescheduleDate">New Date for this Session</Label>
                  <Input 
                    id="rescheduleDate"
                    type="date"
                    value={rescheduleDate}
                    onChange={(e) => setRescheduleDate(e.target.value)}
                    required
                  />
                  <p className="text-[11px] text-muted-foreground">
                    Only this individual session occurrence will be moved. Your recurring skill schedule in My Skills remains unchanged.
                  </p>
                </div>

                <DialogFooter className="gap-2 sm:gap-0 pt-2 border-t">
                  <Button type="button" variant="outline" size="sm" onClick={() => setIsRescheduling(false)}>
                    Back
                  </Button>
                  <Button type="submit" size="sm" disabled={isPending}>
                    {isPending ? <Loader2 className="h-4 w-4 animate-spin mr-1" /> : 'Confirm Reschedule'}
                  </Button>
                </DialogFooter>
              </form>
            )}
          </DialogContent>
        </Dialog>
      )}
    </div>
  )
}
