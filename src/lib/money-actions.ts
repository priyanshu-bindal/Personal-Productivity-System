'use server'

import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'
import { startOfDay, endOfDay, startOfMonth, endOfMonth, format, subMonths } from 'date-fns'

export type ExpenseData = {
  amount: number
  description: string
  category: string
  paymentMethod: string
  date: Date
  note?: string
}

export async function addExpense(data: ExpenseData) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('Unauthorized')

  const formattedPaymentMethod = data.paymentMethod.toLowerCase().replace(' ', '_')

  const { error } = await supabase.from('expenses').insert({
    amount: data.amount,
    description: data.description,
    category: data.category.toLowerCase(),
    payment_method: formattedPaymentMethod,
    expense_date: data.date.toISOString(),
    note: data.note || null,
    user_id: user.id
  })
  
  if (error) {
    console.error('addExpense error:', error)
    throw new Error(error.message)
  }
  
  revalidatePath('/money')
}

export async function updateExpense(id: string, data: Partial<ExpenseData>) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('Unauthorized')

  const updateData: any = {}
  if (data.amount !== undefined) updateData.amount = data.amount
  if (data.description !== undefined) updateData.description = data.description
  if (data.category !== undefined) updateData.category = data.category.toLowerCase()
  if (data.paymentMethod !== undefined) updateData.payment_method = data.paymentMethod.toLowerCase().replace(' ', '_')
  if (data.date !== undefined) updateData.expense_date = data.date.toISOString()
  if (data.note !== undefined) updateData.note = data.note

  const { error } = await supabase.from('expenses').update(updateData).eq('id', id)
  if (error) {
    console.error('updateExpense error:', error)
    throw new Error(error.message)
  }
  
  revalidatePath('/money')
}

export async function deleteExpense(id: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('Unauthorized')

  const { error } = await supabase.from('expenses').delete().eq('id', id)
  if (error) {
    console.error('deleteExpense error:', error)
    throw new Error(error.message)
  }
  
  revalidatePath('/money')
}

export async function getExpenses(filter?: {
  from?: Date
  to?: Date
  category?: string
  paymentMethod?: string
  minAmount?: number
  maxAmount?: number
  search?: string
}) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('Unauthorized')

  let query = supabase.from('expenses').select('*').order('expense_date', { ascending: false })

  if (filter?.from) query = query.gte('expense_date', filter.from.toISOString())
  if (filter?.to) query = query.lte('expense_date', filter.to.toISOString())
  if (filter?.category) query = query.eq('category', filter.category)
  if (filter?.paymentMethod) query = query.eq('payment_method', filter.paymentMethod)
  if (filter?.minAmount !== undefined) query = query.gte('amount', filter.minAmount)
  if (filter?.maxAmount !== undefined) query = query.lte('amount', filter.maxAmount)
  if (filter?.search) {
    query = query.or(`description.ilike.%${filter.search}%,category.ilike.%${filter.search}%,note.ilike.%${filter.search}%`)
  }

  const { data } = await query
  
  const dbToFrontendPayment: Record<string, string> = {
    'cash': 'Cash', 'upi': 'UPI', 'debit_card': 'Debit Card', 
    'credit_card': 'Credit Card', 'bank_transfer': 'Bank Transfer', 'other': 'Other'
  }

  const capitalize = (s: string) => s ? s.charAt(0).toUpperCase() + s.slice(1) : s
  
  return (data || []).map(e => ({
    ...e,
    category: capitalize(e.category),
    paymentMethod: dbToFrontendPayment[e.payment_method] || e.payment_method,
    date: new Date(e.expense_date)
  }))
}

