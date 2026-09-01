'use client'

import { useState, useEffect } from 'react'
import { Plus, Target, CheckSquare, BookOpen, StickyNote, IndianRupee } from 'lucide-react'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { motion } from 'framer-motion'
import { CreateTaskModal } from './tasks/TaskModals'
import { CreateNoteModal } from './notes/NoteModals'
import { SkillModal } from './skills/SkillModal'
import { AddExpenseModal } from './money/AddExpenseModal'
import { getSkills } from '@/lib/actions'

export function QuickAdd() {
  const [isOpen, setIsOpen] = useState(false)
  const [activeModal, setActiveModal] = useState<'task' | 'expense' | 'skill' | 'note' | null>(null)
  const [skills, setSkills] = useState<any[]>([])

  // Fetch skills for modals that need them
  useEffect(() => {
    if (activeModal === 'task' || activeModal === 'note') {
      getSkills().then(setSkills).catch(console.error)
    }
  }, [activeModal])

  return (
    <>
      <div className="fixed bottom-20 right-6 md:bottom-10 md:right-10 z-50">
        <DropdownMenu onOpenChange={setIsOpen}>
          <DropdownMenuTrigger className="focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary rounded-full">
            <motion.div
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              className="h-14 w-14 rounded-full bg-primary text-primary-foreground shadow-lg flex items-center justify-center hover:bg-primary/90"
            >
              <motion.div
                animate={{ rotate: isOpen ? 45 : 0 }}
                transition={{ type: "spring", stiffness: 260, damping: 20 }}
              >
                <Plus className="h-6 w-6" />
              </motion.div>
            </motion.div>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" sideOffset={12} className="w-56 p-2 rounded-xl shadow-xl">
            <DropdownMenuItem 
              className="py-3 px-4 cursor-pointer gap-3 rounded-lg focus:bg-primary/10"
              onClick={() => setActiveModal('task')}
            >
              <CheckSquare className="h-4 w-4 text-primary" />
              <span className="font-medium">Add Task</span>
            </DropdownMenuItem>
            <DropdownMenuItem 
              className="py-3 px-4 cursor-pointer gap-3 rounded-lg focus:bg-primary/10"
              onClick={() => setActiveModal('expense')}
            >
              <IndianRupee className="h-4 w-4 text-emerald-500" />
              <span className="font-medium">Add Expense</span>
            </DropdownMenuItem>
            <DropdownMenuItem 
              className="py-3 px-4 cursor-pointer gap-3 rounded-lg focus:bg-primary/10"
              onClick={() => setActiveModal('skill')}
            >
              <BookOpen className="h-4 w-4 text-blue-500" />
              <span className="font-medium">Add Skill</span>
            </DropdownMenuItem>
            <DropdownMenuItem 
              className="py-3 px-4 cursor-pointer gap-3 rounded-lg focus:bg-primary/10"
              onClick={() => setActiveModal('note')}
            >
              <StickyNote className="h-4 w-4 text-purple-500" />
              <span className="font-medium">Add Note</span>
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>

      <CreateTaskModal 
        isOpen={activeModal === 'task'} 
        onClose={() => setActiveModal(null)} 
        skills={skills} 
      />
      <AddExpenseModal
        isOpen={activeModal === 'expense'}
        onClose={() => setActiveModal(null)}
      />
      <CreateNoteModal 
        isOpen={activeModal === 'note'} 
        onClose={() => setActiveModal(null)} 
        skills={skills} 
      />
      <SkillModal 
        isOpen={activeModal === 'skill'} 
        onClose={() => setActiveModal(null)} 
      />
    </>
  )
}
