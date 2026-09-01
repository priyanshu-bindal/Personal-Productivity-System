'use client'

import { useState, useTransition, useCallback } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { SkillModal } from '@/components/skills/SkillModal'
import { completeLearningSession, deleteSkill, getSkillHistory, addLearningSession } from '@/lib/actions'
import { useToast } from '@/components/ui/toast-provider'
import * as Icons from "lucide-react"
import { MoreVertical, Edit, CheckCircle2, Trash2, Plus, Calendar, Clock, Flame, History, Loader2, TrendingUp } from 'lucide-react'
import { format, isThisWeek, isThisMonth } from 'date-fns'

export function SkillsClient({ initialSkills }: { initialSkills: any[] }) {
  const [isAddModalOpen, setIsAddModalOpen] = useState(false)
  const [editingSkill, setEditingSkill] = useState<any>(null)
  const [historySkill, setHistorySkill] = useState<any>(null)
  const [historySessions, setHistorySessions] = useState<any[]>([])
  const [historyFilter, setHistoryFilter] = useState<'week' | 'month' | 'all'>('all')
  const [isLoadingHistory, setIsLoadingHistory] = useState(false)
  const [isPending, startTransition] = useTransition()
  const [loadingSessionIds, setLoadingSessionIds] = useState<Set<string>>(new Set())
  const { success, error: showError } = useToast()
  
  const handleDelete = async (id: string, name: string) => {
    if (confirm("Are you sure you want to delete this skill?")) {
      startTransition(async () => {
        try {
          await deleteSkill(id)
          success(`${name} deleted`)
        } catch (err) {
          showError("Couldn't delete skill", "Please try again.")
        }
      })
    }
  }

  const handleCompleteToday = useCallback(async (sessionId: string, skillName: string) => {
    if (loadingSessionIds.has(sessionId)) return
    setLoadingSessionIds(prev => new Set(prev).add(sessionId))
    startTransition(async () => {
      try {
        await completeLearningSession(sessionId)
        success(`${skillName} session completed!`, 'Keep the session streak going!')
      } catch (err) {
        showError("Couldn't complete session", "Please try again.")
      } finally {
        setLoadingSessionIds(prev => { const n = new Set(prev); n.delete(sessionId); return n })
      }
    })
  }, [loadingSessionIds, startTransition, success, showError])

  const handleLogPracticeToday = useCallback(async (skillId: string, skillName: string, duration: number) => {
    if (loadingSessionIds.has(skillId)) return
    setLoadingSessionIds(prev => new Set(prev).add(skillId))
    startTransition(async () => {
      try {
        await addLearningSession(skillId, { duration: duration || 60 })
        success(`${skillName} session completed!`, 'Practice logged for today!')
      } catch (err) {
        showError("Couldn't log practice", "Please try again.")
      } finally {
        setLoadingSessionIds(prev => { const n = new Set(prev); n.delete(skillId); return n })
      }
    })
  }, [loadingSessionIds, startTransition, success, showError])

  const handleOpenHistory = async (skill: any) => {
    setHistorySkill(skill)
    setIsLoadingHistory(true)
    try {
      const history = await getSkillHistory(skill.id)
      setHistorySessions(history)
    } catch (err) {
      console.error(err)
    } finally {
      setIsLoadingHistory(false)
    }
  }

  const filteredHistory = historySessions.filter(s => {
    const d = new Date(s.scheduled_date)
    if (historyFilter === 'week') return isThisWeek(d, { weekStartsOn: 1 })
    if (historyFilter === 'month') return isThisMonth(d)
    return true
  })

  return (
    <div className="space-y-8">
      <header className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl md:text-4xl font-bold tracking-tight">My Skills</h1>
          <p className="text-muted-foreground text-lg mt-1">
            Consistent daily practice over intensity. Tell the app what to practice and when.
          </p>
        </div>
        <Button onClick={() => setIsAddModalOpen(true)} className="gap-2">
          <Plus className="h-4 w-4" /> Add Skill
        </Button>
      </header>

      {initialSkills.length === 0 ? (
        <div className="py-16 text-center border border-dashed rounded-xl bg-card space-y-4">
          <div className="mx-auto w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center">
            <Icons.BookOpen className="h-6 w-6 text-primary" />
          </div>
          <div>
            <h3 className="text-xl font-medium">Build your learning system</h3>
            <p className="text-muted-foreground max-w-sm mx-auto text-sm mt-1">
              Add skills you want to practice regularly (e.g. Python, DSA, Communication).
            </p>
          </div>
          <Button onClick={() => setIsAddModalOpen(true)}>+ Add Your First Skill</Button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {initialSkills.map((skill) => {
            const todaySession = skill.todaySession
            const isCompletedToday = todaySession?.status === 'completed'
            const hasPlannedToday = todaySession && todaySession.status === 'planned'

            return (
              <Card key={skill.id} className="group hover:border-primary/50 transition-all hover:shadow-md flex flex-col justify-between">
                <CardHeader className="pb-3">
                  <div className="flex justify-between items-start">
                    <div className="p-2 bg-primary/10 rounded-lg text-primary">
                      <Icons.BookOpen className="h-6 w-6" />
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-medium px-2.5 py-1 bg-muted rounded-full text-muted-foreground">
                        {skill.level || 'Beginner'}
                      </span>
                      <DropdownMenu>
                        <DropdownMenuTrigger className="rounded-md h-8 w-8 inline-flex items-center justify-center text-muted-foreground hover:bg-accent">
                          <MoreVertical className="h-4 w-4" />
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end" className="w-52">
                          <DropdownMenuItem onClick={() => setEditingSkill(skill)}>
                            <Edit className="mr-2 h-4 w-4" /> Edit Skill & Schedule
                          </DropdownMenuItem>
                          <DropdownMenuItem onClick={() => handleOpenHistory(skill)}>
                            <History className="mr-2 h-4 w-4" /> View History
                          </DropdownMenuItem>
                          <DropdownMenuSeparator />
                          <DropdownMenuItem className="text-destructive focus:bg-destructive/10" onClick={() => handleDelete(skill.id, skill.name)}>
                            <Trash2 className="mr-2 h-4 w-4" /> Delete Skill
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </div>
                  </div>

                  <CardTitle className="text-xl mt-3">{skill.name}</CardTitle>
                  <CardDescription className="line-clamp-1">{skill.category}</CardDescription>
                </CardHeader>

                <CardContent className="space-y-5 flex-1 flex flex-col justify-between">
                  {/* Today Session Highlight Box */}
                  <div className="p-3.5 rounded-xl border bg-muted/30 space-y-2">
                    <div className="text-xs font-semibold text-muted-foreground flex items-center justify-between">
                      <span>TODAY</span>
                      <span className="flex items-center gap-1 font-mono">
                        <Clock className="h-3 w-3" /> {skill.sessionDuration}m
                      </span>
                    </div>

                    {isCompletedToday ? (
                      <div className="flex items-center justify-between text-emerald-500 font-medium text-sm pt-1">
                        <span className="flex items-center gap-1.5">
                          <CheckCircle2 className="h-4 w-4" /> Session Completed
                        </span>
                        <span className="text-xs text-muted-foreground">{todaySession.actualDuration || skill.sessionDuration}m logged</span>
                      </div>
                    ) : hasPlannedToday ? (
                      <div className="flex items-center justify-between pt-1 gap-2">
                        <span className="text-sm font-medium">Practice {skill.name}</span>
                        <Button 
                          size="sm" 
                          className="bg-emerald-600 hover:bg-emerald-700 text-white gap-1.5 h-8 text-xs font-semibold shrink-0 min-w-[100px]"
                          onClick={() => handleCompleteToday(todaySession.id, skill.name)}
                          disabled={isPending || loadingSessionIds.has(todaySession.id)}
                        >
                          {loadingSessionIds.has(todaySession.id) ? (
                            <><Loader2 className="h-3.5 w-3.5 animate-spin" /> ...</>
                          ) : (
                            <><CheckCircle2 className="h-3.5 w-3.5" /> Complete</>
                          )}
                        </Button>
                      </div>
                    ) : (
                      <div className="flex items-center justify-between pt-1 gap-2">
                        <span className="text-xs text-muted-foreground truncate">
                          Next: <span className="font-medium text-foreground">{skill.nextSessionDate ? format(new Date(skill.nextSessionDate), 'EEE, MMM d') : 'Soon'}</span>
                        </span>
                        <Button 
                          size="sm" 
                          variant="outline"
                          className="hover:bg-emerald-500/10 hover:text-emerald-500 hover:border-emerald-500/50 gap-1.5 h-8 text-xs font-semibold shrink-0"
                          onClick={() => handleLogPracticeToday(skill.id, skill.name, skill.sessionDuration)}
                          disabled={isPending || loadingSessionIds.has(skill.id)}
                        >
                          {loadingSessionIds.has(skill.id) ? (
                            <><Loader2 className="h-3.5 w-3.5 animate-spin" /> ...</>
                          ) : (
                            <><CheckCircle2 className="h-3.5 w-3.5" /> Log Practice</>
                          )}
                        </Button>
                      </div>
                    )}
                  </div>

                  {/* Automatic Weekly Activity Progress Bar */}
                  <div className="space-y-1.5">
                    <div className="flex justify-between items-center text-xs">
                      <span className="font-medium text-muted-foreground">
                        This Week: <span className="font-bold text-foreground">{skill.weeklyCompleted} / {skill.weeklyTarget} sessions</span>
                      </span>
                      <span className="font-bold text-xs text-emerald-500">
                        {Math.min(100, Math.round((skill.weeklyCompleted / (skill.weeklyTarget || 1)) * 100))}%
                      </span>
                    </div>
                    <div className="h-2 w-full bg-muted rounded-full overflow-hidden">
                      <div 
                        className="h-full bg-emerald-500 transition-all duration-500 rounded-full"
                        style={{ width: `${Math.min(100, Math.round((skill.weeklyCompleted / (skill.weeklyTarget || 1)) * 100))}%` }}
                      />
                    </div>
                  </div>

                  {/* Key Stats Grid */}
                  <div className="grid grid-cols-2 gap-2 pt-2 border-t text-xs">
                    <div className="p-2 rounded-lg bg-card border">
                      <p className="text-muted-foreground mb-0.5">Consistency</p>
                      <p className="font-bold text-sm text-primary">{skill.consistencyPct}%</p>
                    </div>
                    <div className="p-2 rounded-lg bg-card border">
                      <p className="text-muted-foreground mb-0.5">Session Streak</p>
                      <p className="font-bold text-sm text-orange-500 flex items-center gap-0.5">
                        <Flame className="h-3.5 w-3.5 inline" /> {skill.streak} session{skill.streak !== 1 ? 's' : ''}
                      </p>
                    </div>
                    <div className="p-2 rounded-lg bg-card border">
                      <p className="text-muted-foreground mb-0.5">Learning Time</p>
                      <p className="font-bold text-sm text-foreground">{skill.learningHours}h</p>
                    </div>
                    <div className="p-2 rounded-lg bg-card border">
                      <p className="text-muted-foreground mb-0.5">Target</p>
                      <p className="font-bold text-sm text-foreground">{skill.weeklyTarget}x / wk</p>
                    </div>
                  </div>

                  {/* Footer info & history trigger */}
                  <div className="flex justify-between items-center text-xs text-muted-foreground pt-1">
                    <button 
                      onClick={() => handleOpenHistory(skill)}
                      className="flex items-center gap-1 text-primary hover:underline font-medium"
                    >
                      <History className="h-3.5 w-3.5" /> View History
                    </button>
                    <span>{skill.preferredDays?.length || 3} days / wk</span>
                  </div>
                </CardContent>
              </Card>
            )
          })}
        </div>
      )}

      {/* Add / Edit Skill Modal */}
      {isAddModalOpen && (
        <SkillModal isOpen={isAddModalOpen} onClose={() => setIsAddModalOpen(false)} />
      )}
      
      {editingSkill && (
        <SkillModal isOpen={!!editingSkill} onClose={() => setEditingSkill(null)} skill={editingSkill} />
      )}

      {/* History Dialog */}
      {historySkill && (
        <Dialog open={!!historySkill} onOpenChange={(open) => !open && setHistorySkill(null)}>
          <DialogContent className="sm:max-w-[500px] max-h-[85vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle className="flex items-center justify-between">
                <span className="flex items-center gap-2">
                  <History className="h-5 w-5 text-primary" />
                  {historySkill.name} Practice History
                </span>
              </DialogTitle>
            </DialogHeader>

            {/* Filter Tabs */}
            <div className="flex gap-1 p-1 bg-muted rounded-lg text-xs font-medium">
              <button 
                onClick={() => setHistoryFilter('all')} 
                className={`flex-1 py-1.5 rounded-md transition-all ${historyFilter === 'all' ? 'bg-background shadow text-foreground' : 'text-muted-foreground hover:text-foreground'}`}
              >
                All Time
              </button>
              <button 
                onClick={() => setHistoryFilter('month')} 
                className={`flex-1 py-1.5 rounded-md transition-all ${historyFilter === 'month' ? 'bg-background shadow text-foreground' : 'text-muted-foreground hover:text-foreground'}`}
              >
                This Month
              </button>
              <button 
                onClick={() => setHistoryFilter('week')} 
                className={`flex-1 py-1.5 rounded-md transition-all ${historyFilter === 'week' ? 'bg-background shadow text-foreground' : 'text-muted-foreground hover:text-foreground'}`}
              >
                This Week
              </button>
            </div>

            <div className="space-y-3 py-2">
              {isLoadingHistory ? (
                <div className="py-8 text-center text-muted-foreground animate-pulse">
                  Loading session history...
                </div>
              ) : filteredHistory.length === 0 ? (
                <div className="py-8 text-center text-muted-foreground border border-dashed rounded-xl">
                  No sessions recorded for this filter.
                </div>
              ) : (
                filteredHistory.map((session) => (
                  <div key={session.id} className="p-3.5 border rounded-xl flex items-center justify-between bg-card text-sm">
                    <div className="space-y-1">
                      <div className="font-medium flex items-center gap-2">
                        <span>{format(new Date(session.scheduled_date), 'EEEE, MMM d, yyyy')}</span>
                        {session.status === 'completed' ? (
                          <span className="text-xs px-2.5 py-0.5 bg-emerald-500/10 text-emerald-600 rounded-full font-medium">✓ Completed</span>
                        ) : session.status === 'skipped' ? (
                          <span className="text-xs px-2.5 py-0.5 bg-amber-500/10 text-amber-600 rounded-full font-medium">✕ Skipped</span>
                        ) : (
                          <span className="text-xs px-2.5 py-0.5 bg-red-500/10 text-red-500 rounded-full font-medium">✕ Missed</span>
                        )}
                      </div>
                      {session.notes && <p className="text-xs text-muted-foreground italic">&quot;{session.notes}&quot;</p>}
                    </div>
                    <div className="text-right text-xs font-mono text-muted-foreground shrink-0">
                      {session.actual_duration || session.planned_duration} mins
                    </div>
                  </div>
                ))
              )}
            </div>
          </DialogContent>
        </Dialog>
      )}
    </div>
  )
}
