import { getMoneySummary } from '@/lib/money-actions'
import { MoneyNav } from '@/components/money/MoneyNav'
import { DashboardActionButtons } from '@/components/money/DashboardActionButtons'
import { CategoryPieChart } from '@/components/money/SpendingCharts'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export const metadata = {
  title: 'Categories | Money | FocusFlow',
}

export default async function CategoriesPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/signin')

  const summary = await getMoneySummary()
  const f = (num: number) => num.toLocaleString('en-IN')

  return (
    <div className="p-4 md:p-10 max-w-6xl mx-auto space-y-6 pb-24 md:pb-10 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <header className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl md:text-4xl font-bold tracking-tight">Money</h1>
          <p className="text-muted-foreground text-sm md:text-lg mt-1">
            Spending by category for the current month.
          </p>
        </div>
        <div className="w-full md:w-auto">
          <DashboardActionButtons />
        </div>
      </header>

      <MoneyNav />

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Category Breakdown</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="py-4">
              <CategoryPieChart data={summary.categoryBreakdown} />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Top Spending Categories</CardTitle>
          </CardHeader>
          <CardContent>
            {summary.categoryBreakdown.length === 0 ? (
              <div className="py-8 text-center text-muted-foreground">
                No spending data for this month yet.
              </div>
            ) : (
              <div className="space-y-6">
                {summary.categoryBreakdown.map((cat, i) => (
                  <div key={cat.category} className="space-y-2">
                    <div className="flex justify-between font-medium">
                      <span className="flex items-center gap-2">
                        <span className="text-muted-foreground font-normal">{i + 1}.</span>
                        {cat.category}
                      </span>
                      <span>₹{f(cat.amount)}</span>
                    </div>
                    <div className="flex items-center gap-4">
                      <div className="h-2 flex-1 bg-muted rounded-full overflow-hidden">
                        <div 
                          className="h-full bg-primary" 
                          style={{ width: `${cat.percentage}%` }}
                        />
                      </div>
                      <span className="text-xs text-muted-foreground w-8 text-right">
                        {cat.percentage}%
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
