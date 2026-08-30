'use client'

import { useState, useTransition } from 'react'
import { Card, CardContent } from '@/components/ui/card'
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { Button } from '@/components/ui/button'
import { MoreVertical, Edit, Trash2, Coffee, Bus, ShoppingBag, GraduationCap, Gamepad2, Receipt, HeartPulse, Plane, User, Repeat, Users, HelpCircle } from 'lucide-react'
import { format } from 'date-fns'
import { deleteExpense } from '@/lib/money-actions'

const CategoryIcons: Record<string, any> = {
  'Food': Coffee,
  'Transport': Bus,
  'Shopping': ShoppingBag,
  'Education': GraduationCap,
  'Entertainment': Gamepad2,
  'Bills': Receipt,
  'Health': HeartPulse,
  'Travel': Plane,
  'Personal': User,
  'Subscriptions': Repeat,
  'Family': Users,
  'Other': HelpCircle
}

export function ExpenseList({ expenses, showDate = false }: { expenses: any[], showDate?: boolean }) {
  const [isPending, startTransition] = useTransition()

  const handleDelete = (id: string) => {
    if (confirm("Are you sure you want to delete this expense?")) {
      startTransition(async () => {
        await deleteExpense(id)
      })
    }
  }

  if (expenses.length === 0) {
    return (
      <div className="py-8 text-center text-muted-foreground border border-dashed rounded-xl bg-card">
        No expenses found for this period.
      </div>
    )
  }

  return (
    <div>
      {/* Mobile view: Card list */}
      <div className="md:hidden space-y-3">
        {expenses.map((expense) => {
          const Icon = CategoryIcons[expense.category] || HelpCircle
          return (
            <Card key={expense.id} className="shadow-sm">
              <CardContent className="p-3.5 sm:p-4 flex items-center gap-3">
                <div className="h-10 w-10 rounded-full bg-primary/10 text-primary flex items-center justify-center shrink-0">
                  <Icon className="h-5 w-5" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-sm sm:text-base truncate">{expense.description}</p>
                  <div className="flex flex-wrap items-center text-xs text-muted-foreground gap-x-1.5 gap-y-0.5 mt-0.5">
                    <span>{expense.category}</span>
                    <span>•</span>
                    <span>{expense.paymentMethod}</span>
                    {showDate && (
                      <>
                        <span>•</span>
                        <span>{format(new Date(expense.date), 'MMM d')}</span>
                      </>
                    )}
                  </div>
                </div>
                <div className="text-right shrink-0 flex items-center gap-1.5">
                  <span className="font-semibold text-base sm:text-lg tracking-tight">₹{expense.amount.toLocaleString('en-IN')}</span>
                  <DropdownMenu>
                    <DropdownMenuTrigger className="focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring rounded-full h-8 w-8 inline-flex items-center justify-center text-muted-foreground hover:bg-accent">
                      <MoreVertical className="h-4 w-4" />
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuItem className="text-destructive focus:text-destructive focus:bg-destructive/10" onClick={() => handleDelete(expense.id)}>
                        <Trash2 className="mr-2 h-4 w-4" /> Delete
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </div>
              </CardContent>
            </Card>
          )
        })}
      </div>

      {/* Desktop view: Table */}
      <div className="hidden md:block rounded-xl border bg-card overflow-hidden">
        <table className="w-full text-sm text-left">
          <thead className="bg-muted/50 text-muted-foreground font-medium border-b">
            <tr>
              {showDate && <th className="px-4 py-3 font-medium">Date</th>}
              <th className="px-4 py-3 font-medium">Description</th>
              <th className="px-4 py-3 font-medium">Category</th>
              <th className="px-4 py-3 font-medium">Payment</th>
              <th className="px-4 py-3 font-medium text-right">Amount</th>
              <th className="px-4 py-3 font-medium w-[50px]"></th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {expenses.map((expense) => {
              const Icon = CategoryIcons[expense.category] || HelpCircle
              return (
                <tr key={expense.id} className="hover:bg-muted/30 transition-colors">
                  {showDate && (
                    <td className="px-4 py-3 whitespace-nowrap text-muted-foreground">
                      {format(new Date(expense.date), 'MMM d, yyyy')}
                    </td>
                  )}
                  <td className="px-4 py-3 font-medium">{expense.description}</td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <Icon className="h-4 w-4 text-muted-foreground" />
                      {expense.category}
                    </div>
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">{expense.paymentMethod}</td>
                  <td className="px-4 py-3 font-semibold text-right tabular-nums">
                    ₹{expense.amount.toLocaleString('en-IN')}
                  </td>
                  <td className="px-4 py-3 text-right">
                    <DropdownMenu>
                      <DropdownMenuTrigger className="focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring rounded-md h-8 w-8 inline-flex items-center justify-center text-muted-foreground hover:bg-accent hover:text-accent-foreground">
                        <MoreVertical className="h-4 w-4" />
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem className="text-destructive focus:text-destructive focus:bg-destructive/10" onClick={() => handleDelete(expense.id)}>
                          <Trash2 className="mr-2 h-4 w-4" /> Delete
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </div>
  )
}
