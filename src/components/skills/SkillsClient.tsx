'use client'

import { useState, useTransition, useCallback } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { SkillModal } from '@/components/skills/SkillModal'
import { completeLearningSession, deleteSkill, getSkillHistory, addLearningSession } from '@/lib/actions'
import { useToast } from '@/components/ui/toast-provider'
import * as Icons from "lucide-react"
import { MoreVertical, Edit, CheckCircle2, Trash2, Plus, Clock, Flame, History } from 'lucide-react'
import { TrafficLoader } from '@/components/ui/traffic-loader'
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
    <div className="space-y-6 sm:space-y-8 min-w-0 w-full">
      <header className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b pb-6 min-w-0">
        <div className="min-w-0">
          <h1 className="text-2xl sm:text-3xl md:text-4xl font-bold tracking-tight">My Skills</h1>
          <p className="text-muted-foreground text-xs sm:text-base md:text-lg mt-1">
            Consistent daily practice over intensity. Tell the app what to practice and when.
          </p>
        </div>
        <Button onClick={() => setIsAddModalOpen(true)} className="gap-2 self-start md:self-auto text-xs sm:text-sm shrink-0">
          <Plus className="h-4 w-4" /> Add Skill
        </Button>
      </header>

      {initialSkills.length === 0 ? (
        <div className="py-12 sm:py-16 text-center border border-dashed rounded-xl bg-card space-y-4 p-4 min-w-0">
          <div className="mx-auto w-10 h-10 sm:w-12 sm:h-12 bg-primary/10 rounded-full flex items-center justify-center">
            <Icons.BookOpen className="h-5 w-5 sm:h-6 sm:w-6 text-primary" />
          </div>
          <div>
            <h3 className="text-lg sm:text-xl font-medium">Build your learning system</h3>
            <p className="text-muted-foreground max-w-sm mx-auto text-xs sm:text-sm mt-1">
              Add skills you want to practice regularly (e.g. Python, DSA, Communication).
            </p>
          </div>
          <Button size="sm" onClick={() => setIsAddModalOpen(true)}>+ Add Your First Skill</Button>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6 min-w-0">
          {initialSkills.map((skill) => {
            const todaySession = skill.todaySession
            const isCompletedToday = todaySession?.status === 'completed'
            const hasPlannedToday = todaySession && todaySession.status === 'planned'

            return (
              <Card key={skill.id} className="group hover:border-primary/50 transition-all hover:shadow-md flex flex-col justify-between min-w-0">
                <CardHeader className="p-4 sm:p-6 pb-3 min-w-0">
                  <div className="flex justify-between items-start">
                    <div className="p-2 bg-primary/10 rounded-lg text-primary shrink-0">
                      <Icons.BookOpen className="h-5 w-5 sm:h-6 sm:w-6" />
                    </div>
                    <div className="flex items-center gap-1.5">
                      <span className="text-[11px] font-medium px-2 py-0.5 bg-muted rounded-full text-muted-foreground truncate">
                        {skill.level || 'Beginner'}
                      </span>
                      <DropdownMenu>
                        <DropdownMenuTrigger className="rounded-md h-8 w-8 inline-flex items-center justify-center text-muted-foreground hover:bg-accent focus:outline-none">
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

                  <CardTitle className="text-lg sm:text-xl mt-3 truncate">{skill.name}</CardTitle>
                  <CardDescription className="line-clamp-1 text-xs sm:text-sm">{skill.category}</CardDescription>
                </CardHeader>

                <CardContent className="p-4 sm:p-6 pt-0 sm:pt-0 space-y-4 flex-1 flex flex-col justify-between min-w-0">
                  {/* Today Session Highlight Box */}
                  <div className="p-3 rounded-xl border bg-muted/30 space-y-2 min-w-0">
                    <div className="text-[10px] sm:text-xs font-semibold text-muted-foreground flex items-center justify-between">
                      <span>TODAY</span>
                      <span className="flex items-center gap-1 font-mono">
                        <Clock className="h-3 w-3" /> {skill.sessionDuration}m
                      </span>
                    </div>

                    {isCompletedToday ? (
                      <div className="flex items-center justify-between text-emerald-500 font-medium text-xs sm:text-sm pt-0.5 min-w-0">
                        <span className="flex items-center gap-1.5 truncate">
                          <CheckCircle2 className="h-4 w-4 shrink-0" /> Session Completed
                        </span>
                        <span className="text-[11px] text-muted-foreground shrink-0 ml-1">{todaySession.actualDuration || skill.sessionDuration}m</span>
                      </div>
                    ) : hasPlannedToday ? (
                      <div className="flex items-center justify-between pt-0.5 gap-2 min-w-0">
                        <span className="text-xs sm:text-sm font-medium truncate">Practice {skill.name}</span>
                        <Button 
                          size="sm" 
                          className="bg-emerald-600 hover:bg-emerald-700 text-white gap-1 h-7 sm:h-8 text-xs font-semibold shrink-0"
                          onClick={() => handleCompleteToday(todaySession.id, skill.name)}
                          disabled={isPending || loadingSessionIds.has(todaySession.id)}
                        >
                          {loadingSessionIds.has(todaySession.id) ? (
                            <TrafficLoader size="sm" />
                          ) : (
                            <><CheckCircle2 className="h-3.5 w-3.5" /> Complete</>
                          )}
                        </Button>
                      </div>
                    ) : (
                      <div className="flex items-center justify-between pt-0.5 gap-2 min-w-0">
                        <span className="text-[11px] sm:text-xs text-muted-foreground truncate">
                          Next: <span className="font-medium text-foreground">{skill.nextSessionDate ? format(new Date(skill.nextSessionDate), 'EEE, MMM d') : 'Soon'}</span>
                        </span>
                        <Button 
                          size="sm" 
                          variant="outline"
                          className="hover:bg-emerald-500/10 hover:text-emerald-500 hover:border-emerald-500/50 gap-1 h-7 sm:h-8 text-xs font-semibold shrink-0"
                          onClick={() => handleLogPracticeToday(skill.id, skill.name, skill.sessionDuration)}
                          disabled={isPending || loadingSessionIds.has(skill.id)}
                        >
                          {loadingSessionIds.has(skill.id) ? (
                            <TrafficLoader size="sm" />
                          ) : (
                            <><CheckCircle2 className="h-3.5 w-3.5" /> Practice</>
                          )}
                        </Button>
                      </div>
                    )}
                  </div>

                  {/* Automatic Weekly Activity Progress Bar */}
                  <div className="space-y-1.5 min-w-0">
                    <div className="flex justify-between items-center text-xs">
                      <span className="font-medium text-muted-foreground truncate">
                        This Week: <span className="font-bold text-foreground">{skill.weeklyCompleted} / {skill.weeklyTarget}</span>
                      </span>
                      <span className="font-bold text-xs text-emerald-500 ml-1 shrink-0">
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
                  <div className="grid grid-cols-2 gap-2 pt-2 border-t text-xs min-w-0">
                    <div className="p-2 rounded-lg bg-card border min-w-0">
                      <p className="text-muted-foreground text-[10px] sm:text-xs mb-0.5 truncate">Consistency</p>
                      <p className="font-bold text-xs sm:text-sm text-primary truncate">{skill.consistencyPct}%</p>
                    </div>
                    <div className="p-2 rounded-lg bg-card border min-w-0">
                      <p className="text-muted-foreground text-[10px] sm:text-xs mb-0.5 truncate">Streak</p>
                      <p className="font-bold text-xs sm:text-sm text-orange-500 flex items-center gap-0.5 truncate">
                        <Flame className="h-3 w-3 shrink-0 inline" /> {skill.streak}d
                      </p>
                    </div>
                    <div className="p-2 rounded-lg bg-card border min-w-0">
                      <p className="text-muted-foreground text-[10px] sm:text-xs mb-0.5 truncate">Learning Time</p>
                      <p className="font-bold text-xs sm:text-sm text-foreground truncate">{skill.learningHours}h</p>
                    </div>
                    <div className="p-2 rounded-lg bg-card border min-w-0">
                      <p className="text-muted-foreground text-[10px] sm:text-xs mb-0.5 truncate">Target</p>
                      <p className="font-bold text-xs sm:text-sm text-foreground truncate">{skill.weeklyTarget}x / wk</p>
                    </div>
                  </div>

                  {/* Footer info & history trigger */}
                  <div className="flex justify-between items-center text-xs text-muted-foreground pt-1 min-w-0">
                    <button 
                      onClick={() => handleOpenHistory(skill)}
                      className="flex items-center gap-1 text-primary hover:underline font-medium text-xs truncate"
                    >
                      <History className="h-3.5 w-3.5 shrink-0" /> History
                    </button>
                    <span className="shrink-0 text-[11px]">{skill.preferredDays?.length || 3}d / wk</span>
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
          <DialogContent className="sm:max-w-[500px] max-h-[85vh] overflow-y-auto p-4 sm:p-6">
            <DialogHeader>
              <DialogTitle className="flex items-center justify-between text-base sm:text-lg">
                <span className="flex items-center gap-2 truncate">
                  <History className="h-5 w-5 text-primary shrink-0" />
                  {historySkill.name} History
                </span>
              </DialogTitle>
            </DialogHeader>

            {/* Filter Tabs */}
            <div className="flex gap-1 p-1 bg-muted rounded-lg text-xs font-medium min-w-0">
              <button 
                onClick={() => setHistoryFilter('all')} 
                className={`flex-1 py-1.5 rounded-md transition-all text-center ${historyFilter === 'all' ? 'bg-background shadow text-foreground font-semibold' : 'text-muted-foreground hover:text-foreground'}`}
              >
                All Time
              </button>
              <button 
                onClick={() => setHistoryFilter('month')} 
                className={`flex-1 py-1.5 rounded-md transition-all text-center ${historyFilter === 'month' ? 'bg-background shadow text-foreground font-semibold' : 'text-muted-foreground hover:text-foreground'}`}
              >
                This Month
              </button>
              <button 
                onClick={() => setHistoryFilter('week')} 
                className={`flex-1 py-1.5 rounded-md transition-all text-center ${historyFilter === 'week' ? 'bg-background shadow text-foreground font-semibold' : 'text-muted-foreground hover:text-foreground'}`}
              >
                This Week
              </button>
            </div>

            <div className="space-y-3 py-2 min-w-0">
              {isLoadingHistory ? (
                <div className="py-8 flex justify-center items-center">
                  <TrafficLoader size="sm" />
                </div>
              ) : filteredHistory.length === 0 ? (
                <div className="py-8 text-center text-xs sm:text-sm text-muted-foreground border border-dashed rounded-xl">
                  No sessions recorded for this filter.
                </div>
              ) : (
                filteredHistory.map((session) => (
                  <div key={session.id} className="p-3 border rounded-xl flex items-center justify-between bg-card text-xs sm:text-sm min-w-0">
                    <div className="space-y-0.5 min-w-0 pr-2">
                      <div className="font-medium flex flex-wrap items-center gap-1.5">
                        <span className="truncate">{format(new Date(session.scheduled_date), 'EEE, MMM d, yyyy')}</span>
                        {session.status === 'completed' ? (
                          <span className="text-[10px] px-2 py-0.5 bg-emerald-500/10 text-emerald-600 rounded-full font-medium shrink-0">✓ Completed</span>
                        ) : session.status === 'skipped' ? (
                          <span className="text-[10px] px-2 py-0.5 bg-amber-500/10 text-amber-600 rounded-full font-medium shrink-0">✕ Skipped</span>
                        ) : (
                          <span className="text-[10px] px-2 py-0.5 bg-red-500/10 text-red-500 rounded-full font-medium shrink-0">✕ Missed</span>
                        )}
                      </div>
                      {session.notes && <p className="text-xs text-muted-foreground italic truncate">&quot;{session.notes}&quot;</p>}
                    </div>
                    <div className="text-right text-xs font-mono text-muted-foreground shrink-0">
                      {session.actual_duration || session.planned_duration}m
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
