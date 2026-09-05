'use client'

import React from 'react'
import { BarChart3, PieChart, Sparkles, Receipt, Target, TrendingUp, Lightbulb, Wallet } from 'lucide-react'
import { cn } from '@/lib/utils'

const ICON_MAP = {
  BarChart3,
  PieChart,
  Sparkles,
  Receipt,
  Target,
  TrendingUp,
  Lightbulb,
  Wallet,
} as const

export type EmptyStateIconName = keyof typeof ICON_MAP

interface MoneyEmptyStateProps {
  iconName: EmptyStateIconName
  title: string
  description: string
  action?: React.ReactNode
  accentColor?: 'green' | 'blue' | 'amber' | 'emerald'
  className?: string
  minHeight?: string
  showGrid?: boolean
}

export function MoneyEmptyState({
  iconName,
  title,
  description,
  action,
  accentColor = 'green',
  className,
  minHeight = 'min-h-[220px]',
  showGrid = true,
}: MoneyEmptyStateProps) {
  const Icon = ICON_MAP[iconName] ?? BarChart3
  const glowColors = {
    green: 'bg-[#00E5A0]/10 border-[#00E5A0]/25 text-[#00E5A0]',
    blue: 'bg-[#3B82F6]/10 border-[#3B82F6]/25 text-[#3B82F6]',
    amber: 'bg-[#FFB020]/10 border-[#FFB020]/25 text-[#FFB020]',
    emerald: 'bg-[#10B981]/10 border-[#10B981]/25 text-[#10B981]',
  }

  return (
    <div
      className={cn(
        'relative w-full flex flex-col items-center justify-center text-center p-6 rounded-xl overflow-hidden select-none animate-in fade-in zoom-in-95 duration-300',
        minHeight,
        className
      )}
    >
      {/* Subtle Ghosted Grid Overlay (5-8% opacity) */}
      {showGrid && (
        <div className="absolute inset-0 pointer-events-none opacity-[0.06] bg-[radial-gradient(#EAF2F5_1px,transparent_1px)] [background-size:16px_16px]" />
      )}

      {/* Faint Chart Axis Outline */}
      {showGrid && (
        <div className="absolute inset-[10%] pointer-events-none opacity-[0.04] border-b border-l border-[#EAF2F5]" />
      )}

      {/* Subtle Circular Icon Container */}
      <div className="relative z-10 mb-3.5">
        <div
          className={cn(
            'w-12 h-12 rounded-full flex items-center justify-center border shadow-lg backdrop-blur-md transition-transform duration-300 hover:scale-105',
            glowColors[accentColor]
          )}
        >
          <Icon className="w-5 h-5 stroke-[1.75]" />
        </div>
      </div>

      {/* Content */}
      <div className="relative z-10 max-w-sm space-y-1.5 px-2">
        <h4 className="text-sm font-semibold tracking-tight text-[#EAF2F5]">
          {title}
        </h4>
        <p className="text-xs text-[#7E93A8] leading-relaxed max-w-[280px] mx-auto">
          {description}
        </p>
      </div>

      {/* Optional CTA */}
      {action && <div className="relative z-10 mt-4">{action}</div>}
    </div>
  )
}
