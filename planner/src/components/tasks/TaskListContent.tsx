'use client'

import { useState, useTransition } from 'react'
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Checkbox } from "@/components/ui/checkbox"
import { format, isToday, isTomorrow, isPast, startOfToday, addDays, endOfDay } from "date-fns"
import { Clock, CheckCircle2, AlertCircle, CalendarDays, MoreVertical, Edit2, Trash2, RotateCcw } from "lucide-react"
import { updateTaskStatus, deleteTask } from '@/lib/actions'
import { EditTaskModal } from './TaskModals'

export function TaskListContent({ tasks, skills }: { tasks: any[], skills: any[] }) {
  const [isPending, startTransition] = useTransition()
  const [editingTask, setEditingTask] = useState<any>(null)

  const handleStatusToggle = (id: string, currentStatus: string) => {
    startTransition(() => {
      updateTaskStatus(id, currentStatus === 'Completed' ? 'Not Started' : 'Completed')
    })
  }

  const handleDelete = (id: string) => {
    if (confirm("Delete this task?")) {
      startTransition(() => {
        deleteTask(id)
      })
    }
  }

  const overdue = tasks.filter(t => t.scheduledDate && isPast(new Date(t.scheduledDate)) && !isToday(new Date(t.scheduledDate)) && t.status !== 'Completed')
  const today = tasks.filter(t => t.scheduledDate && isToday(new Date(t.scheduledDate)) && t.status !== 'Completed')
  const tomorrow = tasks.filter(t => t.scheduledDate && isTomorrow(new Date(t.scheduledDate)) && t.status !== 'Completed')
  const upcoming = tasks.filter(t => {
    if (!t.scheduledDate || t.status === 'Completed') return false
    const d = new Date(t.scheduledDate)
    const tmrwEnd = endOfDay(addDays(startOfToday(), 1))
    return d > tmrwEnd
  })
  const completed = tasks.filter(t => t.status === 'Completed')

  const priorityColor = (p: string) => {
    if (p === 'High') return 'destructive'
    if (p === 'Medium') return 'secondary'
    return 'outline'
  }

  const renderTask = (task: any, showDate = false) => (
    <Card key={task.id} className="transition-all hover:shadow-md overflow-hidden group">
      <CardContent className="p-4 flex items-start gap-4">
        <div className="pt-0.5">
          <Checkbox 
            checked={task.status === 'Completed'} 
            onCheckedChange={() => handleStatusToggle(task.id, task.status)}
            disabled={isPending}
          />
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            {task.skill && <span className="text-xs font-semibold text-primary">{task.skill.name}</span>}
            {task.duration && (
              <span className="text-xs text-muted-foreground flex items-center gap-1">
                <Clock className="w-3 h-3" /> {task.duration} min
              </span>
            )}
            {showDate && task.scheduledDate && (
              <span className="text-xs text-muted-foreground flex items-center gap-1">
                <CalendarDays className="w-3 h-3" /> {format(new Date(task.scheduledDate), 'MMM d')}
              </span>
            )}
            <Badge variant={priorityColor(task.priority) as any} className="ml-auto md:hidden">{task.priority}</Badge>
          </div>
          <h3 className={`font-medium mt-1 ${task.status === 'Completed' ? 'line-through text-muted-foreground' : ''}`}>
            {task.title}
          </h3>
          {task.description && (
            <p className="text-sm text-muted-foreground mt-0.5 truncate">{task.description}</p>
          )}
        </div>
        
        <div className="flex items-center gap-2">
          <Badge variant={priorityColor(task.priority) as any} className="hidden md:inline-flex">{task.priority}</Badge>
          <DropdownMenu>
            <DropdownMenuTrigger className="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground h-8 w-8 opacity-0 group-hover:opacity-100 transition-opacity">
              <MoreVertical className="h-4 w-4" />
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem onClick={() => setEditingTask(task)}>
                <Edit2 className="h-4 w-4 mr-2" /> Edit Task
              </DropdownMenuItem>
              {task.status === 'Completed' ? (
                <DropdownMenuItem onClick={() => handleStatusToggle(task.id, 'Completed')}>
                  <RotateCcw className="h-4 w-4 mr-2" /> Mark Incomplete
                </DropdownMenuItem>
              ) : (
                <DropdownMenuItem onClick={() => handleStatusToggle(task.id, 'Not Started')}>
                  <CheckCircle2 className="h-4 w-4 mr-2" /> Mark Complete
                </DropdownMenuItem>
              )}
              <DropdownMenuItem className="text-destructive" onClick={() => handleDelete(task.id)}>
                <Trash2 className="h-4 w-4 mr-2" /> Delete Task
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </CardContent>
    </Card>
  )

  const renderSection = (title: string, taskList: any[], icon: React.ReactNode, showDate = false) => {
    if (taskList.length === 0) return null
    return (
      <section className="space-y-3">
        <div className="flex items-center gap-2">
          {icon}
          <h2 className="text-lg font-semibold">{title}</h2>
          <Badge variant="secondary" className="ml-1">{taskList.length}</Badge>
        </div>
        <div className="space-y-3">
          {taskList.map(t => renderTask(t, showDate))}
        </div>
      </section>
    )
  }

  return (
    <>
      <div className="space-y-8">
        {renderSection('Overdue', overdue, <AlertCircle className="h-5 w-5 text-red-500" />)}
        {renderSection('Today', today, <CalendarDays className="h-5 w-5 text-primary" />)}
        {renderSection('Tomorrow', tomorrow, <CalendarDays className="h-5 w-5 text-blue-500" />)}
        {renderSection('Upcoming', upcoming, <CalendarDays className="h-5 w-5 text-muted-foreground" />, true)}
        {renderSection('Completed', completed, <CheckCircle2 className="h-5 w-5 text-emerald-500" />, true)}
      </div>

      {tasks.length === 0 && (
        <div className="py-16 text-center border border-dashed rounded-xl bg-card">
          <CalendarDays className="h-10 w-10 text-muted-foreground mx-auto mb-4" />
          <h3 className="text-xl font-medium mb-2">No tasks yet</h3>
          <p className="text-muted-foreground max-w-sm mx-auto">
            Click the + button in the bottom right to create your first task.
          </p>
        </div>
      )}

      <EditTaskModal 
        task={editingTask} 
        isOpen={!!editingTask} 
        onClose={() => setEditingTask(null)} 
        skills={skills}
      />
    </>
  )
}
