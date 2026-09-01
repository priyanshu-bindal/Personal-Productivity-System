'use client'

import { useState } from 'react'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { createGoal, updateGoal } from '@/lib/actions'
import { format } from 'date-fns'
import { useToast } from '@/components/ui/toast-provider'
import { Loader2 } from 'lucide-react'

interface CreateGoalModalProps {
  isOpen: boolean
  onClose: () => void
}

export function CreateGoalModal({ isOpen, onClose }: CreateGoalModalProps) {
  const [title, setTitle] = useState('')
  const [target, setTarget] = useState('')
  const [deadline, setDeadline] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const { success, error: showError } = useToast()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (isLoading) return
    setIsLoading(true)

    try {
      await createGoal({
        title,
        target: target || null,
        deadline: deadline ? new Date(deadline) : null
      })
      success("Goal added", title)
      setTitle('')
      setTarget('')
      setDeadline('')
      onClose()
    } catch (err) {
      console.error(err)
      showError("Couldn't add goal", "Please try again.")
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && !isLoading && onClose()}>
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
            <Button type="button" variant="outline" onClick={onClose} disabled={isLoading}>Cancel</Button>
            <Button type="submit" disabled={isLoading || !title.trim()} className="min-w-[110px]">
              {isLoading ? (
                <><Loader2 className="h-4 w-4 animate-spin mr-2" /> Adding...</>
              ) : (
                'Save Goal'
              )}
            </Button>
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
  const [isLoading, setIsLoading] = useState(false)
  const { success, error: showError } = useToast()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (isLoading) return
    setIsLoading(true)

    try {
      await updateGoal(goal.id, {
        title,
        target: target || null,
        deadline: deadline ? new Date(deadline) : null
      })
      success("Goal updated", title)
      onClose()
    } catch (err) {
      console.error(err)
      showError("Couldn't update goal", "Please try again.")
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && !isLoading && onClose()}>
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
            <Button type="button" variant="outline" onClick={onClose} disabled={isLoading}>Cancel</Button>
            <Button type="submit" disabled={isLoading || !title.trim()} className="min-w-[120px]">
              {isLoading ? (
                <><Loader2 className="h-4 w-4 animate-spin mr-2" /> Saving...</>
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
