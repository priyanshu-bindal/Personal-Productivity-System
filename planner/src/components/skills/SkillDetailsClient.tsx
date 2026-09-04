'use client'

import { useState, useTransition } from 'react'
import { Card, CardContent } from "@/components/ui/card"
import { Progress } from "@/components/ui/progress"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Slider } from "@/components/ui/slider"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog"
import { createSkillTopic, updateTopicProgress, deleteSkillTopic, addLearningSession } from '@/lib/actions'
import { Plus, X, CheckCircle2, Trash2 } from "lucide-react"

export function TopicsManager({ skillId, topics }: { skillId: string, topics: any[] }) {
  const [isAdding, setIsAdding] = useState(false)
  const [newTopicName, setNewTopicName] = useState('')
  const [isPending, startTransition] = useTransition()

  const handleAdd = () => {
    if (!newTopicName.trim()) return
    startTransition(async () => {
      await createSkillTopic(skillId, newTopicName.trim())
      setNewTopicName('')
      setIsAdding(false)
    })
  }

  const handleProgressChange = (topicId: string, value: number[]) => {
    startTransition(async () => {
      await updateTopicProgress(topicId, value[0])
    })
  }

  const handleDelete = (topicId: string) => {
    startTransition(async () => {
      await deleteSkillTopic(topicId)
    })
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-2xl font-semibold tracking-tight">Current Topics</h2>
        <Button variant="outline" size="sm" onClick={() => setIsAdding(true)} className="gap-1.5">
          <Plus className="h-3.5 w-3.5" /> Add Topic
        </Button>
      </div>

      {isAdding && (
        <div className="flex gap-2 p-4 border rounded-lg bg-muted/30">
          <Input
            placeholder="e.g., Arrays, Binary Search..."
            value={newTopicName}
            onChange={e => setNewTopicName(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && handleAdd()}
            autoFocus
          />
          <Button size="sm" onClick={handleAdd} disabled={isPending}>Add</Button>
          <Button size="sm" variant="ghost" onClick={() => setIsAdding(false)}><X className="h-4 w-4" /></Button>
        </div>
      )}

      <Card className="shadow-sm">
        <CardContent className="p-0">
          {topics.length === 0 ? (
            <div className="p-8 text-center text-muted-foreground">
              No topics added yet. Break down your skill into manageable topics to track progress.
            </div>
          ) : (
            <ul className="divide-y">
              {topics.map((topic) => (
                <li key={topic.id} className="p-4 group">
                  <div className="flex items-center justify-between mb-2">
                    <span className="font-medium">{topic.name}</span>
                    <div className="flex items-center gap-3">
                      <span className="text-sm font-medium w-10 text-right tabular-nums">{topic.progress}%</span>
                      <button
                        onClick={() => handleDelete(topic.id)}
                        className="opacity-0 group-hover:opacity-100 transition-opacity text-muted-foreground hover:text-destructive"
                      >
                        <Trash2 className="h-3.5 w-3.5" />
                      </button>
                    </div>
                  </div>
                  <Slider
                    defaultValue={[topic.progress]}
                    max={100}
                    step={5}
                    onValueCommitted={(value: any) => handleProgressChange(topic.id, value)}
                    className="cursor-pointer"
                  />
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>
    </div>
  )
}

export function MarkPracticedInline({ skillId, skillName }: { skillId: string, skillName: string }) {
  const [isOpen, setIsOpen] = useState(false)
  const [duration, setDuration] = useState('60')
  const [notes, setNotes] = useState('')
  const [topics, setTopics] = useState('')
  const [isPending, startTransition] = useTransition()

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    startTransition(async () => {
      await addLearningSession(skillId, {
        duration: parseInt(duration),
        notes: notes || undefined,
        topics: topics || undefined
      })
      setIsOpen(false)
      setDuration('60')
      setNotes('')
      setTopics('')
    })
  }

  return (
    <>
      <Button onClick={() => setIsOpen(true)} className="gap-2">
        <CheckCircle2 className="h-4 w-4" /> Mark as Practiced
      </Button>

      <Dialog open={isOpen} onOpenChange={setIsOpen}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Log {skillName} Practice</DialogTitle>
          </DialogHeader>
          <form onSubmit={handleSubmit} className="space-y-4 py-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">Duration (minutes)</label>
              <Input type="number" min="1" value={duration} onChange={e => setDuration(e.target.value)} required />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">Topics Covered (Optional)</label>
              <Input value={topics} onChange={e => setTopics(e.target.value)} placeholder="e.g., Arrays, HashMaps" />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">What did you work on? (Optional)</label>
              <textarea
                value={notes}
                onChange={e => setNotes(e.target.value)}
                placeholder="Brief summary..."
                rows={3}
                className="flex w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
              />
            </div>
            <DialogFooter className="pt-4">
              <Button type="button" variant="outline" onClick={() => setIsOpen(false)} disabled={isPending}>Cancel</Button>
              <Button type="submit" disabled={isPending}>{isPending ? 'Saving...' : 'Save Session'}</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </>
  )
}
