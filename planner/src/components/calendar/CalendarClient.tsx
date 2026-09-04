'use client'

import { useState, useTransition, useEffect, useCallback, useRef } from 'react'
import { Card, CardContent } from "@/components/ui/card"
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
  ArrowRight,
  BookOpen
} from 'lucide-react'
import { TrafficLoader } from '@/components/ui/traffic-loader'
import { 
  format, 
  addWeeks, 
  subWeeks, 
  startOfWeek, 
  endOfWeek, 
  eachDayOfInterval, 
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
    <div className="space-y-6 min-w-0 w-full animate-in fade-in slide-in-from-bottom-4 duration-500">
      {/* Calendar Header & Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b pb-6 min-w-0">
        <div className="min-w-0">
          <h1 className="text-2xl sm:text-3xl md:text-4xl font-bold tracking-tight">Calendar</h1>
          <p className="text-muted-foreground text-xs sm:text-base md:text-lg mt-1">
            See your learning schedule for the week.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2 self-start sm:self-auto min-w-0">
          <div className="flex items-center gap-1">
            <Button variant="outline" size="sm" onClick={handlePrevWeek} aria-label="Previous Week" className="h-8 w-8 p-0">
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <Button variant="outline" size="sm" onClick={handleTodayWeek} className="h-8 text-xs px-2.5">
              Today
            </Button>
            <Button variant="outline" size="sm" onClick={handleNextWeek} aria-label="Next Week" className="h-8 w-8 p-0">
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
          <span className="text-xs sm:text-sm font-semibold text-foreground truncate">
            {format(monday, 'MMM d')} – {format(sunday, 'MMM d, yyyy')}
          </span>
        </div>
      </div>

      {/* Week Progress Summary Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between p-3.5 sm:p-4 border rounded-xl bg-card gap-3 min-w-0">
        <div className="flex items-center gap-3 min-w-0">
          <div className="p-2 sm:p-2.5 bg-primary/10 rounded-lg text-primary shrink-0">
            <CalendarIcon className="h-4 w-4 sm:h-5 sm:w-5" />
          </div>
          <div className="min-w-0">
            <p className="font-semibold text-xs sm:text-sm truncate">Weekly Progress</p>
            <p className="text-[11px] sm:text-xs text-muted-foreground truncate">
              {completedSessionsThisWeek} / {totalSessionsThisWeek} sessions completed · {weeklyPct}%
            </p>
          </div>
        </div>
        <Link href="/skills" className="self-start sm:self-auto shrink-0">
          <Button size="sm" variant="ghost" className="text-xs gap-1 hover:text-primary h-8 px-2">
            Manage Skills <ArrowRight className="h-3.5 w-3.5" />
          </Button>
        </Link>
      </div>

      {/* Desktop Weekly View: Compact 7-Column Grid */}
      <div className="hidden md:grid grid-cols-7 gap-3 items-start min-w-0">
        {weekDays.map((day) => {
          const dayStr = format(day, 'yyyy-MM-dd')
          const daySessions = sessions.filter(s => s.scheduledDate === dayStr)
          const isCurrentDay = isToday(day)

          return (
            <div 
              key={dayStr} 
              className={`flex flex-col border rounded-xl p-3 bg-card min-h-[160px] min-w-0 ${
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

              <div className="space-y-2 flex-1 flex flex-col justify-start min-w-0">
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
                        className={`w-full text-left p-2.5 rounded-lg border transition-all hover:scale-[1.02] flex flex-col justify-between gap-1 min-w-0 ${
                          isCompleted
                            ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400'
                            : isSkipped
                            ? 'bg-muted/40 border-muted text-muted-foreground line-through opacity-70'
                            : 'bg-card border-border hover:border-primary/50 text-foreground'
                        }`}
                      >
                        <div className="flex items-center justify-between w-full min-w-0">
                          <span className="font-semibold text-xs truncate">
                            {session.skillName}
                          </span>
                          <span className="text-[10px] font-mono opacity-80 shrink-0 ml-1">
                            {session.plannedDuration}m
                          </span>
                        </div>

                        <div className="flex items-center gap-1 text-[11px] font-medium min-w-0">
                          {isCompleted ? (
                            <span className="flex items-center gap-1 text-emerald-500 font-semibold truncate">
                              <CheckCircle2 className="h-3 w-3 shrink-0" /> Completed
                            </span>
                          ) : isSkipped ? (
                            <span className="flex items-center gap-1 text-muted-foreground truncate">
                              <XCircle className="h-3 w-3 shrink-0" /> Skipped
                            </span>
                          ) : (
                            <span className="flex items-center gap-1 text-blue-400 truncate">
                              <Clock className="h-3 w-3 shrink-0" /> Scheduled
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
      <div className="md:hidden space-y-3 sm:space-y-4 min-w-0">
        {weekDays.map((day) => {
          const dayStr = format(day, 'yyyy-MM-dd')
          const daySessions = sessions.filter(s => s.scheduledDate === dayStr)
          const isCurrentDay = isToday(day)

          return (
            <div 
              key={dayStr} 
              className={`border rounded-xl p-3.5 sm:p-4 bg-card space-y-3 min-w-0 ${
                isCurrentDay ? 'ring-2 ring-primary border-primary/50 bg-primary/5' : ''
              }`}
            >
              <div className="flex justify-between items-center border-b pb-2 min-w-0">
                <div className="flex items-center gap-2 min-w-0">
                  <span className={`text-sm sm:text-base font-bold truncate ${isCurrentDay ? 'text-primary' : ''}`}>
                    {format(day, 'EEEE, MMM d')}
                  </span>
                  {isCurrentDay && (
                    <Badge variant="default" className="text-[10px] px-1.5 py-0 shrink-0">Today</Badge>
                  )}
                </div>
                <span className="text-xs text-muted-foreground font-medium shrink-0 ml-2">
                  {daySessions.length} session{daySessions.length !== 1 ? 's' : ''}
                </span>
              </div>

              {daySessions.length === 0 ? (
                <p className="text-xs text-muted-foreground py-1 font-medium">— Nothing scheduled</p>
              ) : (
                <div className="space-y-2 min-w-0">
                  {daySessions.map(session => {
                    const isCompleted = session.status === 'completed'
                    const isSkipped = session.status === 'skipped'

                    return (
                      <div
                        key={session.id}
                        onClick={() => openSessionDetail(session)}
                        className={`p-3 rounded-lg border flex items-center justify-between cursor-pointer active:scale-[0.99] transition-all min-w-0 gap-2 ${
                          isCompleted
                            ? 'bg-emerald-500/10 border-emerald-500/30'
                            : isSkipped
                            ? 'bg-muted/40 border-muted opacity-70'
                            : 'bg-card border-border hover:border-primary/50'
                        }`}
                      >
                        <div className="space-y-0.5 min-w-0 flex-1">
                          <div className="flex flex-wrap items-center gap-1.5">
                            <span className="font-semibold text-xs sm:text-sm truncate">{session.skillName}</span>
                            <Badge variant="outline" className="text-[10px] px-1.5 py-0 font-normal shrink-0">
                              {session.category}
                            </Badge>
                          </div>
                          <span className="text-xs text-muted-foreground flex items-center gap-1 truncate">
                            <Clock className="h-3 w-3 shrink-0" /> {session.plannedDuration} minutes
                          </span>
                        </div>

                        <div className="flex items-center gap-2 shrink-0">
                          {isCompleted ? (
                            <Badge className="bg-emerald-600 text-white gap-1 text-[11px] sm:text-xs">
                              <CheckCircle2 className="h-3 w-3" /> Completed
                            </Badge>
                          ) : isSkipped ? (
                            <Badge variant="secondary" className="gap-1 text-[11px] sm:text-xs">
                              <XCircle className="h-3 w-3" /> Skipped
                            </Badge>
                          ) : (
                            <Button size="sm" variant="outline" className="h-7 sm:h-8 text-xs font-medium px-2.5">
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
        <Card className="border-dashed py-8 sm:py-12 text-center min-w-0">
          <CardContent className="space-y-4 p-4">
            <div className="mx-auto w-10 h-10 sm:w-12 sm:h-12 bg-primary/10 rounded-full flex items-center justify-center text-primary">
              <BookOpen className="h-5 w-5 sm:h-6 sm:w-6" />
            </div>
            <div>
              <h3 className="text-base sm:text-lg font-semibold">No learning sessions scheduled for this week</h3>
              <p className="text-muted-foreground text-xs sm:text-sm max-w-sm mx-auto mt-1">
                Add skills and set your practice days in My Skills to automatically generate your weekly schedule.
              </p>
            </div>
            <Link href="/skills">
              <Button size="sm" className="gap-2">
                <Plus className="h-4 w-4" /> Go to My Skills
              </Button>
            </Link>
          </CardContent>
        </Card>
      )}

      {/* Session Detail & Action Modal */}
      {selectedSession && (
        <Dialog open={!!selectedSession} onOpenChange={(open) => !open && setSelectedSession(null)}>
          <DialogContent className="sm:max-w-[420px] p-4 sm:p-6">
            <DialogHeader>
              <DialogTitle className="flex items-center justify-between text-base sm:text-lg">
                <span className="truncate pr-2">{selectedSession.skillName}</span>
                <Badge 
                  variant={
                    selectedSession.status === 'completed' ? 'default' : 
                    selectedSession.status === 'skipped' ? 'secondary' : 'outline'
                  }
                  className="shrink-0"
                >
                  {selectedSession.status}
                </Badge>
              </DialogTitle>
            </DialogHeader>

            {!isRescheduling ? (
              <div className="space-y-4 py-2 min-w-0">
                <div className="grid grid-cols-2 gap-2.5 text-xs min-w-0">
                  <div className="p-2.5 rounded-lg border bg-muted/30 min-w-0">
                    <span className="text-muted-foreground block mb-0.5 text-[10px]">Date</span>
                    <span className="font-semibold text-foreground text-xs sm:text-sm truncate block">
                      {format(parseISO(selectedSession.scheduledDate), 'EEE, MMM d')}
                    </span>
                  </div>
                  <div className="p-2.5 rounded-lg border bg-muted/30 min-w-0">
                    <span className="text-muted-foreground block mb-0.5 text-[10px]">Duration</span>
                    <span className="font-semibold text-foreground text-xs sm:text-sm truncate block">
                      {selectedSession.plannedDuration} mins
                    </span>
                  </div>
                  <div className="p-2.5 rounded-lg border bg-muted/30 min-w-0">
                    <span className="text-muted-foreground block mb-0.5 text-[10px]">Category</span>
                    <span className="font-semibold text-foreground text-xs sm:text-sm truncate block">
                      {selectedSession.category}
                    </span>
                  </div>
                  <div className="p-2.5 rounded-lg border bg-muted/30 min-w-0">
                    <span className="text-muted-foreground block mb-0.5 text-[10px]">Level</span>
                    <span className="font-semibold text-foreground text-xs sm:text-sm truncate block">
                      {selectedSession.level}
                    </span>
                  </div>
                </div>

                <DialogFooter className="gap-2 sm:gap-2 pt-2 border-t flex flex-col-reverse sm:flex-row">
                  {selectedSession.status === 'planned' && (
                    <>
                      <Button 
                        size="sm" 
                        variant="outline" 
                        onClick={() => setIsRescheduling(true)}
                        disabled={isPending}
                        className="w-full sm:w-auto text-xs"
                      >
                        Reschedule
                      </Button>
                      <Button 
                        size="sm" 
                        variant="secondary" 
                        onClick={() => handleSkip(selectedSession)}
                        disabled={isPending}
                        className="w-full sm:w-auto text-xs"
                      >
                        Skip
                      </Button>
                      <Button 
                        size="sm" 
                        className="bg-emerald-600 hover:bg-emerald-700 text-white gap-1.5 w-full sm:w-auto text-xs"
                        onClick={() => handleComplete(selectedSession)}
                        disabled={isPending || loadingSessionId === selectedSession.id}
                      >
                        {loadingSessionId === selectedSession.id ? (
                          <TrafficLoader size="sm" />
                        ) : (
                          <>
                            <CheckCircle2 className="h-4 w-4" /> Complete
                          </>
                        )}
                      </Button>
                    </>
                  )}
                  {selectedSession.status !== 'planned' && (
                    <Button variant="outline" size="sm" onClick={() => setSelectedSession(null)} className="w-full sm:w-auto text-xs">
                      Close
                    </Button>
                  )}
                </DialogFooter>
              </div>
            ) : (
              <form onSubmit={handleReschedule} className="space-y-4 py-2 min-w-0">
                <div className="space-y-2 min-w-0">
                  <Label htmlFor="rescheduleDate" className="text-xs sm:text-sm">New Date for this Session</Label>
                  <Input 
                    id="rescheduleDate"
                    type="date"
                    value={rescheduleDate}
                    onChange={(e) => setRescheduleDate(e.target.value)}
                    required
                    className="text-xs sm:text-sm"
                  />
                  <p className="text-[11px] text-muted-foreground">
                    Only this individual session occurrence will be moved. Your recurring skill schedule remains unchanged.
                  </p>
                </div>

                <DialogFooter className="gap-2 pt-2 border-t flex flex-row justify-end">
                  <Button type="button" variant="outline" size="sm" onClick={() => setIsRescheduling(false)} className="text-xs">
                    Back
                  </Button>
                  <Button type="submit" size="sm" disabled={isPending} className="text-xs">
                    {isPending ? <TrafficLoader size="sm" className="mr-1" /> : 'Confirm'}
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
