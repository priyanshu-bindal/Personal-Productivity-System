'use client'

import { useState } from 'react'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { createSkill, updateSkill } from '@/lib/actions'

const CATEGORIES = ["Programming", "Computer Science", "Communication", "Personal Development", "Career", "Other"]
const LEVELS = ["Beginner", "Intermediate", "Advanced"]

interface SkillModalProps {
  isOpen: boolean
  onClose: () => void
  skill?: any // If provided, we are editing
}

export function SkillModal({ isOpen, onClose, skill }: SkillModalProps) {
  const [name, setName] = useState(skill?.name || '')
  const [category, setCategory] = useState(skill?.category || 'Programming')
  const [level, setLevel] = useState(skill?.level || 'Beginner')
  const [description, setDescription] = useState(skill?.description || '')
  const [target, setTarget] = useState(skill?.target || '')
  const [weeklyTarget, setWeeklyTarget] = useState(skill?.weeklyTarget?.toString() || '3')
  const [progressSource, setProgressSource] = useState(skill?.progressSource || 'Automatic')
  const [progress, setProgress] = useState(skill?.progress?.toString() || '0')
  const [isLoading, setIsLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)
    
    const payload = {
      name,
      category,
      level,
      description,
      target,
      weeklyTarget: parseInt(weeklyTarget) || 3,
      progressSource,
      ...(progressSource === 'Manual' && { progress: parseInt(progress) || 0 })
    }

    try {
      if (skill?.id) {
        await updateSkill(skill.id, payload)
      } else {
        await createSkill(payload)
      }
      onClose()
    } catch (error) {
      console.error(error)
      alert("Failed to save skill")
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-[500px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{skill ? 'Edit Skill' : 'Add New Skill'}</DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="name">Skill Name</Label>
            <Input id="name" value={name} onChange={e => setName(e.target.value)} placeholder="e.g., DSA, Python" required />
          </div>
          
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Category</Label>
              <Select value={category} onValueChange={setCategory}>
                <SelectTrigger>
                  <SelectValue placeholder="Select..." />
                </SelectTrigger>
                <SelectContent>
                  {CATEGORIES.map(c => <SelectItem key={c} value={c}>{c}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
            
            <div className="space-y-2">
              <Label>Current Level</Label>
              <Select value={level} onValueChange={setLevel}>
                <SelectTrigger>
                  <SelectValue placeholder="Select..." />
                </SelectTrigger>
                <SelectContent>
                  {LEVELS.map(l => <SelectItem key={l} value={l}>{l}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="description">Description (Optional)</Label>
            <Textarea id="description" value={description} onChange={e => setDescription(e.target.value)} placeholder="Briefly describe this skill" rows={2} />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="target">Target / Goal</Label>
            <Input id="target" value={target} onChange={e => setTarget(e.target.value)} placeholder="e.g., Become comfortable with medium-level problems" />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="weeklyTarget">Weekly Target (Sessions)</Label>
              <Input id="weeklyTarget" type="number" min="1" max="21" value={weeklyTarget} onChange={e => setWeeklyTarget(e.target.value)} />
            </div>
            <div className="space-y-2">
              <Label>Progress Source</Label>
              <Select value={progressSource} onValueChange={setProgressSource}>
                <SelectTrigger>
                  <SelectValue placeholder="Select..." />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Automatic">Automatic (from topics)</SelectItem>
                  <SelectItem value="Manual">Manual Override</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          {progressSource === 'Manual' && (
            <div className="space-y-2 border-t pt-4 mt-4">
              <Label htmlFor="progress">Manual Progress (%)</Label>
              <Input id="progress" type="number" min="0" max="100" value={progress} onChange={e => setProgress(e.target.value)} />
            </div>
          )}

          <DialogFooter className="pt-4">
            <Button type="button" variant="outline" onClick={onClose} disabled={isLoading}>Cancel</Button>
            <Button type="submit" disabled={isLoading}>{skill ? 'Save Changes' : 'Create Skill'}</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
