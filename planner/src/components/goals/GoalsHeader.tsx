'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Plus } from 'lucide-react'
import { CreateGoalModal } from './GoalModals'

export function GoalsHeader() {
  const [isOpen, setIsOpen] = useState(false)
  
  return (
    <>
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <header>
          <h1 className="text-3xl md:text-4xl font-bold tracking-tight">Goals</h1>
          <p className="text-muted-foreground text-lg mt-2">Set long-term objectives and track your milestones.</p>
        </header>
        <Button onClick={() => setIsOpen(true)}>
          <Plus className="h-4 w-4 mr-2" /> Add Goal
        </Button>
      </div>
      <CreateGoalModal isOpen={isOpen} onClose={() => setIsOpen(false)} />
    </>
  )
}