export async function getMoneySummary() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('Unauthorized')

  const now = new Date()
  const todayStart = startOfDay(now).toISOString()
  const todayEnd = endOfDay(now).toISOString()
  const monthStart = startOfMonth(now).toISOString()
  const monthEnd = endOfMonth(now).toISOString()
  const prevMonthStart = startOfMonth(subMonths(now, 1)).toISOString()
  const prevMonthEnd = endOfMonth(subMonths(now, 1)).toISOString()

  const [
    { data: todayExpenses }, 
    { data: monthExpensesAsc }, 
    { data: prevMonthExpenses }, 
    { data: allMonthExpenses }
  ] = await Promise.all([
    supabase.from('expenses').select('*').gte('expense_date', todayStart).lte('expense_date', todayEnd),
    supabase.from('expenses').select('*').gte('expense_date', monthStart).lte('expense_date', monthEnd).order('expense_date', { ascending: true }),
    supabase.from('expenses').select('*').gte('expense_date', prevMonthStart).lte('expense_date', prevMonthEnd),
    supabase.from('expenses').select('*').gte('expense_date', monthStart).lte('expense_date', monthEnd)
  ])

  const dbToFrontendPayment: Record<string, string> = {
    'cash': 'Cash', 'upi': 'UPI', 'debit_card': 'Debit Card', 
    'credit_card': 'Credit Card', 'bank_transfer': 'Bank Transfer', 'other': 'Other'
  }
  const capitalize = (s: string) => s ? s.charAt(0).toUpperCase() + s.slice(1) : s

  const mapToCamel = (expenses: any[]) => expenses.map(e => ({
    ...e,
    category: capitalize(e.category),
    paymentMethod: dbToFrontendPayment[e.payment_method] || e.payment_method,
    date: new Date(e.expense_date)
  }))

  const today = mapToCamel(todayExpenses || [])
  const month = mapToCamel(allMonthExpenses || [])
  const prevMonth = mapToCamel(prevMonthExpenses || [])
  const monthAsc = mapToCamel(monthExpensesAsc || [])

  const todayTotal = today.reduce((s, e) => s + Number(e.amount), 0)
  const monthTotal = month.reduce((s, e) => s + Number(e.amount), 0)
  const prevMonthTotal = prevMonth.reduce((s, e) => s + Number(e.amount), 0)

  // average daily: sum / days elapsed
  const daysElapsed = now.getDate()
  const avgDaily = daysElapsed > 0 ? monthTotal / daysElapsed : 0

  // Highest category
  const categoryMap: Record<string, number> = {}
  for (const e of month) {
    categoryMap[e.category] = (categoryMap[e.category] || 0) + Number(e.amount)
  }
  let highestCategory = { name: 'N/A', amount: 0 }
  for (const [cat, amt] of Object.entries(categoryMap)) {
    if (amt > highestCategory.amount) highestCategory = { name: cat, amount: amt }
  }

  // Daily chart data for current month
  const dailyMap: Record<string, number> = {}
  for (const e of monthAsc) {
    const day = format(new Date(e.date), 'yyyy-MM-dd')
    dailyMap[day] = (dailyMap[day] || 0) + Number(e.amount)
  }
  const dailyData = Object.entries(dailyMap).map(([date, amount]) => ({ date, amount }))

  // Highest spending day
  const highestDay = dailyData.reduce((max, d) => d.amount > max.amount ? d : max, { date: 'N/A', amount: 0 })

  // Category breakdown for month
  const categoryBreakdown = Object.entries(categoryMap).map(([category, amount]) => ({
    category,
    amount,
    percentage: monthTotal > 0 ? Math.round((amount / monthTotal) * 100) : 0
  })).sort((a, b) => b.amount - a.amount)

  return {
    todayTotal,
    monthTotal,
    prevMonthTotal,
    avgDaily,
    highestCategory,
    dailyData,
    highestDay,
    categoryBreakdown,
    todayExpenses: today,
    monthExpenses: month,
    daysElapsed,
    monthComparisonPct: prevMonthTotal > 0 ? ((monthTotal - prevMonthTotal) / prevMonthTotal) * 100 : null
  }
}

export async function getBudgets(month?: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('Unauthorized')

  const monthKey = month || format(new Date(), 'yyyy-MM')
  // For Supabase we map month to a DATE column. We can use yyyy-MM-01.
  const dateKey = `${monthKey}-01`

  const { data } = await supabase.from('budgets').select('*').eq('month', dateKey)
  
  return (data || []).map(b => ({
    ...b,
    monthlyLimit: Number(b.monthly_limit),
    month: monthKey
  }))
}

export async function setBudget(category: string, monthlyLimit: number, month?: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('Unauthorized')

  const monthKey = month || format(new Date(), 'yyyy-MM')
  const dateKey = `${monthKey}-01`
  
  // Upsert is supported in Supabase using the ON CONFLICT clause but simplified with supabase-js:
  // We need to use `upsert` with the correct conflict columns or just delete and insert.
  
  const { data: existing } = await supabase
    .from('budgets')
    .select('id')
    .eq('category', category)
    .eq('month', dateKey)
    .single()
    
  if (existing) {
    const { error } = await supabase
      .from('budgets')
      .update({ monthly_limit: monthlyLimit })
      .eq('id', existing.id)
    if (error) throw new Error(error.message)
  } else {
    const { error } = await supabase
      .from('budgets')
      .insert({
        category: category.toLowerCase(),
        monthly_limit: monthlyLimit,
        month: dateKey,
        user_id: user.id
      })
    if (error) throw new Error(error.message)
  }
  
  revalidatePath('/money')
}

export async function deleteBudget(id: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('Unauthorized')

  const { error } = await supabase.from('budgets').delete().eq('id', id)
  if (error) throw new Error(error.message)
  
  revalidatePath('/money')
}
