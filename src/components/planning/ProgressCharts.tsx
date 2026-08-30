'use client'

import { Bar, BarChart, ResponsiveContainer, XAxis, YAxis, Tooltip, CartesianGrid } from "recharts"

export function ProgressCharts({ data }: { data: any[] }) {
  if (!data || data.length === 0) return null

  return (
    <ResponsiveContainer width="100%" height={350}>
      <BarChart data={data} margin={{ top: 20, right: 0, left: -20, bottom: 0 }}>
        <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="rgba(255,255,255,0.1)" />
        <XAxis 
          dataKey="name" 
          fontSize={12} 
          tickLine={false} 
          axisLine={false}
          tick={{ fill: 'var(--muted-foreground)' }}
          dy={10}
        />
        <YAxis 
          fontSize={12} 
          tickLine={false} 
          axisLine={false} 
          tick={{ fill: 'var(--muted-foreground)' }}
          tickFormatter={(value) => `${value}h`}
        />
        <Tooltip 
          cursor={{ fill: 'rgba(255,255,255,0.05)' }} 
          contentStyle={{ borderRadius: '8px', border: '1px solid var(--border)', backgroundColor: 'var(--background)' }}
          formatter={(value: any) => [`${value} hours`, 'Invested Time']}
          labelStyle={{ color: 'var(--foreground)', fontWeight: 600, marginBottom: '4px' }}
        />
        <Bar dataKey="hours" fill="hsl(var(--primary))" radius={[4, 4, 0, 0]} maxBarSize={60} />
      </BarChart>
    </ResponsiveContainer>
  )
}
