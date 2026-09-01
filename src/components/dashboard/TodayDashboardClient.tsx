'use client'

import { useState, useCallback, useOptimistic } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { completeLearningSession, skipLearningSession } from '@/lib/actions'
import { useToast } from '@/components/ui/toast-provider'
import { CheckCircle2, Clock, Flame, Calendar, BookOpen, Plus, ArrowRight, Loader2 } from 'lucide-react'
import { format } from 'date-fns'
import Link from 'next/link'
import { SkillModal } from '@/components/skills/SkillModal'
import { motion, AnimatePresence } from 'framer-motion'

export function TodayDashboardClient({ 
  todaySessions, 
  skills, 
  userFirstName 
}: { 
  todaySessions: any[]
  skills: any[]
  userFirstName: string 
}) {
  const [isAddSkillOpen, setIsAddSkillOpen] = useState(false)
  const [loadingIds, setLoadingIds] = useState<Set<string>>(new Set())
  const { success, error: showError } = useToast()

  // Optimistic state for sessions
  const [optimisticSessions, setOptimisticSessions] = useOptimistic(
    todaySessions,
    (state: any[], update: { id: string; newStatus: string }) => 
      state.map(s => s.id === update.id ? { ...s, status: update.newStatus } : s)
  )

  const completedSessions = optimisticSessions.filter(s => s.status === 'completed')
  const plannedSessions = optimisticSessions.filter(s => s.status === 'planned')
  const totalPlannedDuration = optimisticSessions.reduce((acc, s) => acc + (s.plannedDuration || 60), 0)

  const handleComplete = useCallback(async (sessionId: string, skillName: string) => {
    if (loadingIds.has(sessionId)) return // Prevent duplicate
    setLoadingIds(prev => new Set(prev).add(sessionId))
    
    // Optimistic update
    setOptimisticSessions({ id: sessionId, newStatus: 'completed' })

    try {
      await completeLearningSession(sessionId)
      success(`${skillName} session completed!`, 'Great work! Keep the streak going.')
    } catch (err) {
      showError("Couldn't complete session", "Please try again.")
    } finally {
      setLoadingIds(prev => { const n = new Set(prev); n.delete(sessionId); return n })
    }
  }, [loadingIds, setOptimisticSessions, success, showError])

  const handleSkip = useCallback(async (sessionId: string, skillName: string) => {
    if (loadingIds.has(sessionId)) return
    setLoadingIds(prev => new Set(prev).add(sessionId))
    
    setOptimisticSessions({ id: sessionId, newStatus: 'skipped' })

    try {
      await skipLearningSession(sessionId)
      success(`${skillName} skipped`, "You can always reschedule.")
    } catch (err) {
      showError("Couldn't skip session", "Please try again.")
    } finally {
      setLoadingIds(prev => { const n = new Set(prev); n.delete(sessionId); return n })
    }
  }, [loadingIds, setOptimisticSessions, success, showError])

  const hour = new Date().getHours()
  const greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening'

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
      {/* Header & Greeting */}
      <header className="flex flex-col md:flex-row md:items-end justify-between gap-4 border-b pb-6">
        <div>
          <div className="text-xs font-semibold uppercase tracking-wider text-primary mb-1">
            {format(new Date(), 'EEEE, MMMM d, yyyy')}
          </div>
          <h1 className="text-3xl md:text-4xl font-bold tracking-tight">
            {greeting}, {userFirstName}!
          </h1>
          <p className="text-muted-foreground text-base md:text-lg mt-1">
            {plannedSessions.length > 0
              ? `You have ${plannedSessions.length} learning session${plannedSessions.length !== 1 ? 's' : ''} planned for today.`
              : optimisticSessions.length > 0
                ? "All learning sessions completed today! Excellent job."
                : "Nothing scheduled for today. Take a break or practice a skill."}
          </p>
        </div>

        <Button onClick={() => setIsAddSkillOpen(true)} className="gap-2 shrink-0">
          <Plus className="h-4 w-4" /> Add Skill
        </Button>
      </header>

      {/* Main Today View */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
        
        {/* Left Column: Today's Sessions */}
        <div className="lg:col-span-8 space-y-6">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-semibold tracking-tight flex items-center gap-2">
              <Calendar className="h-5 w-5 text-primary" /> Today&apos;s Learning Sessions
            </h2>
            <span className="text-xs text-muted-foreground font-medium">
              {totalPlannedDuration} mins total
            </span>
          </div>

          {optimisticSessions.length === 0 ? (
            <Card className="border-dashed shadow-none bg-muted/20 py-12 text-center">
              <CardContent className="space-y-3">
                <div className="w-12 h-12 rounded-full bg-primary/10 text-primary flex items-center justify-center mx-auto">
                  <BookOpen className="h-6 w-6" />
                </div>
                <h3 className="font-semibold text-lg">Nothing planned for today</h3>
                <p className="text-sm text-muted-foreground max-w-sm mx-auto">
                  Setup your skills with preferred practice days, and daily sessions will automatically appear here.
                </p>
                <div className="pt-2">
                  <Button variant="outline" onClick={() => setIsAddSkillOpen(true)}>+ Add a Skill</Button>
                </div>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-4">
              <AnimatePresence mode="popLayout">
                {optimisticSessions.map((session) => {
                  const isCompleted = session.status === 'completed'
                  const isSkipped = session.status === 'skipped'
                  const skill = session.skill || {}
                  const isActionLoading = loadingIds.has(session.id)

                  return (
                    <motion.div
                      key={session.id}
                      layout
                      initial={false}
                      animate={{ opacity: 1, scale: 1 }}
                      transition={{ duration: 0.2 }}
                    >
                      <Card className={`shadow-sm transition-all duration-300 ${isCompleted ? 'border-emerald-500/40 bg-emerald-500/5' : 'hover:border-primary/50'}`}>
                        <CardContent className="p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                          <div className="space-y-1">
                            <div className="flex items-center gap-2">
                              <span className="font-semibold text-lg">{skill.name || 'Learning Session'}</span>
                              {skill.category && (
                                <span className="text-xs px-2.5 py-0.5 rounded-full bg-muted text-muted-foreground font-medium">
                                  {skill.category}
                                </span>
                              )}
                            </div>

                            <div className="flex items-center gap-4 text-xs text-muted-foreground font-medium pt-1">
                              <span className="flex items-center gap-1">
                                <Clock className="h-3.5 w-3.5 text-primary" /> {session.plannedDuration} minutes
                              </span>
                              {skill.level && <span>Level: {skill.level}</span>}
                            </div>
                          </div>

                          {/* Direct Card Action Button */}
                          <div className="flex items-center gap-2 pt-2 sm:pt-0">
                            {isCompleted ? (
                              <motion.div 
                                initial={{ scale: 0.8, opacity: 0 }}
                                animate={{ scale: 1, opacity: 1 }}
                                transition={{ type: 'spring', stiffness: 300, damping: 20 }}
                                className="flex items-center gap-1.5 text-emerald-600 bg-emerald-500/10 px-3 py-1.5 rounded-lg text-xs font-semibold"
                              >
                                <CheckCircle2 className="h-4 w-4" /> Completed
                              </motion.div>
                            ) : isSkipped ? (
                              <span className="text-xs text-muted-foreground px-3 py-1.5 rounded-lg bg-muted">Skipped</span>
                            ) : (
                              <>
                                <Button 
                                  variant="ghost" 
                                  size="sm" 
                                  className="text-xs text-muted-foreground hover:text-foreground"
                                  onClick={() => handleSkip(session.id, skill.name || 'Session')}
                                  disabled={isActionLoading}
                                >
                                  Skip
                                </Button>
                                <Button 
                                  size="sm" 
                                  className="bg-emerald-600 hover:bg-emerald-700 text-white gap-2 font-semibold min-w-[140px]"
                                  onClick={() => handleComplete(session.id, skill.name || 'Session')}
                                  disabled={isActionLoading}
                                >
                                  {isActionLoading ? (
                                    <><Loader2 className="h-4 w-4 animate-spin" /> Completing...</>
                                  ) : (
                                    <><CheckCircle2 className="h-4 w-4" /> Complete Session</>
                                  )}
                                </Button>
                              </>
                            )}
                          </div>
                        </CardContent>
                      </Card>
                    </motion.div>
                  )
                })}
              </AnimatePresence>
            </div>
          )}
        </div>

        {/* Right Column: Skills Overview */}
        <div className="lg:col-span-4 space-y-6">
          <Card>
            <CardHeader className="pb-3 flex flex-row items-center justify-between">
              <CardTitle className="text-base font-semibold">Your Skills Overview</CardTitle>
              <Link href="/skills" className="text-xs text-primary hover:underline flex items-center gap-1">
                View All <ArrowRight className="h-3 w-3" />
              </Link>
            </CardHeader>
            <CardContent className="space-y-4">
              {skills.length === 0 ? (
                <p className="text-sm text-muted-foreground text-center py-4">No skills created yet.</p>
              ) : (
                skills.slice(0, 4).map(skill => (
                  <div key={skill.id} className="p-3 border rounded-xl space-y-2 bg-card">
                    <div className="flex justify-between items-center text-sm font-medium">
                      <span>{skill.name}</span>
                      <span className="text-xs text-primary font-bold">{skill.consistencyPct}% consistency</span>
                    </div>
                    <div className="flex justify-between text-xs text-muted-foreground">
                      <span className="flex items-center gap-1">
                        <Flame className="h-3 w-3 text-orange-500" /> {skill.streak}d streak
                      </span>
                      <span>Target: {skill.weeklyTarget}x/wk</span>
                    </div>
                  </div>
                ))
              )}
            </CardContent>
          </Card>
        </div>

      </div>

      {isAddSkillOpen && (
        <SkillModal isOpen={isAddSkillOpen} onClose={() => setIsAddSkillOpen(false)} />
      )}
    </div>
  )
}
