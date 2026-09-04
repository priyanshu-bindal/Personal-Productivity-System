'use client'

import { useState, useEffect } from 'react'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { createTask, updateTask } from '@/lib/actions'
import { format } from 'date-fns'
import { Textarea } from '@/components/ui/textarea'
import { useToast } from '@/components/ui/toast-provider'
import { TrafficLoader } from '@/components/ui/traffic-loader'

interface TaskModalProps {
  isOpen: boolean
  onClose: () => void
  skills: any[]
  goals?: any[]
  initialSkillId?: string
  initialGoalId?: string
}

export function CreateTaskModal({ 
  isOpen, 
  onClose, 
  skills, 
  goals = [], 
  initialSkillId = 'none',
  initialGoalId = 'none'
}: TaskModalProps) {
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [date, setDate] = useState(format(new Date(), 'yyyy-MM-dd'))
  const [time, setTime] = useState('09:00')
  const [duration, setDuration] = useState('60')
  const [priority, setPriority] = useState('Medium')
  const [skillId, setSkillId] = useState<string>(initialSkillId)
  const [goalId, setGoalId] = useState<string>(initialGoalId)
  const [isLoading, setIsLoading] = useState(false)
  const { success, error: showError } = useToast()

  useEffect(() => {
    if (isOpen) {
      setSkillId(initialSkillId || 'none')
      setGoalId(initialGoalId || 'none')
      setDate(format(new Date(), 'yyyy-MM-dd'))
    }
  }, [isOpen, initialSkillId, initialGoalId])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (isLoading) return
    setIsLoading(true)

    try {
      const scheduledDate = new Date(`${date}T${time || '09:00'}`)
      
      await createTask({
        title,
        description,
        scheduledDate,
        duration: parseInt(duration) || 60,
        priority,
        skillId: skillId === 'none' ? null : skillId,
        goalId: goalId === 'none' ? null : goalId
      })

      success("Task added successfully", title)

      setTitle('')
      setDescription('')
      setDate(format(new Date(), 'yyyy-MM-dd'))
      setTime('09:00')
      setDuration('60')
      setPriority('Medium')
      setSkillId('none')
      setGoalId('none')
      onClose()
    } catch (err) {
      console.error(err)
      showError("Couldn't add task", "Please try again.")
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && !isLoading && onClose()}>
      <DialogContent className="sm:max-w-[425px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Create Task</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="title">Task Title</Label>
            <Input id="title" value={title} onChange={e => setTitle(e.target.value)} placeholder="e.g., Solve 5 Binary Search problems" required autoFocus />
          </div>
          
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="date">Date</Label>
              <Input id="date" type="date" value={date} onChange={e => setDate(e.target.value)} required />
            </div>
            <div className="space-y-2">
              <Label htmlFor="time">Time (Optional)</Label>
              <Input id="time" type="time" value={time} onChange={e => setTime(e.target.value)} />
            </div>
          </div>
          
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="duration">Duration (mins)</Label>
              <Input id="duration" type="number" min="1" value={duration} onChange={e => setDuration(e.target.value)} required />
            </div>
            <div className="space-y-2">
              <Label>Priority</Label>
              <Select value={priority} onValueChange={(v) => setPriority(v || 'Medium')}>
                <SelectTrigger>
                  <SelectValue placeholder="Select..." />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Low">Low</SelectItem>
                  <SelectItem value="Medium">Medium</SelectItem>
                  <SelectItem value="High">High</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="skill">Related Skill (Optional)</Label>
            <Select value={skillId} onValueChange={(v) => setSkillId(v || 'none')}>
              <SelectTrigger>
                <SelectValue placeholder="Select a skill" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="none">None</SelectItem>
                {skills.map(s => (
                  <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {goals.length > 0 && (
            <div className="space-y-2">
              <Label htmlFor="goal">Related Goal (Optional)</Label>
              <Select value={goalId} onValueChange={(v) => setGoalId(v || 'none')}>
                <SelectTrigger>
                  <SelectValue placeholder="Select a goal" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="none">None</SelectItem>
                  {goals.map(g => (
                    <SelectItem key={g.id} value={g.id}>{g.title}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}

          <div className="space-y-2">
            <Label htmlFor="description">Description (Optional)</Label>
            <Textarea id="description" value={description} onChange={e => setDescription(e.target.value)} placeholder="Add any details..." rows={2} />
          </div>

          <DialogFooter className="pt-4">
            <Button type="button" variant="outline" onClick={onClose} disabled={isLoading}>Cancel</Button>
            <Button type="submit" disabled={isLoading || !title.trim()} className="min-w-[110px]">
              {isLoading ? (
                <><TrafficLoader size="sm" className="mr-2" /> Adding...</>
              ) : (
                'Save Task'
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

export function EditTaskModal({ task, isOpen, onClose, skills }: { task: any, isOpen: boolean, onClose: () => void, skills: any[] }) {
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [date, setDate] = useState('')
  const [time, setTime] = useState('')
  const [duration, setDuration] = useState('60')
  const [priority, setPriority] = useState('Medium')
  const [skillId, setSkillId] = useState<string>('none')
  const [isLoading, setIsLoading] = useState(false)
  const { success, error: showError } = useToast()

  useEffect(() => {
    if (task && isOpen) {
      setTitle(task.title)
      setDescription(task.description || '')
      if (task.scheduledDate) {
        const d = new Date(task.scheduledDate)
        setDate(format(d, 'yyyy-MM-dd'))
        setTime(format(d, 'HH:mm'))
      }
      setDuration(task.duration?.toString() || '60')
      setPriority(task.priority || 'Medium')
      setSkillId(task.skillId || 'none')
    }
  }, [task, isOpen])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (isLoading) return
    setIsLoading(true)

    try {
      const scheduledDate = date && time ? new Date(`${date}T${time}`) : null
      
      await updateTask(task.id, {
        title,
        description,
        scheduledDate,
        duration: parseInt(duration),
        priority,
        skillId: skillId === 'none' ? null : skillId
      })
      success("Task updated", title)
      onClose()
    } catch (err) {
      console.error(err)
      showError("Couldn't update task", "Please try again.")
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && !isLoading && onClose()}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Edit Task</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="edit-title">Task Title</Label>
            <Input id="edit-title" value={title} onChange={e => setTitle(e.target.value)} required />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="edit-description">Description (Optional)</Label>
            <Textarea id="edit-description" value={description} onChange={e => setDescription(e.target.value)} rows={2} />
          </div>
          
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="edit-date">Date</Label>
              <Input id="edit-date" type="date" value={date} onChange={e => setDate(e.target.value)} required />
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-time">Time</Label>
              <Input id="edit-time" type="time" value={time} onChange={e => setTime(e.target.value)} required />
            </div>
          </div>
          
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="edit-duration">Duration (mins)</Label>
              <Input id="edit-duration" type="number" min="1" value={duration} onChange={e => setDuration(e.target.value)} required />
            </div>
            <div className="space-y-2">
              <Label>Priority</Label>
              <Select value={priority} onValueChange={(v) => setPriority(v || 'Medium')}>
                <SelectTrigger>
                  <SelectValue placeholder="Select..." />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Low">Low</SelectItem>
                  <SelectItem value="Medium">Medium</SelectItem>
                  <SelectItem value="High">High</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="edit-skill">Related Skill (Optional)</Label>
            <Select value={skillId} onValueChange={(v) => setSkillId(v || 'none')}>
              <SelectTrigger>
                <SelectValue placeholder="Select a skill" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="none">None</SelectItem>
                {skills.map(s => (
                  <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <DialogFooter className="pt-4">
            <Button type="button" variant="outline" onClick={onClose} disabled={isLoading}>Cancel</Button>
            <Button type="submit" disabled={isLoading || !title.trim()} className="min-w-[120px]">
              {isLoading ? (
                <><TrafficLoader size="sm" className="mr-2" /> Saving...</>
              ) : (
                'Save Changes'
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
