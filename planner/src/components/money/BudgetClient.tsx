'use client'

import { useState, useTransition } from 'react'
import { Card, CardContent } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { setBudget, deleteBudget } from '@/lib/money-actions'
import { Edit2, Check, X, AlertTriangle } from 'lucide-react'

const CATEGORIES = [
  'Food', 'Transport', 'Shopping', 'Education', 'Entertainment', 
  'Bills', 'Health', 'Travel', 'Personal', 'Subscriptions', 'Family', 'Other'
]

export function BudgetClient({ 
  budgets, 
  categoryBreakdown 
}: { 
  budgets: any[], 
  categoryBreakdown: { category: string, amount: number }[] 
}) {
  const [isPending, startTransition] = useTransition()
  const [editingCategory, setEditingCategory] = useState<string | null>(null)
  const [editValue, setEditValue] = useState('')

  const handleSave = (category: string) => {
    const limit = parseFloat(editValue)
    if (isNaN(limit) || limit <= 0) {
      alert('Please enter a valid budget amount.')
      return
    }

    startTransition(async () => {
      await setBudget(category, limit)
      setEditingCategory(null)
    })
  }

  const handleDelete = (id: string) => {
    startTransition(async () => {
      await deleteBudget(id)
    })
  }

  const getBudgetData = (category: string) => {
    const budget = budgets.find(b => b.category === category)
    const spent = categoryBreakdown.find(c => c.category === category)?.amount || 0
    return { budget, spent }
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {CATEGORIES.map(category => {
        const { budget, spent } = getBudgetData(category)
        const isEditing = editingCategory === category
        
        // If no budget is set, and we are not editing, just show a prompt to set it
        if (!budget && !isEditing) {
          return (
            <Card key={category} className="bg-muted/30 border-dashed hover:bg-muted/50 transition-colors">
              <CardContent className="p-6 flex flex-col items-center justify-center text-center space-y-3 h-full min-h-[160px]">
                <div className="font-medium">{category}</div>
                <div className="text-sm text-muted-foreground">No budget set</div>
                <Button 
                  variant="outline" 
                  size="sm" 
                  onClick={() => {
                    setEditingCategory(category)
                    setEditValue('')
                  }}
                >
                  Set Budget
                </Button>
              </CardContent>
            </Card>
          )
        }

        const limit = budget ? budget.monthlyLimit : 0
        const percentage = limit > 0 ? Math.round((spent / limit) * 100) : 0
        const isExceeded = percentage > 100

        return (
          <Card key={category} className={isExceeded ? "border-destructive/50 shadow-sm" : "shadow-sm"}>
            <CardContent className="p-6 space-y-4">
              <div className="flex items-center justify-between">
                <div className="font-medium text-lg">{category}</div>
                {!isEditing && budget && (
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    className="h-8 w-8 p-0 text-muted-foreground"
                    onClick={() => {
                      setEditingCategory(category)
                      setEditValue(budget.monthlyLimit.toString())
                    }}
                  >
                    <Edit2 className="h-4 w-4" />
                  </Button>
                )}
              </div>

              {isEditing ? (
                <div className="flex items-center gap-2">
                  <div className="relative flex-1">
                    <span className="absolute left-3 top-2.5 text-muted-foreground">₹</span>
                    <Input 
                      type="number"
                      value={editValue}
                      onChange={e => setEditValue(e.target.value)}
                      className="pl-8"
                      placeholder="0.00"
                      autoFocus
                    />
                  </div>
                  <Button size="icon" onClick={() => handleSave(category)} disabled={isPending}>
                    <Check className="h-4 w-4" />
                  </Button>
                  <Button size="icon" variant="outline" onClick={() => setEditingCategory(null)} disabled={isPending}>
                    <X className="h-4 w-4" />
                  </Button>
                </div>
              ) : (
                <div className="space-y-3">
                  <div className="flex justify-between items-end">
                    <div className="text-2xl font-bold tracking-tight">₹{spent.toLocaleString('en-IN')}</div>
                    <div className="text-sm text-muted-foreground mb-1">
                      / ₹{limit.toLocaleString('en-IN')}
                    </div>
                  </div>

                  <div className="space-y-1">
                    <div className="h-2 w-full bg-muted rounded-full overflow-hidden">
                      <div 
                        className={`h-full rounded-full transition-all ${
                          isExceeded ? 'bg-destructive' : percentage > 80 ? 'bg-amber-500' : 'bg-primary'
                        }`}
                        style={{ width: `${Math.min(percentage, 100)}%` }}
                      />
                    </div>
                    <div className="flex justify-between items-center text-xs">
                      <span className="font-medium">{percentage}%</span>
                      {isExceeded && (
                        <span className="flex items-center gap-1 text-destructive font-medium">
                          <AlertTriangle className="h-3 w-3" /> Budget exceeded
                        </span>
                      )}
                    </div>
                  </div>
                  
                  <div className="pt-2 flex justify-end">
                    <button 
                      onClick={() => handleDelete(budget.id)}
                      className="text-xs text-muted-foreground hover:text-destructive hover:underline"
                    >
                      Remove budget
                    </button>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        )
      })}
    </div>
  )
}
