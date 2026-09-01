'use client'

import { useState, useEffect } from 'react'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { createNote, updateNote } from '@/lib/actions'
import { useToast } from '@/components/ui/toast-provider'
import { Loader2 } from 'lucide-react'

interface NoteModalProps {
  isOpen: boolean
  onClose: () => void
  skills: any[]
}

export function CreateNoteModal({ isOpen, onClose, skills }: NoteModalProps) {
  const [title, setTitle] = useState('')
  const [content, setContent] = useState('')
  const [tags, setTags] = useState('')
  const [skillId, setSkillId] = useState<string>('none')
  const [isLoading, setIsLoading] = useState(false)
  const { success, error: showError } = useToast()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (isLoading) return
    setIsLoading(true)

    try {
      await createNote({
        title,
        content,
        tags,
        skillId: skillId === 'none' ? null : skillId
      })
      success("Note saved", title)
      setTitle('')
      setContent('')
      setTags('')
      setSkillId('none')
      onClose()
    } catch (err) {
      console.error(err)
      showError("Couldn't save note", "Please try again.")
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && !isLoading && onClose()}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>Create Note</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="title">Title</Label>
            <Input id="title" value={title} onChange={e => setTitle(e.target.value)} required autoFocus />
          </div>
          <div className="space-y-2">
            <Label htmlFor="content">Content</Label>
            <Textarea 
              id="content" 
              value={content} 
              onChange={e => setContent(e.target.value)} 
              required 
              rows={6}
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="tags">Tags (comma separated)</Label>
              <Input id="tags" value={tags} onChange={e => setTags(e.target.value)} placeholder="e.g. react, hooks" />
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
          </div>
          <DialogFooter className="pt-4">
            <Button type="button" variant="outline" onClick={onClose} disabled={isLoading}>Cancel</Button>
            <Button type="submit" disabled={isLoading || !title.trim() || !content.trim()} className="min-w-[110px]">
              {isLoading ? (
                <><Loader2 className="h-4 w-4 animate-spin mr-2" /> Saving...</>
              ) : (
                'Save Note'
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

export function EditNoteModal({ note, isOpen, onClose, skills }: { note: any, isOpen: boolean, onClose: () => void, skills: any[] }) {
  const [title, setTitle] = useState('')
  const [content, setContent] = useState('')
  const [tags, setTags] = useState('')
  const [skillId, setSkillId] = useState<string>('none')
  const [isLoading, setIsLoading] = useState(false)
  const { success, error: showError } = useToast()

  useEffect(() => {
    if (note && isOpen) {
      setTitle(note.title)
      setContent(note.content)
      const formattedTags = Array.isArray(note.tags) ? note.tags.join(', ') : (note.tags || '')
      setTags(formattedTags)
      setSkillId(note.skillId || 'none')
    }
  }, [note, isOpen])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (isLoading) return
    setIsLoading(true)

    try {
      await updateNote(note.id, {
        title,
        content,
        tags,
        skillId: skillId === 'none' ? null : skillId
      })
      success("Note updated", title)
      onClose()
    } catch (err) {
      console.error(err)
      showError("Couldn't update note", "Please try again.")
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && !isLoading && onClose()}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>Edit Note</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="edit-title">Title</Label>
            <Input id="edit-title" value={title} onChange={e => setTitle(e.target.value)} required />
          </div>
          <div className="space-y-2">
            <Label htmlFor="edit-content">Content</Label>
            <Textarea 
              id="edit-content" 
              value={content} 
              onChange={e => setContent(e.target.value)} 
              required 
              rows={6}
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="edit-tags">Tags (comma separated)</Label>
              <Input id="edit-tags" value={tags} onChange={e => setTags(e.target.value)} placeholder="e.g. react, hooks" />
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
          </div>
          <DialogFooter className="pt-4">
            <Button type="button" variant="outline" onClick={onClose} disabled={isLoading}>Cancel</Button>
            <Button type="submit" disabled={isLoading || !title.trim() || !content.trim()} className="min-w-[120px]">
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
