import { getMoneySummary } from '@/lib/money-actions'
import { MoneyNav } from '@/components/money/MoneyNav'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { IndianRupee, TrendingUp, Calendar, CreditCard, ArrowUpRight, ArrowDownRight } from 'lucide-react'
import { ExpenseList } from '@/components/money/ExpenseList'
import { DailySpendingChart, CategoryPieChart } from '@/components/money/SpendingCharts'
import { format } from 'date-fns'
import { redirect } from 'next/navigation'
import Link from 'next/link'
import { DashboardActionButtons } from '@/components/money/DashboardActionButtons'
import { cn } from '@/lib/utils'
import { getCurrentUser } from '@/lib/auth'

export const metadata = {
  title: 'Money Dashboard | FocusFlow',
}

export default async function MoneyDashboard() {
  const user = await getCurrentUser()
  if (!user) redirect('/auth/signin')

  const summary = await getMoneySummary()
  
  // Format numbers securely
  const f = (num: number) => num.toLocaleString('en-IN')

  return (
    <div className="p-4 md:p-10 max-w-6xl mx-auto space-y-6 pb-24 md:pb-10 min-w-0 w-full animate-in fade-in slide-in-from-bottom-4 duration-500">
      <header className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl md:text-4xl font-bold tracking-tight">Money</h1>
          <p className="text-muted-foreground text-xs sm:text-sm md:text-lg mt-1">
            Track where your money goes and understand your spending.
          </p>
        </div>
      </header>

      <MoneyNav />

      {/* Summary Cards */}
      <div className="grid grid-cols-2 min-w-0 sm:grid-cols-2 lg:grid-cols-4 gap-3 md:gap-4">
        <Card className="min-w-0">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 p-3 sm:p-4 pb-1 sm:pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium truncate">Today&apos;s Spending</CardTitle>
            <IndianRupee className="h-3.5 w-3.5 sm:h-4 sm:w-4 text-muted-foreground shrink-0" />
          </CardHeader>
          <CardContent className="p-3 sm:p-4 pt-0">
            <div className="text-lg sm:text-2xl font-bold truncate">₹{f(summary.todayTotal)}</div>
            <p className="text-[11px] sm:text-xs text-muted-foreground mt-0.5 truncate">
              {summary.todayExpenses.length} transaction(s) today
            </p>
          </CardContent>
        </Card>
        
        <Card className="min-w-0">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 p-3 sm:p-4 pb-1 sm:pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium truncate">This Month</CardTitle>
            <Calendar className="h-3.5 w-3.5 sm:h-4 sm:w-4 text-muted-foreground shrink-0" />
          </CardHeader>
          <CardContent className="p-3 sm:p-4 pt-0">
            <div className="text-lg sm:text-2xl font-bold truncate">₹{f(summary.monthTotal)}</div>
            {summary.monthComparisonPct !== null && (
              <p className={cn(
                "text-[10px] sm:text-xs mt-0.5 flex items-center truncate",
                summary.monthComparisonPct > 0 ? "text-destructive" : "text-emerald-500"
              )}>
                {summary.monthComparisonPct > 0 ? <ArrowUpRight className="h-3 w-3 mr-0.5 shrink-0" /> : <ArrowDownRight className="h-3 w-3 mr-0.5 shrink-0" />}
                {Math.abs(summary.monthComparisonPct).toFixed(1)}% {summary.monthComparisonPct > 0 ? 'more' : 'less'}
              </p>
            )}
          </CardContent>
        </Card>

        <Card className="min-w-0">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 p-3 sm:p-4 pb-1 sm:pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium truncate">Average Daily</CardTitle>
            <TrendingUp className="h-3.5 w-3.5 sm:h-4 sm:w-4 text-muted-foreground shrink-0" />
          </CardHeader>
          <CardContent className="p-3 sm:p-4 pt-0">
            <div className="text-lg sm:text-2xl font-bold truncate">₹{f(Math.round(summary.avgDaily))}</div>
            <p className="text-[11px] sm:text-xs text-muted-foreground mt-0.5 truncate">
              {summary.daysElapsed} days this month
            </p>
          </CardContent>
        </Card>

        <Card className="min-w-0">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 p-3 sm:p-4 pb-1 sm:pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium truncate">Highest Category</CardTitle>
            <CreditCard className="h-3.5 w-3.5 sm:h-4 sm:w-4 text-muted-foreground shrink-0" />
          </CardHeader>
          <CardContent className="p-3 sm:p-4 pt-0">
            <div className="text-lg sm:text-2xl font-bold truncate">{summary.highestCategory.name}</div>
            <p className="text-[11px] sm:text-xs text-muted-foreground mt-0.5 truncate">
              ₹{f(summary.highestCategory.amount)} spent
            </p>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 min-w-0">
        {/* Left Column: Charts and Breakdowns */}
        <div className="lg:col-span-2 space-y-6 min-w-0">
          <Card className="min-w-0 overflow-hidden">
            <CardHeader className="p-4 sm:p-6 pb-2">
              <CardTitle className="text-base sm:text-lg">Daily Spending</CardTitle>
              <CardDescription className="text-xs sm:text-sm">Your spending pattern for this month.</CardDescription>
            </CardHeader>
            <CardContent className="p-2 sm:p-6">
              <DailySpendingChart data={summary.dailyData} />
            </CardContent>
          </Card>

          <Card className="min-w-0 overflow-hidden">
            <CardHeader className="p-4 sm:p-6 pb-2">
              <CardTitle className="text-base sm:text-lg">Where is my money going?</CardTitle>
              <CardDescription className="text-xs sm:text-sm">Top spending categories this month.</CardDescription>
            </CardHeader>
            <CardContent className="p-4 sm:p-6 flex flex-col md:flex-row items-center gap-6 sm:gap-8">
              <div className="w-full md:w-1/2 min-w-0">
                <CategoryPieChart data={summary.categoryBreakdown.slice(0, 5)} />
              </div>
              <div className="w-full md:w-1/2 space-y-3 sm:space-y-4 min-w-0">
                {summary.categoryBreakdown.slice(0, 5).map((cat, i) => (
                  <div key={cat.category} className="space-y-1 min-w-0">
                    <div className="flex justify-between text-xs sm:text-sm font-medium min-w-0">
                      <span className="truncate">{i + 1}. {cat.category}</span>
                      <span className="shrink-0 ml-2">₹{f(cat.amount)}</span>
                    </div>
                    <div className="flex justify-between text-[11px] sm:text-xs text-muted-foreground">
                      <span>{cat.percentage}%</span>
                    </div>
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
        <div className="space-y-6 min-w-0">
          <Card className="bg-primary/5 border-primary/20 min-w-0">
            <CardContent className="p-4 sm:p-6">
              <h3 className="font-semibold text-base sm:text-lg mb-1 sm:mb-2">Quick Action</h3>
              <p className="text-xs sm:text-sm text-muted-foreground mb-3 sm:mb-4">Log a new expense quickly.</p>
              <DashboardActionButtons />
            </CardContent>
          </Card>

          <Card className="min-w-0">
            <CardHeader className="flex flex-row items-center justify-between p-4 sm:p-6 pb-2">
              <CardTitle className="text-base font-semibold">Today&apos;s Spending</CardTitle>
              <Link href="/money/expenses" className="text-xs text-primary hover:underline font-medium">
                View All
              </Link>
            </CardHeader>
            <CardContent className="p-3 sm:p-6 pt-0 sm:pt-0">
              {summary.todayExpenses.length === 0 ? (
                <div className="py-6 text-center text-xs sm:text-sm text-muted-foreground">
                  No expenses recorded today.
                </div>
              ) : (
                <ExpenseList expenses={summary.todayExpenses} showDate={false} />
              )}
            </CardContent>
          </Card>

          {/* Spending Insights */}
          <Card className="min-w-0">
            <CardHeader className="p-4 sm:p-6 pb-2">
              <CardTitle className="text-base font-semibold">Spending Insights</CardTitle>
            </CardHeader>
            <CardContent className="p-4 sm:p-6 pt-0 sm:pt-0">
              <ul className="space-y-2.5 text-xs sm:text-sm">
                {summary.highestCategory.amount > 0 && (
                  <li className="flex gap-2">
                    <span className="text-primary shrink-0 mt-0.5">•</span>
                    <span>You spent the most on <span className="font-medium">{summary.highestCategory.name}</span> this month.</span>
                  </li>
                )}
                {summary.monthComparisonPct !== null && summary.monthComparisonPct !== 0 && (
                  <li className="flex gap-2">
                    <span className="text-primary shrink-0 mt-0.5">•</span>
                    <span>Your spending {summary.monthComparisonPct > 0 ? 'increased' : 'decreased'} by <span className="font-medium">{Math.abs(summary.monthComparisonPct).toFixed(1)}%</span> compared with last month.</span>
                  </li>
                )}
                {summary.highestDay.amount > 0 && (
                  <li className="flex gap-2">
                    <span className="text-primary shrink-0 mt-0.5">•</span>
                    <span>Your highest spending day was <span className="font-medium">{format(new Date(summary.highestDay.date), 'MMMM do')}</span>.</span>
                  </li>
                )}
                {summary.todayExpenses.length === 0 && summary.monthExpenses.length > 0 && (
                  <li className="flex gap-2">
                    <span className="text-emerald-500 shrink-0 mt-0.5">•</span>
                    <span>You haven&apos;t spent any money today. Great job!</span>
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
