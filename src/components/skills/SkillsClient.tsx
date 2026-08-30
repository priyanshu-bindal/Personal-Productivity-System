'use client'

import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Progress } from "@/components/ui/progress"
import { Button } from "@/components/ui/button"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { SkillModal } from '@/components/skills/SkillModal'
import { ScheduleSessionModal, MarkPracticedModal } from '@/components/skills/SessionModals'
import { CreateTaskModal } from '@/components/tasks/TaskModals'
import { deleteSkill } from '@/lib/actions'
import * as Icons from "lucide-react"
import { MoreVertical, Edit, CalendarPlus, PlusSquare, FileText, CheckCircle, Trash2, ChevronRight, Plus } from 'lucide-react'
import Link from 'next/link'

export function SkillsClient({ initialSkills }: { initialSkills: any[] }) {
  const [isAddModalOpen, setIsAddModalOpen] = useState(false)
  const [editingSkill, setEditingSkill] = useState<any>(null)
  const [schedulingSkill, setSchedulingSkill] = useState<any>(null)
  const [practicingSkill, setPracticingSkill] = useState<any>(null)
  const [taskSkill, setTaskSkill] = useState<any>(null)
  
  const handleDelete = async (id: string) => {
    if (confirm("Are you sure you want to delete this skill? This cannot be undone.")) {
      try {
        await deleteSkill(id)
      } catch (err) {
        alert("Failed to delete skill.")
      }
    }
  }

  return (
    <div className="space-y-8">
      <header className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl md:text-4xl font-bold tracking-tight">My Skills</h1>
          <p className="text-muted-foreground text-lg mt-2">
            Track and manage your learning areas. Consistency over intensity.
          </p>
        </div>
        <Button onClick={() => setIsAddModalOpen(true)} className="gap-2">
          <Plus className="h-4 w-4" /> Add Skill
        </Button>
      </header>

      {initialSkills.length === 0 ? (
        <div className="py-16 text-center border border-dashed rounded-xl bg-card">
          <div className="mx-auto w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center mb-4">
            <Icons.BookOpen className="h-6 w-6 text-primary" />
          </div>
          <h3 className="text-xl font-medium mb-2">Build your personal learning system.</h3>
          <p className="text-muted-foreground mb-6 max-w-sm mx-auto">
            Add the skills you want to develop and schedule them across your week.
          </p>
          <Button onClick={() => setIsAddModalOpen(true)}>+ Add Your First Skill</Button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {initialSkills.map((skill) => {
            // @ts-ignore
            const Icon = skill.icon && Icons[skill.icon] ? Icons[skill.icon] : Icons.Book
            
            // Calculate progress if automatic
            const progress = skill.progressSource === 'Automatic' && skill.topics && skill.topics.length > 0
              ? Math.round(skill.topics.reduce((acc: number, t: any) => acc + t.progress, 0) / skill.topics.length)
              : skill.progress

            return (
              <Card key={skill.id} className="group hover:border-primary/50 transition-all hover:shadow-md relative">
                <CardHeader className="pb-3">
                  <div className="flex justify-between items-start">
                    <div className="p-2 bg-primary/10 rounded-lg text-primary">
                      <Icon className="h-6 w-6" />
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-medium px-2.5 py-1 bg-muted rounded-full text-muted-foreground">
                        {skill.level}
                      </span>
                      <DropdownMenu>
                        <DropdownMenuTrigger className="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 h-8 w-8 text-muted-foreground">
                          <MoreVertical className="h-4 w-4" />
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end" className="w-48">
                          <DropdownMenuItem onClick={() => setEditingSkill(skill)}><Edit className="mr-2 h-4 w-4" /> Edit Skill</DropdownMenuItem>
                          <DropdownMenuItem onClick={() => setSchedulingSkill(skill)}><CalendarPlus className="mr-2 h-4 w-4" /> Schedule Session</DropdownMenuItem>
                          <DropdownMenuItem onClick={() => setTaskSkill(skill)}><PlusSquare className="mr-2 h-4 w-4" /> Add Task</DropdownMenuItem>
                          <DropdownMenuItem><FileText className="mr-2 h-4 w-4" /> Add Note</DropdownMenuItem>
                          <DropdownMenuSeparator />
                          <DropdownMenuItem onClick={() => setPracticingSkill(skill)}><CheckCircle className="mr-2 h-4 w-4 text-emerald-500" /> Mark as Practiced</DropdownMenuItem>
                          <DropdownMenuSeparator />
                          <DropdownMenuItem>
                            <Link href={`/skills/${skill.id}`} className="flex w-full items-center"><ChevronRight className="mr-2 h-4 w-4" /> View Details</Link>
                          </DropdownMenuItem>
                          <DropdownMenuItem className="text-destructive focus:bg-destructive/10 focus:text-destructive" onClick={() => handleDelete(skill.id)}>
                            <Trash2 className="mr-2 h-4 w-4" /> Delete Skill
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </div>
                  </div>
                  <CardTitle className="text-xl mt-4">{skill.name}</CardTitle>
                  <CardDescription className="line-clamp-1">{skill.category}</CardDescription>
                </CardHeader>
                <CardContent className="space-y-5">
                  <div className="space-y-1.5">
                    <div className="flex justify-between text-sm font-medium">
                      <span>Progress</span>
                      <span>{progress}%</span>
                    </div>
                    <Progress value={progress} className="h-2" />
                  </div>
                  
                  <div className="grid grid-cols-2 gap-4 pt-4 border-t text-sm">
                    <div>
                      <p className="text-muted-foreground mb-1">Weekly Target</p>
                      <p className="font-medium">{skill.weeklyTarget} sessions</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground mb-1">Topics</p>
                      <p className="font-medium">{skill.topics?.length || 0}</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            )
          })}
        </div>
      )}

      {isAddModalOpen && (
        <SkillModal isOpen={isAddModalOpen} onClose={() => setIsAddModalOpen(false)} />
      )}
      
      {editingSkill && (
        <SkillModal isOpen={!!editingSkill} onClose={() => setEditingSkill(null)} skill={editingSkill} />
      )}
      
      {schedulingSkill && (
        <ScheduleSessionModal isOpen={!!schedulingSkill} onClose={() => setSchedulingSkill(null)} skillId={schedulingSkill.id} skillName={schedulingSkill.name} />
      )}
      
      {practicingSkill && (
        <MarkPracticedModal isOpen={!!practicingSkill} onClose={() => setPracticingSkill(null)} skillId={practicingSkill.id} skillName={practicingSkill.name} />
      )}

      {taskSkill && (
        <CreateTaskModal 
          isOpen={!!taskSkill} 
          onClose={() => setTaskSkill(null)} 
          skills={initialSkills}
          initialSkillId={taskSkill.id}
        />
      )}
    </div>
  )
}
