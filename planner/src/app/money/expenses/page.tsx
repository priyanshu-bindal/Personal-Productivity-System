import { getExpenses } from '@/lib/money-actions'
import { MoneyNav } from '@/components/money/MoneyNav'
import { ExpenseList } from '@/components/money/ExpenseList'
import { DashboardActionButtons } from '@/components/money/DashboardActionButtons'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export const metadata = {
  title: 'All Expenses | Money | FocusFlow',
}

import { getCurrentUser } from '@/lib/auth'

export default async function ExpensesPage() {
  const user = await getCurrentUser()
  if (!user) redirect('/auth/signin')

  // We are fetching all expenses. In a real app we would paginate this.
  const expenses = await getExpenses()

  return (
    <div className="p-4 md:p-10 max-w-6xl mx-auto space-y-6 pb-24 md:pb-10 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <header className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl md:text-4xl font-bold tracking-tight">Money</h1>
          <p className="text-muted-foreground text-sm md:text-lg mt-1">
            History of all your expenses.
          </p>
        </div>
        <div className="w-full md:w-auto">
          <DashboardActionButtons />
        </div>
      </header>

      <MoneyNav />

      <div className="space-y-4">
        {/* We can add a simple filter bar here later. For now, display all expenses. */}
        <div className="flex justify-between items-center">
          <h2 className="text-xl font-semibold tracking-tight">All Expenses</h2>
          <div className="text-sm text-muted-foreground">{expenses.length} records</div>
        </div>

        <ExpenseList expenses={expenses} showDate={true} />
      </div>
    </div>
  )
}
