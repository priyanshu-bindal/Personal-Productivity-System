'use client'

import { useState, useTransition } from 'react'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { createGoal, updateGoal } from '@/lib/actions'
import { format } from 'date-fns'

interface CreateGoalModalProps {
  isOpen: boolean
  onClose: () => void
}

export function CreateGoalModal({ isOpen, onClose }: CreateGoalModalProps) {
  const [title, setTitle] = useState('')
  const [target, setTarget] = useState('')
  const [deadline, setDeadline] = useState('')
  const [isPending, startTransition] = useTransition()

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    startTransition(async () => {
      await createGoal({
        title,
        target: target || null,
        deadline: deadline ? new Date(deadline) : null
      })
      setTitle('')
      setTarget('')
      setDeadline('')
      onClose()
    })
  }

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Create Goal</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="title">Goal Title</Label>
            <Input id="title" value={title} onChange={e => setTitle(e.target.value)} placeholder="e.g. Become strong in DSA" required autoFocus />
          </div>
          <div className="space-y-2">
            <Label htmlFor="target">Target (Optional)</Label>
            <Input id="target" value={target} onChange={e => setTarget(e.target.value)} placeholder="e.g. Complete 200 LeetCode problems" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="deadline">Deadline (Optional)</Label>
            <Input id="deadline" type="date" value={deadline} onChange={e => setDeadline(e.target.value)} />
          </div>
          <DialogFooter className="pt-4">
            <Button type="button" variant="outline" onClick={onClose} disabled={isPending}>Cancel</Button>
            <Button type="submit" disabled={isPending || !title}>Save</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

export function EditGoalModal({ goal, isOpen, onClose }: { goal: any, isOpen: boolean, onClose: () => void }) {
  const [title, setTitle] = useState(goal?.title || '')
  const [target, setTarget] = useState(goal?.target || '')
  const [deadline, setDeadline] = useState(goal?.deadline ? format(new Date(goal.deadline), 'yyyy-MM-dd') : '')
  const [isPending, startTransition] = useTransition()

  // Update state when goal changes
  if (isOpen && goal?.title !== undefined && title === '') {
    setTitle(goal.title)
    setTarget(goal.target || '')
    setDeadline(goal.deadline ? format(new Date(goal.deadline), 'yyyy-MM-dd') : '')
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    startTransition(async () => {
      await updateGoal(goal.id, {
        title,
        target: target || null,
        deadline: deadline ? new Date(deadline) : null
      })
      onClose()
    })
  }

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Edit Goal</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="edit-title">Goal Title</Label>
            <Input id="edit-title" value={title} onChange={e => setTitle(e.target.value)} required />
          </div>
          <div className="space-y-2">
            <Label htmlFor="edit-target">Target (Optional)</Label>
            <Input id="edit-target" value={target} onChange={e => setTarget(e.target.value)} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="edit-deadline">Deadline (Optional)</Label>
            <Input id="edit-deadline" type="date" value={deadline} onChange={e => setDeadline(e.target.value)} />
          </div>
          <DialogFooter className="pt-4">
            <Button type="button" variant="outline" onClick={onClose} disabled={isPending}>Cancel</Button>
            <Button type="submit" disabled={isPending || !title}>Save Changes</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
