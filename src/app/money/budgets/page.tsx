import { getMoneySummary, getBudgets } from '@/lib/money-actions'
import { MoneyNav } from '@/components/money/MoneyNav'
import { DashboardActionButtons } from '@/components/money/DashboardActionButtons'
import { BudgetClient } from '@/components/money/BudgetClient'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export const metadata = {
  title: 'Budgets | Money | FocusFlow',
}

export default async function BudgetsPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/signin')

  const summary = await getMoneySummary()
  const budgets = await getBudgets()

  return (
    <div className="p-4 md:p-10 max-w-6xl mx-auto space-y-6 pb-24 md:pb-10 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <header className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl md:text-4xl font-bold tracking-tight">Money</h1>
          <p className="text-muted-foreground text-sm md:text-lg mt-1">
            Set and track monthly limits by category.
          </p>
        </div>
        <div className="w-full md:w-auto">
          <DashboardActionButtons />
        </div>
      </header>

      <MoneyNav />

      <BudgetClient 
        budgets={budgets} 
        categoryBreakdown={summary.categoryBreakdown} 
      />
    </div>
  )
}
