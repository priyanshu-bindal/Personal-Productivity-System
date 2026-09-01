'use client'

import { useState } from 'react'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { createSkill, updateSkill } from '@/lib/actions'
import { useToast } from '@/components/ui/toast-provider'
import { Loader2 } from 'lucide-react'

const CATEGORIES = ["Programming", "Computer Science", "Communication", "Personal Development", "Career", "Other"]
const LEVELS = ["Beginner", "Intermediate", "Advanced"]
const ALL_DAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

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
  const [sessionDuration, setSessionDuration] = useState(skill?.sessionDuration?.toString() || '60')
  const [preferredDays, setPreferredDays] = useState<string[]>(skill?.preferredDays || ['Monday', 'Wednesday', 'Friday'])
  const [isLoading, setIsLoading] = useState(false)
  const { success, error: showError } = useToast()

  const toggleDay = (day: string) => {
    if (preferredDays.includes(day)) {
      if (preferredDays.length > 1) {
        setPreferredDays(preferredDays.filter(d => d !== day))
      }
    } else {
      setPreferredDays([...preferredDays, day])
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (isLoading) return // Prevent duplicate submission
    setIsLoading(true)
    
    const payload = {
      name,
      category,
      level,
      description,
      target,
      sessionDuration: parseInt(sessionDuration) || 60,
      preferredDays,
      weeklyTarget: preferredDays.length
    }

    try {
      if (skill?.id) {
        await updateSkill(skill.id, payload)
        success(`${name} updated`, 'Skill schedule saved.')
      } else {
        await createSkill(payload)
        success(`${name} added`, `${preferredDays.length} sessions/week auto-scheduled.`)
      }
      onClose()
    } catch (err) {
      console.error(err)
      showError("Couldn't save skill", "Please try again.")
      // Keep modal open so user doesn't lose data
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && !isLoading && onClose()}>
      <DialogContent className="sm:max-w-[500px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{skill ? 'Edit Skill & Schedule' : 'Add New Skill'}</DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="name">Skill Name</Label>
            <Input id="name" value={name} onChange={e => setName(e.target.value)} placeholder="e.g., Python, DSA, Communication" required autoFocus />
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
            <Label htmlFor="sessionDuration">Session Duration (minutes)</Label>
            <Select value={sessionDuration} onValueChange={setSessionDuration}>
              <SelectTrigger>
                <SelectValue placeholder="Select duration" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="30">30 minutes</SelectItem>
                <SelectItem value="45">45 minutes</SelectItem>
                <SelectItem value="60">60 minutes (1 hr)</SelectItem>
                <SelectItem value="90">90 minutes (1.5 hrs)</SelectItem>
                <SelectItem value="120">120 minutes (2 hrs)</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label>Practice Schedule (Preferred Days)</Label>
            <div className="flex flex-wrap gap-2 pt-1">
              {ALL_DAYS.map(day => {
                const isSelected = preferredDays.includes(day)
                return (
                  <button
                    key={day}
                    type="button"
                    onClick={() => toggleDay(day)}
                    className={`px-3 py-1.5 rounded-lg text-xs font-medium border transition-all ${
                      isSelected 
                        ? 'bg-primary text-primary-foreground border-primary' 
                        : 'bg-muted/50 text-muted-foreground border-transparent hover:bg-muted'
                    }`}
                  >
                    {day.slice(0, 3)}
                  </button>
                )
              })}
            </div>
            <p className="text-xs text-muted-foreground mt-1">
              {preferredDays.length} session{preferredDays.length !== 1 ? 's' : ''} per week automatically planned.
            </p>
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="description">Description (Optional)</Label>
            <Textarea id="description" value={description} onChange={e => setDescription(e.target.value)} placeholder="Briefly describe what you are mastering" rows={2} />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="target">Target / Goal (Optional)</Label>
            <Input id="target" value={target} onChange={e => setTarget(e.target.value)} placeholder="e.g., Complete 100 LeetCode problems" />
          </div>

          <DialogFooter className="pt-4">
            <Button type="button" variant="outline" onClick={onClose} disabled={isLoading}>Cancel</Button>
            <Button type="submit" disabled={isLoading || !name.trim()} className="min-w-[120px]">
              {isLoading ? (
                <><Loader2 className="h-4 w-4 animate-spin mr-2" /> Adding...</>
              ) : (
                skill ? 'Save Changes' : 'Create Skill'
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
