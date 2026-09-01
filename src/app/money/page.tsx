import { getMoneySummary } from '@/lib/money-actions'
import { MoneyNav } from '@/components/money/MoneyNav'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { IndianRupee, TrendingUp, Calendar, CreditCard, ArrowUpRight, ArrowDownRight } from 'lucide-react'
import { AddExpenseModal } from '@/components/money/AddExpenseModal'
import { ExpenseList } from '@/components/money/ExpenseList'
import { DailySpendingChart, CategoryPieChart } from '@/components/money/SpendingCharts'
import { format } from 'date-fns'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'
import { DashboardActionButtons } from '@/components/money/DashboardActionButtons'
import { cn } from '@/lib/utils'

export const metadata = {
  title: 'Money Dashboard | FocusFlow',
}

import { getCurrentUser } from '@/lib/auth'

export default async function MoneyDashboard() {
  const user = await getCurrentUser()
  if (!user) redirect('/auth/signin')

  const summary = await getMoneySummary()
  
  // Format numbers securely
  const f = (num: number) => num.toLocaleString('en-IN')

  return (
    <div className="p-4 md:p-10 max-w-6xl mx-auto space-y-6 pb-24 md:pb-10 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <header className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl md:text-4xl font-bold tracking-tight">Money</h1>
          <p className="text-muted-foreground text-sm md:text-lg mt-1">
            Track where your money goes and understand your spending.
          </p>
        </div>
      </header>

      <MoneyNav />

      {/* Summary Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 md:gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Today's Spending</CardTitle>
            <IndianRupee className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">₹{f(summary.todayTotal)}</div>
            <p className="text-xs text-muted-foreground mt-1">
              {summary.todayExpenses.length} transaction(s) today
            </p>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">This Month</CardTitle>
            <Calendar className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">₹{f(summary.monthTotal)}</div>
            {summary.monthComparisonPct !== null && (
              <p className={cn(
                "text-xs mt-1 flex items-center",
                summary.monthComparisonPct > 0 ? "text-destructive" : "text-emerald-500"
              )}>
                {summary.monthComparisonPct > 0 ? <ArrowUpRight className="h-3 w-3 mr-1" /> : <ArrowDownRight className="h-3 w-3 mr-1" />}
                {Math.abs(summary.monthComparisonPct).toFixed(1)}% {summary.monthComparisonPct > 0 ? 'more' : 'less'} than last month
              </p>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Average Daily</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">₹{f(Math.round(summary.avgDaily))}</div>
            <p className="text-xs text-muted-foreground mt-1">
              Based on {summary.daysElapsed} days this month
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Highest Category</CardTitle>
            <CreditCard className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{summary.highestCategory.name}</div>
            <p className="text-xs text-muted-foreground mt-1">
              ₹{f(summary.highestCategory.amount)} spent
            </p>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column: Charts and Breakdowns */}
        <div className="lg:col-span-2 space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Daily Spending</CardTitle>
              <CardDescription>Your spending pattern for this month.</CardDescription>
            </CardHeader>
            <CardContent>
              <DailySpendingChart data={summary.dailyData} />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Where is my money going?</CardTitle>
              <CardDescription>Top spending categories this month.</CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col md:flex-row items-center gap-8">
              <div className="w-full md:w-1/2">
                <CategoryPieChart data={summary.categoryBreakdown.slice(0, 5)} />
              </div>
              <div className="w-full md:w-1/2 space-y-4">
                {summary.categoryBreakdown.slice(0, 5).map((cat, i) => (
                  <div key={cat.category} className="space-y-1">
                    <div className="flex justify-between text-sm font-medium">
                      <span>{i + 1}. {cat.category}</span>
                      <span>₹{f(cat.amount)}</span>
                    </div>
                    <div className="flex justify-between text-xs text-muted-foreground">
                      <span>{cat.percentage}%</span>
                    </div>
                    {/* Basic horizontal bar */}
                    <div className="h-1.5 w-full bg-muted rounded-full overflow-hidden">
                      <div 
                        className="h-full bg-primary" 
                        style={{ width: `${cat.percentage}%` }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Right Column: Actions & Today's List */}
        <div className="space-y-6">
          <Card className="bg-primary/5 border-primary/20">
            <CardContent className="p-6">
              <h3 className="font-semibold text-lg mb-2">Quick Action</h3>
              <p className="text-sm text-muted-foreground mb-4">Log a new expense quickly.</p>
              <DashboardActionButtons />
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-base font-semibold">Today's Spending</CardTitle>
              <Link href="/money/expenses" className="text-xs text-primary hover:underline font-medium">
                View All
              </Link>
            </CardHeader>
            <CardContent>
              {summary.todayExpenses.length === 0 ? (
                <div className="py-6 text-center text-sm text-muted-foreground">
                  No expenses recorded today.
                </div>
              ) : (
                <ExpenseList expenses={summary.todayExpenses} showDate={false} />
              )}
            </CardContent>
          </Card>

          {/* Spending Insights */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base font-semibold">Spending Insights</CardTitle>
            </CardHeader>
            <CardContent>
              <ul className="space-y-3 text-sm">
                {summary.highestCategory.amount > 0 && (
                  <li className="flex gap-2">
                    <span className="text-primary mt-0.5">•</span>
                    <span>You spent the most on <span className="font-medium">{summary.highestCategory.name}</span> this month.</span>
                  </li>
                )}
                {summary.monthComparisonPct !== null && summary.monthComparisonPct !== 0 && (
                  <li className="flex gap-2">
                    <span className="text-primary mt-0.5">•</span>
                    <span>Your spending {summary.monthComparisonPct > 0 ? 'increased' : 'decreased'} by <span className="font-medium">{Math.abs(summary.monthComparisonPct).toFixed(1)}%</span> compared with last month.</span>
                  </li>
                )}
                {summary.highestDay.amount > 0 && (
                  <li className="flex gap-2">
                    <span className="text-primary mt-0.5">•</span>
                    <span>Your highest spending day was <span className="font-medium">{format(new Date(summary.highestDay.date), 'MMMM do')}</span>.</span>
                  </li>
                )}
                {summary.todayExpenses.length === 0 && summary.monthExpenses.length > 0 && (
                  <li className="flex gap-2">
                    <span className="text-emerald-500 mt-0.5">•</span>
                    <span>You haven't spent any money today. Great job!</span>
                  </li>
                )}
                {summary.monthExpenses.length === 0 && (
                  <li className="flex gap-2 text-muted-foreground">
                    Start tracking your expenses to see insights here.
                  </li>
                )}
              </ul>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
