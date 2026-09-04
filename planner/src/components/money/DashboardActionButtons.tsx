'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { AddExpenseModal } from '@/components/money/AddExpenseModal'

export function DashboardActionButtons() {
  const [isOpen, setIsOpen] = useState(false)
  
  return (
    <>
      <Button className="w-full" onClick={() => setIsOpen(true)}>
        + Add Expense
      </Button>
      <AddExpenseModal isOpen={isOpen} onClose={() => setIsOpen(false)} />
    </>
  )
}
