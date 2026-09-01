'use client'

import { useState, useEffect, useTransition } from "react"
import { Card, CardContent } from "@/components/ui/card"
import { Calendar } from "@/components/ui/calendar"
import { format, isSameDay } from "date-fns"
import { getTasks, getSkills, updateTaskStatus } from "@/lib/actions"
import { Button } from "@/components/ui/button"
import { Checkbox } from "@/components/ui/checkbox"
import { Plus, CheckCircle2, Clock } from "lucide-react"
import { CreateTaskModal } from "@/components/tasks/TaskModals"

export default function CalendarClient() {
  const [date, setDate] = useState<Date | undefined>(new Date())
  const [tasks, setTasks] = useState<any[]>([])
  const [skills, setSkills] = useState<any[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [isTaskModalOpen, setIsTaskModalOpen] = useState(false)
  const [isPending, startTransition] = useTransition()

  const loadData = async () => {
    setIsLoading(true)
    try {
      const [tList, sList] = await Promise.all([getTasks(), getSkills()])
      setTasks(tList)
      setSkills(sList)
    } catch (err) {
      console.error(err)
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    loadData()
  }, [])

  const selectedDateTasks = tasks.filter(t => 
    t.scheduledDate && date && isSameDay(new Date(t.scheduledDate), date)
  )

  const handleToggleTask = (id: string, currentStatus: string) => {
    const nextStatus = currentStatus === 'Completed' ? 'Not Started' : 'Completed'
    startTransition(async () => {
      await updateTaskStatus(id, nextStatus)
      await loadData()
    })
  }

  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
      <div className="lg:col-span-4">
        <Card className="shadow-sm">
          <CardContent className="p-3">
            <Calendar
              mode="single"
              selected={date}
              onSelect={setDate}
              className="rounded-md mx-auto"
            />
          </CardContent>
        </Card>
      </div>
      
      <div className="lg:col-span-8">
        <Card className="min-h-[400px] shadow-sm flex flex-col">
          <CardContent className="p-6 flex-1 flex flex-col">
            <div className="flex items-center justify-between mb-6 pb-2 border-b">
              <h2 className="text-xl font-semibold">
                {date ? format(date, 'EEEE, MMMM do, yyyy') : 'Select a date'}
              </h2>
              <Button size="sm" className="gap-2" onClick={() => setIsTaskModalOpen(true)}>
                <Plus className="h-4 w-4" /> Add Task
              </Button>
            </div>
            
            <div className="space-y-3 flex-1">
              {isLoading ? (
                <div className="py-12 text-center text-muted-foreground animate-pulse">
                  Loading tasks...
                </div>
              ) : selectedDateTasks.length === 0 ? (
                <div className="py-12 text-center text-muted-foreground border border-dashed rounded-xl">
                  <p className="mb-3">No tasks scheduled for this date.</p>
                  <Button variant="outline" size="sm" onClick={() => setIsTaskModalOpen(true)}>
                    + Schedule Task
                  </Button>
                </div>
              ) : (
                selectedDateTasks.map(task => (
                  <div key={task.id} className="flex items-center justify-between p-3.5 border rounded-xl bg-card hover:border-primary/50 transition-colors">
                    <div className="flex items-center gap-3">
                      <Checkbox
                        checked={task.status === 'Completed'}
                        onCheckedChange={() => handleToggleTask(task.id, task.status)}
                        disabled={isPending}
                      />
                      <div>
                        <p className={`font-medium text-sm sm:text-base ${task.status === 'Completed' ? 'line-through text-muted-foreground' : ''}`}>
                          {task.title}
                        </p>
                        <div className="flex items-center gap-2 text-xs text-muted-foreground mt-0.5">
                          {task.skill?.name && <span className="bg-primary/10 text-primary px-2 py-0.5 rounded-md">{task.skill.name}</span>}
                          {task.duration && (
                            <span className="flex items-center gap-1">
                              <Clock className="h-3 w-3" /> {task.duration}m
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                    {task.status === 'Completed' && (
                      <CheckCircle2 className="h-5 w-5 text-emerald-500 shrink-0" />
                    )}
                  </div>
                ))
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      <CreateTaskModal
        isOpen={isTaskModalOpen}
        onClose={async () => {
          setIsTaskModalOpen(false)
          await loadData()
        }}
        skills={skills}
      />
    </div>
  )
}
