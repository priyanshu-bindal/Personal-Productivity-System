'use client'

import { useState } from 'react'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { addExpense } from '@/lib/money-actions'
import { format } from 'date-fns'
import { useToast } from '@/components/ui/toast-provider'
import { TrafficLoader } from '@/components/ui/traffic-loader'

interface AddExpenseModalProps {
  isOpen: boolean
  onClose: () => void
}

const CATEGORIES = [
  'Food', 'Transport', 'Shopping', 'Education', 'Entertainment', 
  'Bills', 'Health', 'Travel', 'Personal', 'Subscriptions', 'Family', 'Other'
]

const PAYMENT_METHODS = [
  'Cash', 'UPI', 'Debit Card', 'Credit Card', 'Bank Transfer', 'Other'
]

export function AddExpenseModal({ isOpen, onClose }: AddExpenseModalProps) {
  const [amount, setAmount] = useState('')
  const [description, setDescription] = useState('')
  const [category, setCategory] = useState(CATEGORIES[0])
  const [paymentMethod, setPaymentMethod] = useState(PAYMENT_METHODS[1])
  const [date, setDate] = useState(format(new Date(), 'yyyy-MM-dd'))
  const [note, setNote] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const { success, error: showError } = useToast()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (isLoading) return
    setIsLoading(true)

    try {
      await addExpense({
        amount: parseFloat(amount),
        description,
        category,
        paymentMethod,
        date: new Date(date),
        note: note || undefined
      })
      success(`Expense recorded (₹${amount})`, description)
      setAmount('')
      setDescription('')
      setCategory(CATEGORIES[0])
      setNote('')
      onClose()
    } catch (err) {
      console.error(err)
      showError("Couldn't add expense", "Please try again.")
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && !isLoading && onClose()}>
      <DialogContent className="sm:max-w-[425px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Add Expense</DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="amount" className="text-lg">Amount (₹)</Label>
            <Input 
              id="amount" 
              type="number" 
              step="0.01"
              min="0.01" 
              value={amount} 
              onChange={e => setAmount(e.target.value)} 
              placeholder="0.00" 
              className="text-2xl h-12"
              required 
              autoFocus
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="description">Description</Label>
            <Input id="description" value={description} onChange={e => setDescription(e.target.value)} placeholder="e.g., Lunch with friends" required />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Category</Label>
              <Select value={category} onValueChange={(val) => val && setCategory(val)}>
                <SelectTrigger>
                  <SelectValue placeholder="Select..." />
                </SelectTrigger>
                <SelectContent>
                  {CATEGORIES.map(cat => (
                    <SelectItem key={cat} value={cat}>{cat}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="date">Date</Label>
              <Input id="date" type="date" value={date} onChange={e => setDate(e.target.value)} required />
            </div>
          </div>

          <div className="space-y-2">
            <Label>Payment Method</Label>
            <Select value={paymentMethod} onValueChange={(val) => val && setPaymentMethod(val)}>
              <SelectTrigger>
                <SelectValue placeholder="Select..." />
              </SelectTrigger>
              <SelectContent>
                {PAYMENT_METHODS.map(method => (
                  <SelectItem key={method} value={method}>{method}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="note">Optional Note</Label>
            <Textarea id="note" value={note} onChange={e => setNote(e.target.value)} placeholder="Additional details..." rows={2} />
          </div>

          <DialogFooter className="pt-4">
            <Button type="button" variant="outline" onClick={onClose} disabled={isLoading}>Cancel</Button>
            <Button type="submit" disabled={isLoading || !amount || !description.trim()} className="min-w-[120px]">
              {isLoading ? (
                <><TrafficLoader size="sm" className="mr-2" /> Adding...</>
              ) : (
                'Save Expense'
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
