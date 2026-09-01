'use server'

import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'
import { startOfDay, endOfDay, startOfMonth, endOfMonth, format, subMonths } from 'date-fns'

import { getCurrentUser } from '@/lib/auth'

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
  const dateStr = format(data.date, 'yyyy-MM-dd')

  const { error } = await supabase.from('expenses').insert({
    amount: data.amount,
    description: data.description,
    category: data.category.toLowerCase(),
    payment_method: formattedPaymentMethod,
    expense_date: dateStr,
    note: data.note || null,
    user_id: user.id
  })
  
  if (error) {
    console.error('addExpense error:', error)
    throw new Error(error.message)
  }
  
  revalidatePath('/money')
  revalidatePath('/money/expenses')
  revalidatePath('/money/categories')
  revalidatePath('/money/budgets')
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
  if (data.date !== undefined) updateData.expense_date = format(data.date, 'yyyy-MM-dd')
  if (data.note !== undefined) updateData.note = data.note

  const { error } = await supabase.from('expenses').update(updateData).eq('id', id)
  if (error) {
    console.error('updateExpense error:', error)
    throw new Error(error.message)
  }
  
  revalidatePath('/money')
  revalidatePath('/money/expenses')
  revalidatePath('/money/categories')
  revalidatePath('/money/budgets')
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
  revalidatePath('/money/expenses')
  revalidatePath('/money/categories')
  revalidatePath('/money/budgets')
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
  const user = await getCurrentUser()
  if (!user) return []
  const supabase = await createClient()

  let query = supabase.from('expenses').select('*').eq('user_id', user.id).order('expense_date', { ascending: false })

  if (filter?.from) query = query.gte('expense_date', format(filter.from, 'yyyy-MM-dd'))
  if (filter?.to) query = query.lte('expense_date', format(filter.to, 'yyyy-MM-dd'))
  if (filter?.category) query = query.eq('category', filter.category.toLowerCase())
  if (filter?.paymentMethod) query = query.eq('payment_method', filter.paymentMethod.toLowerCase().replace(' ', '_'))
  if (filter?.minAmount !== undefined) query = query.gte('amount', filter.minAmount)
  if (filter?.maxAmount !== undefined) query = query.lte('amount', filter.maxAmount)
  if (filter?.search) {
    query = query.or(`description.ilike.%${filter.search}%,category.ilike.%${filter.search}%,note.ilike.%${filter.search}%`)
  }

  const { data, error } = await query
  if (error) {
    console.error('getExpenses error:', error)
    return []
  }
  
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
  const user = await getCurrentUser()
  if (!user) return {
    todayTotal: 0, monthTotal: 0, prevMonthTotal: 0, avgDaily: 0, 
    highestCategory: { name: 'N/A', amount: 0 }, dailyData: [], 
    highestDay: { date: 'N/A', amount: 0 }, categoryBreakdown: [], 
    todayExpenses: [], monthExpenses: [], daysElapsed: 1, monthComparisonPct: null
  }
  const supabase = await createClient()

  const now = new Date()
  const todayStr = format(now, 'yyyy-MM-dd')
  const monthStartStr = format(startOfMonth(now), 'yyyy-MM-dd')
  const monthEndStr = format(endOfMonth(now), 'yyyy-MM-dd')
  const prevMonthStartStr = format(startOfMonth(subMonths(now, 1)), 'yyyy-MM-dd')
  const prevMonthEndStr = format(endOfMonth(subMonths(now, 1)), 'yyyy-MM-dd')

  const [
    { data: todayExpenses, error: e1 }, 
    { data: monthExpensesAsc, error: e2 }, 
    { data: prevMonthExpenses, error: e3 }, 
    { data: allMonthExpenses, error: e4 }
  ] = await Promise.all([
    supabase.from('expenses').select('*').eq('user_id', user.id).eq('expense_date', todayStr),
    supabase.from('expenses').select('*').eq('user_id', user.id).gte('expense_date', monthStartStr).lte('expense_date', monthEndStr).order('expense_date', { ascending: true }),
    supabase.from('expenses').select('*').eq('user_id', user.id).gte('expense_date', prevMonthStartStr).lte('expense_date', prevMonthEndStr),
    supabase.from('expenses').select('*').eq('user_id', user.id).gte('expense_date', monthStartStr).lte('expense_date', monthEndStr)
  ])

  if (e1 || e2 || e3 || e4) {
    console.error('getMoneySummary errors:', { e1, e2, e3, e4 })
  }

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
  const user = await getCurrentUser()
  if (!user) return []
  const supabase = await createClient()

  const monthKey = month || format(new Date(), 'yyyy-MM')
  const dateKey = `${monthKey}-01`

  const { data } = await supabase.from('budgets').select('*').eq('user_id', user.id).eq('month', dateKey)
  
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
