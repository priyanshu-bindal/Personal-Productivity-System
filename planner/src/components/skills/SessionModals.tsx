'use client'

import { useState } from 'react'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { createTask, addLearningSession } from '@/lib/actions'
import { format } from 'date-fns'

interface ScheduleSessionModalProps {
  isOpen: boolean
  onClose: () => void
  skillId: string
  skillName: string
}

export function ScheduleSessionModal({ isOpen, onClose, skillId, skillName }: ScheduleSessionModalProps) {
  const [title, setTitle] = useState('')
  const [date, setDate] = useState(format(new Date(), 'yyyy-MM-dd'))
  const [time, setTime] = useState('18:00')
  const [duration, setDuration] = useState('60')
  const [priority, setPriority] = useState('Medium')
  const [isLoading, setIsLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)
    
    // Construct Date object from date string and time string
    const scheduledDate = new Date(`${date}T${time}`)
    
    try {
      await createTask({
        title,
        scheduledDate,
        duration: parseInt(duration),
        priority,
        skillId
      })
      onClose()
    } catch (err) {
      alert("Failed to schedule session")
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Schedule {skillName} Session</DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="title">Task / Objective</Label>
            <Input id="title" value={title} onChange={e => setTitle(e.target.value)} placeholder="e.g., Solve 5 Binary Search problems" required />
          </div>
          
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="date">Date</Label>
              <Input id="date" type="date" value={date} onChange={e => setDate(e.target.value)} required />
            </div>
            <div className="space-y-2">
              <Label htmlFor="time">Time</Label>
              <Input id="time" type="time" value={time} onChange={e => setTime(e.target.value)} required />
            </div>
          </div>
          
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="duration">Duration (minutes)</Label>
              <Input id="duration" type="number" min="1" value={duration} onChange={e => setDuration(e.target.value)} required />
            </div>
            <div className="space-y-2">
              <Label>Priority</Label>
              <Select value={priority} onValueChange={(val) => val && setPriority(val)}>
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

          <DialogFooter className="pt-4">
            <Button type="button" variant="outline" onClick={onClose} disabled={isLoading}>Cancel</Button>
            <Button type="submit" disabled={isLoading}>Schedule</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

interface MarkPracticedModalProps {
  isOpen: boolean
  onClose: () => void
  skillId: string
  skillName: string
}

export function MarkPracticedModal({ isOpen, onClose, skillId, skillName }: MarkPracticedModalProps) {
  const [duration, setDuration] = useState('60')
  const [notes, setNotes] = useState('')
  const [topics, setTopics] = useState('')
  const [isLoading, setIsLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)
    
    try {
      await addLearningSession(skillId, {
        duration: parseInt(duration),
        notes,
        topics
      })
      onClose()
    } catch (err) {
      alert("Failed to save session")
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Mark {skillName} as Practiced</DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="duration">Duration (minutes)</Label>
            <Input id="duration" type="number" min="1" value={duration} onChange={e => setDuration(e.target.value)} required />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="topics">Topics Covered (Optional)</Label>
            <Input id="topics" value={topics} onChange={e => setTopics(e.target.value)} placeholder="e.g., Arrays, HashMaps" />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="notes">What did you work on? (Optional)</Label>
            <Textarea id="notes" value={notes} onChange={e => setNotes(e.target.value)} placeholder="Brief summary of your session..." rows={3} />
          </div>

          <DialogFooter className="pt-4">
            <Button type="button" variant="outline" onClick={onClose} disabled={isLoading}>Cancel</Button>
            <Button type="submit" disabled={isLoading}>Save Session</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
