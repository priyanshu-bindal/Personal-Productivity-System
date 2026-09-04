'use client'

import { Bar, BarChart, ResponsiveContainer, XAxis, YAxis, Tooltip, PieChart, Pie, Cell } from "recharts"

const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899', '#6366f1', '#14b8a6', '#f97316', '#64748b']

export function DailySpendingChart({ data }: { data: { date: string, amount: number }[] }) {
  if (!data || data.length === 0) {
    return <div className="h-[220px] sm:h-[250px] flex items-center justify-center text-xs sm:text-sm text-muted-foreground">No data available</div>
  }

  // Format the dates for the X-axis
  const formattedData = data.map(item => {
    const d = new Date(item.date)
    return {
      ...item,
      displayDate: d.toLocaleDateString('en-US', { month: 'numeric', day: 'numeric' })
    }
  })

  return (
    <div className="w-full min-w-0 h-[220px] sm:h-[250px]">
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={formattedData} margin={{ top: 10, right: 10, left: -22, bottom: 0 }}>
          <XAxis dataKey="displayDate" fontSize={11} tickLine={false} axisLine={false} interval="preserveStartEnd" />
          <YAxis 
            fontSize={11} 
            tickLine={false} 
            axisLine={false} 
            tickFormatter={(value) => `₹${value}`}
          />
          <Tooltip 
            cursor={{ fill: 'rgba(255,255,255,0.05)' }} 
            contentStyle={{ borderRadius: '8px', border: '1px solid #333', backgroundColor: 'var(--background)', fontSize: '12px' }}
            formatter={(value: any) => [`₹${Number(value).toLocaleString('en-IN')}`, 'Amount']}
            labelStyle={{ color: 'var(--foreground)', fontWeight: 600, marginBottom: '2px' }}
          />
          <Bar dataKey="amount" fill="#3b82f6" radius={[4, 4, 0, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}

export function CategoryPieChart({ data }: { data: { category: string, amount: number, percentage: number }[] }) {
  if (!data || data.length === 0) {
    return <div className="h-[220px] sm:h-[250px] flex items-center justify-center text-xs sm:text-sm text-muted-foreground">No data available</div>
  }

  return (
    <div className="w-full min-w-0 h-[220px] sm:h-[250px]">
      <ResponsiveContainer width="100%" height="100%">
        <PieChart margin={{ top: 0, right: 0, left: 0, bottom: 0 }}>
          <Pie
            data={data}
            cx="50%"
            cy="50%"
            innerRadius={50}
            outerRadius={75}
            paddingAngle={2}
            dataKey="amount"
          >
            {data.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
            ))}
          </Pie>
          <Tooltip 
            contentStyle={{ borderRadius: '8px', border: '1px solid #333', backgroundColor: 'var(--background)', fontSize: '12px' }}
            formatter={(value: any, name: any, props: any) => [`₹${Number(value).toLocaleString('en-IN')} (${props.payload.percentage}%)`, name]}
          />
        </PieChart>
      </ResponsiveContainer>
    </div>
  )
}
