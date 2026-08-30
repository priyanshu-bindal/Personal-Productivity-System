'use client'

import { useState, useTransition } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Progress } from "@/components/ui/progress"
import { Checkbox } from "@/components/ui/checkbox"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Target, Flag, MoreVertical, Edit2, Trash2, Plus } from "lucide-react"
import { toggleMilestone, deleteGoal, createMilestone, deleteMilestone } from '@/lib/actions'
import { EditGoalModal } from './GoalModals'
import { format } from 'date-fns'

export function GoalList({ goals }: { goals: any[] }) {
  const [isPending, startTransition] = useTransition()
  const [editingGoal, setEditingGoal] = useState<any>(null)
  const [newMilestoneGoalId, setNewMilestoneGoalId] = useState<string | null>(null)
  const [milestoneTitle, setMilestoneTitle] = useState('')

  const handleToggleMilestone = (id: string, completed: boolean) => {
    startTransition(() => {
      toggleMilestone(id, completed)
    })
  }

  const handleDeleteGoal = (id: string) => {
    if (confirm("Are you sure you want to delete this goal?")) {
      startTransition(() => {
        deleteGoal(id)
      })
    }
  }

  const handleAddMilestone = (goalId: string) => {
    if (!milestoneTitle.trim()) return
    startTransition(async () => {
      await createMilestone(goalId, milestoneTitle)
      setMilestoneTitle('')
      setNewMilestoneGoalId(null)
    })
  }

  const handleDeleteMilestone = (id: string) => {
    if (confirm("Remove this milestone?")) {
      startTransition(() => {
        deleteMilestone(id)
      })
    }
  }

  if (goals.length === 0) {
    return (
      <div className="col-span-full py-12 text-center border-2 border-dashed rounded-xl">
        <Target className="h-10 w-10 text-muted-foreground mx-auto mb-4" />
        <h3 className="text-lg font-medium mb-2">No goals set</h3>
        <p className="text-muted-foreground">Define what you want to achieve long-term.</p>
      </div>
    )
  }

  return (
    <>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {goals.map((goal) => (
          <Card key={goal.id} className="group hover:border-primary/50 transition-all hover:shadow-md flex flex-col">
            <CardHeader className="pb-3">
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3 mb-2">
                  <div className="p-2 bg-orange-500/10 rounded-lg text-orange-500">
                    <Target className="h-5 w-5" />
                  </div>
                  <div>
                    <CardTitle className="text-xl">{goal.title}</CardTitle>
                    {goal.deadline && (
                      <div className="text-xs text-muted-foreground mt-1 font-medium">
                        Deadline: {format(new Date(goal.deadline), 'MMM d, yyyy')}
                      </div>
                    )}
                  </div>
                </div>
                <DropdownMenu>
                  <DropdownMenuTrigger className="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground h-10 w-10 -mr-2 -mt-2 opacity-0 group-hover:opacity-100">
                    <MoreVertical className="h-4 w-4" />
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem onClick={() => setEditingGoal(goal)}>
                      <Edit2 className="h-4 w-4 mr-2" /> Edit Goal
                    </DropdownMenuItem>
                    <DropdownMenuItem className="text-destructive" onClick={() => handleDeleteGoal(goal.id)}>
                      <Trash2 className="h-4 w-4 mr-2" /> Delete Goal
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>
              {goal.target && (
                <CardDescription>Target: {goal.target}</CardDescription>
              )}
            </CardHeader>
            <CardContent className="space-y-6 flex-1 flex flex-col">
              <div className="space-y-1.5">
                <div className="flex justify-between text-sm font-medium">
                  <span>Progress</span>
                  <span>{goal.progress}%</span>
                </div>
                <Progress value={goal.progress} className="h-2" />
              </div>
              
              <div className="space-y-3 pt-2 flex-1">
                <div className="flex items-center justify-between">
                  <h4 className="text-sm font-semibold flex items-center gap-2">
                    <Flag className="h-4 w-4" /> Milestones
                  </h4>
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    className="h-6 px-2 text-xs" 
                    onClick={() => setNewMilestoneGoalId(goal.id)}
                  >
                    <Plus className="h-3 w-3 mr-1" /> Add
                  </Button>
                </div>
                
                <div className="space-y-2">
                  {goal.milestones?.map((milestone: any) => (
                    <div key={milestone.id} className="flex items-start justify-between group/ms">
                      <div className="flex items-start gap-3">
                        <div className="pt-0.5">
                          <Checkbox 
                            checked={milestone.completed} 
                            onCheckedChange={(checked) => handleToggleMilestone(milestone.id, checked as boolean)}
                            disabled={isPending}
                          />
                        </div>
                        <span className={`text-sm ${milestone.completed ? 'line-through text-muted-foreground' : ''}`}>
                          {milestone.title}
                        </span>
                      </div>
                      <Button 
                        variant="ghost" 
                        size="icon" 
                        className="h-5 w-5 opacity-0 group-hover/ms:opacity-100 transition-opacity text-muted-foreground hover:text-destructive"
                        onClick={() => handleDeleteMilestone(milestone.id)}
                      >
                        <Trash2 className="h-3 w-3" />
                      </Button>
                    </div>
                  ))}

                  {newMilestoneGoalId === goal.id && (
                    <div className="flex items-center gap-2 mt-2">
                      <Input 
                        autoFocus
                        size={1}
                        className="h-7 text-sm"
                        placeholder="Milestone title..."
                        value={milestoneTitle}
                        onChange={e => setMilestoneTitle(e.target.value)}
                        onKeyDown={e => {
                          if (e.key === 'Enter') handleAddMilestone(goal.id)
                          if (e.key === 'Escape') setNewMilestoneGoalId(null)
                        }}
                      />
                      <Button size="sm" className="h-7 px-2" onClick={() => handleAddMilestone(goal.id)} disabled={!milestoneTitle.trim()}>
                        Save
                      </Button>
                    </div>
                  )}

                  {goal.milestones?.length === 0 && newMilestoneGoalId !== goal.id && (
                    <div className="text-xs text-muted-foreground italic pt-1">
                      No milestones yet.
                    </div>
                  )}
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <EditGoalModal 
        goal={editingGoal} 
        isOpen={!!editingGoal} 
        onClose={() => setEditingGoal(null)} 
      />
    </>
  )
}
