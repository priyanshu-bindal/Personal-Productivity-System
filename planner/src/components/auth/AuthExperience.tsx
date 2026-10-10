'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'
import {
  Sparkles,
  Calendar,
  TrendingUp,
  IndianRupee,
  Flame,
  CheckCircle2,
  Lock,
  Mail,
  User,
  ArrowRight,
  AlertCircle,
  Loader2,
  Check,
  Activity,
  ShieldCheck,
  Zap,
} from 'lucide-react'
import TextType from '@/components/ui/TextType'
import { login, signup, resetPassword } from '@/app/auth/actions'

interface AuthExperienceProps {
  initialMode?: 'signin' | 'signup'
  initialError?: string | null
}

interface FieldErrors {
  fullName?: string
  email?: string
  password?: string
}

export function AuthExperience({
  initialMode = 'signin',
  initialError = null,
}: AuthExperienceProps) {
  const [mode, setMode] = useState<'signin' | 'signup'>(initialMode)
  const [showForgotModal, setShowForgotModal] = useState(false)
  const [forgotEmail, setForgotEmail] = useState('')
  const [forgotLoading, setForgotLoading] = useState(false)
  const [forgotSuccess, setForgotSuccess] = useState(false)
  const [forgotError, setForgotError] = useState<string | null>(null)

  // Form states
  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [fieldErrors, setFieldErrors] = useState<FieldErrors>({})
  const [formError, setFormError] = useState<string | null>(initialError)
  const [isLoading, setIsLoading] = useState(false)

  // Switch mode without page reload, keeping URL in sync
  const switchMode = (newMode: 'signin' | 'signup') => {
    if (newMode === mode) return
    setMode(newMode)
    setFormError(null)
    setFieldErrors({})
    if (newMode === 'signin') {
      window.history.replaceState(null, '', '/auth/signin')
    } else {
      window.history.replaceState(null, '', '/auth/signup')
    }
  }

  const validateEmail = (val: string) => {
    if (!val.trim()) return 'Please enter your email address.'
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(val.trim())) return 'Please enter a valid email address.'
    return undefined
  }

  const validatePassword = (val: string, isSignUp: boolean) => {
    if (!val) return 'Please enter your password.'
    if (isSignUp && val.length < 6) return 'Password must be at least 6 characters.'
    return undefined
  }

  const validateFullName = (val: string) => {
    if (!val.trim()) return 'Please enter your name.'
    return undefined
  }

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    if (isLoading) return

    setFormError(null)
    const errors: FieldErrors = {}
    const isSignUp = mode === 'signup'

    if (isSignUp) {
      const nameErr = validateFullName(fullName)
      if (nameErr) errors.fullName = nameErr
    }

    const emailErr = validateEmail(email)
    const passErr = validatePassword(password, isSignUp)

    if (emailErr) errors.email = emailErr
    if (passErr) errors.password = passErr

    if (Object.keys(errors).length > 0) {
      setFieldErrors(errors)
      return
    }

    setFieldErrors({})
    setIsLoading(true)

    try {
      const formData = new FormData()
      formData.append('email', email.trim())
      formData.append('password', password)
      if (isSignUp) {
        formData.append('full_name', fullName.trim())
      }

      if (isSignUp) {
        const result = await signup(formData)
        if (result?.error) {
          setFormError(result.error)
          if (
            result.error.toLowerCase().includes('already exists') ||
            result.error.toLowerCase().includes('sign in')
          ) {
            setFieldErrors(prev => ({ ...prev, email: result.error }))
          }
          setIsLoading(false)
        } else if (result?.success) {
          window.location.href = '/'
        }
      } else {
        const result = await login(formData)
        if (result?.error) {
          setFormError(result.error)
          setIsLoading(false)
        } else if (result?.success) {
          window.location.href = '/'
        }
      }
    } catch (err: any) {
      if (err?.message !== 'NEXT_REDIRECT') {
        setFormError(
          mode === 'signup'
            ? 'Unable to create account. Please check your details and try again.'
            : 'Incorrect email or password. Please try again.'
        )
        setIsLoading(false)
      }
    }
  }

  const handleForgotPasswordSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setForgotError(null)
    const err = validateEmail(forgotEmail)
    if (err) {
      setForgotError(err)
      return
    }

    setForgotLoading(true)
    try {
      const formData = new FormData()
      formData.append('email', forgotEmail.trim())
      const res = await resetPassword(formData)
      if (res?.error) {
        setForgotError(res.error)
      } else {
        setForgotSuccess(true)
      }
    } catch {
      setForgotError('Failed to send reset link. Please try again.')
    } finally {
      setForgotLoading(false)
    }
  }

  return (
    <div className="relative min-h-[100dvh] w-full bg-[#05070D] text-[#F1F5F9] flex flex-col justify-between overflow-x-hidden selection:bg-[#3978FF]/30 selection:text-cyan-200 antialiased">
      {/* ── 1. CINEMATIC DARK BACKGROUND & RESTRAINED AMBIENT LIGHTING ── */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden z-0">
        {/* Subtle geometric dot grid pattern */}
        <div
          className="absolute inset-0 opacity-[0.14]"
          style={{
            backgroundImage: `radial-gradient(rgba(56, 189, 248, 0.25) 1px, transparent 1px)`,
            backgroundSize: '36px 36px',
            maskImage: 'radial-gradient(ellipse at 50% 50%, black 40%, transparent 90%)',
            WebkitMaskImage: 'radial-gradient(ellipse at 50% 50%, black 40%, transparent 90%)',
          }}
        />

        {/* Top-Left Ambient Cyan/Blue Light */}
        <div
          className="absolute -top-[15%] -left-[10%] w-[580px] h-[580px] rounded-full blur-[140px] opacity-20"
          style={{
            background: 'radial-gradient(circle, #0284c7 0%, #0369a1 40%, transparent 70%)',
            animation: 'ambient-drift 24s ease-in-out infinite alternate',
          }}
        />

        {/* Center-Right Subtle Indigo Atmosphere */}
        <div
          className="absolute top-[25%] -right-[15%] w-[620px] h-[620px] rounded-full blur-[160px] opacity-15"
          style={{
            background: 'radial-gradient(circle, #38bdf8 0%, #4338ca 45%, transparent 70%)',
            animation: 'ambient-drift 30s ease-in-out infinite alternate-reverse',
          }}
        />

        {/* Subtle Vignette Overlay */}
        <div className="absolute inset-0 bg-radial-[circle_at_center,transparent_45%,#05070D_95%]" />
      </div>

      {/* ── 2. TOP BRAND HEADER ── */}
      <header className="relative z-10 w-full max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-4 pb-1 sm:pt-6 sm:pb-2 flex items-center justify-between shrink-0">
        <Link
          href="/"
          className="group flex items-center gap-3 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#3978FF] rounded-xl p-1 transition-transform active:scale-[0.98]"
        >
          {/* Refined FocusFlow Logo Badge */}
          <div className="relative flex items-center justify-center w-10 h-10 sm:w-11 sm:h-11 rounded-2xl bg-gradient-to-br from-cyan-500/15 via-[#3978FF]/20 to-indigo-700/30 border border-[#3978FF]/30 shadow-[0_2px_12px_rgba(57,120,255,0.2)] group-hover:border-[#3978FF]/60 transition-all duration-300">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 32 32"
              className="w-5 h-5 sm:w-6 sm:h-6 text-cyan-400"
              fill="none"
            >
              <path
                d="M10 8L4 16l6 8M22 8l6 8-6 8M19 6l-6 20"
                stroke="currentColor"
                strokeWidth="2.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </div>
          <div>
            <span className="text-xl sm:text-2xl font-black tracking-tight text-white flex items-center gap-1">
              Focus<span className="text-transparent bg-clip-text bg-gradient-to-r from-cyan-400 via-sky-300 to-[#3978FF]">Flow</span>
            </span>
            <span className="hidden sm:block text-[10px] tracking-widest uppercase font-semibold text-cyan-400/80 -mt-1">
              Consistency Platform
            </span>
          </div>
        </Link>

        {/* Status indicator */}
        <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-full bg-white/[0.03] border border-white/[0.08] backdrop-blur-md text-xs text-[#94A3B8]">
          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
          <span>All systems online</span>
        </div>
      </header>

      {/* ── 3. MAIN HERO + AUTH CARD SECTION ── */}
      <main className="relative z-10 w-full max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-1 pb-4 sm:pt-2 sm:pb-6 flex-1 flex flex-col justify-center">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-10 xl:gap-14 items-start">
          
          {/* ══════════════════════════════════════════════════════════════════
              LEFT SIDE: DYNAMIC PRODUCT SHOWCASE & LIVING DASHBOARD
          ══════════════════════════════════════════════════════════════════ */}
          <div className="lg:col-span-7 flex flex-col justify-center space-y-6 lg:space-y-7 lg:pr-2">
            {/* Headline and Copy */}
            <div className="space-y-3 sm:space-y-4">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-gradient-to-r from-cyan-500/10 via-[#3978FF]/10 to-indigo-500/10 border border-cyan-500/25 text-cyan-300 text-xs font-semibold tracking-wide">
                <Sparkles className="w-3.5 h-3.5 text-cyan-400" />
                <span>Consistency Over Intensity</span>
              </div>

              <h1 className="text-3xl sm:text-4xl lg:text-5xl xl:text-6xl font-extrabold tracking-tight text-white leading-[1.12] min-h-[2.24em] select-none">
                Your Next Level <br />
                <span className="text-transparent bg-clip-text bg-gradient-to-r from-cyan-400 via-sky-300 to-[#3978FF]">
                  <TextType
                    text={['Starts Today.']}
                    typingSpeed={75}
                    pauseDuration={1500}
                    showCursor
                    cursorCharacter="_"
                    cursorBlinkDuration={0.5}
                    deletingSpeed={50}
                    variableSpeedEnabled={false}
                    variableSpeedMin={60}
                    variableSpeedMax={120}
                    cursorClassName="text-cyan-400 font-bold"
                  />
                </span>
              </h1>

              <p className="text-sm sm:text-base lg:text-lg text-[#94A3B8] max-w-xl font-normal leading-relaxed">
                Build consistency. Master new skills. Take control of your day with the private platform designed for continuous progress.
              </p>
            </div>

            {/* Living Productivity Visualization (Illustrative Dashboard) */}
            <div className="relative group">
              {/* Main Clean Showcase Card */}
              <div className="relative rounded-2xl sm:rounded-3xl bg-[#091122]/90 border border-[rgba(71,115,170,0.3)] p-4 sm:p-5 lg:p-6 shadow-[0_16px_40px_rgba(0,0,0,0.5)] space-y-4 sm:space-y-5 overflow-hidden">
                {/* Dashboard Header Bar */}
                <div className="flex items-center justify-between pb-3 sm:pb-4 border-b border-white/[0.06]">
                  <div className="flex items-center gap-2.5 sm:gap-3">
                    <div className="w-8 h-8 sm:w-9 sm:h-9 rounded-xl bg-cyan-500/10 border border-cyan-400/25 flex items-center justify-center text-cyan-400">
                      <Activity className="w-4 h-4" />
                    </div>
                    <div>
                      <div className="text-xs sm:text-sm font-semibold text-white flex items-center gap-2">
                        Today&apos;s Focus Sprint
                        <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-cyan-500/15 text-cyan-300 border border-cyan-500/25">
                          Live
                        </span>
                      </div>
                      <p className="text-[10px] sm:text-[11px] text-[#94A3B8] font-mono">
                        Illustrative preview • 3 of 4 objectives completed
                      </p>
                    </div>
                  </div>

                  {/* Streak Indicator with Warm Flame Accent */}
                  <div className="flex items-center gap-1.5 px-2.5 sm:px-3 py-1 sm:py-1.5 rounded-xl bg-amber-500/10 border border-amber-500/25 text-amber-300 text-[11px] sm:text-xs font-bold">
                    <Flame className="w-3.5 h-3.5 sm:w-4 sm:h-4 text-amber-400" />
                    <span>14 Day Streak</span>
                  </div>
                </div>

                {/* Active Skill Progress Bars */}
                <div className="space-y-3">
                  {/* Skill 1: Full-Stack Systems */}
                  <div className="space-y-1.5">
                    <div className="flex justify-between items-center text-xs">
                      <span className="text-[#F1F5F9] font-medium flex items-center gap-1.5">
                        <span className="w-2 h-2 rounded-full bg-cyan-400" />
                        Next.js Architecture & Systems
                      </span>
                      <span className="text-cyan-300 font-mono font-semibold">82%</span>
                    </div>
                    <div className="h-2 w-full rounded-full bg-white/[0.06] overflow-hidden p-0.5">
                      <div
                        className="h-full rounded-full bg-gradient-to-r from-cyan-500 to-[#3978FF]"
                        style={{ width: '82%' }}
                      />
                    </div>
                  </div>

                  {/* Skill 2: UI Motion */}
                  <div className="space-y-1.5">
                    <div className="flex justify-between items-center text-xs">
                      <span className="text-[#F1F5F9] font-medium flex items-center gap-1.5">
                        <span className="w-2 h-2 rounded-full bg-indigo-400" />
                        Fluid Motion & Micro-Interactions
                      </span>
                      <span className="text-indigo-300 font-mono font-semibold">68%</span>
                    </div>
                    <div className="h-2 w-full rounded-full bg-white/[0.06] overflow-hidden p-0.5">
                      <div
                        className="h-full rounded-full bg-gradient-to-r from-indigo-500 to-[#3978FF]"
                        style={{ width: '68%' }}
                      />
                    </div>
                  </div>
                </div>

                {/* Interactive Weekly Progress Micro-Chart & Stats Grid */}
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5 pt-1">
                  {/* Metric 1 */}
                  <div className="p-2.5 sm:p-3 rounded-xl bg-white/[0.025] border border-white/[0.06] flex flex-col justify-between">
                    <span className="text-[10px] sm:text-[11px] text-[#94A3B8]">Total Focus</span>
                    <div className="text-base sm:text-lg font-bold text-white font-mono mt-0.5">42.5 hrs</div>
                    <span className="text-[10px] text-emerald-400 font-medium">+14% this week</span>
                  </div>

                  {/* Metric 2 */}
                  <div className="p-2.5 sm:p-3 rounded-xl bg-white/[0.025] border border-white/[0.06] flex flex-col justify-between">
                    <span className="text-[10px] sm:text-[11px] text-[#94A3B8]">Completed</span>
                    <div className="text-base sm:text-lg font-bold text-white font-mono mt-0.5">28 Tasks</div>
                    <span className="text-[10px] text-cyan-400 font-medium">93% on time</span>
                  </div>

                  {/* Metric 3: Weekly Activity Bar Sparkline */}
                  <div className="col-span-2 p-2.5 sm:p-3 rounded-xl bg-white/[0.025] border border-white/[0.06] flex flex-col justify-between">
                    <div className="flex items-center justify-between text-[10px] sm:text-[11px] text-[#94A3B8] mb-1.5">
                      <span>Weekly Momentum</span>
                      <span className="text-cyan-400 font-mono text-[10px]">M T W T F S S</span>
                    </div>
                    {/* 7-day sparkline bars */}
                    <div className="flex items-end justify-between gap-1.5 h-7 sm:h-8">
                      {[40, 65, 80, 50, 95, 75, 90].map((height, idx) => (
                        <div
                          key={idx}
                          className="flex-1 bg-white/[0.06] rounded-t-sm flex flex-col justify-end"
                          style={{ height: '100%' }}
                        >
                          <div
                            className={`w-full rounded-t-sm ${
                              idx === 6
                                ? 'bg-gradient-to-t from-cyan-500 to-sky-300'
                                : 'bg-gradient-to-t from-[#3978FF]/70 to-cyan-500/80'
                            }`}
                            style={{ height: `${height}%` }}
                          />
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>

              {/* Floating Glass Accent Pill 1 - Top Right */}
              <div
                className="hidden sm:flex absolute -top-3 -right-2 items-center gap-2 px-3 py-1.5 rounded-xl bg-[#091122]/95 border border-[rgba(71,115,170,0.35)] shadow-[0_8px_20px_rgba(0,0,0,0.5)] text-xs text-[#F1F5F9] z-20"
                style={{ animation: 'float-slow 6s ease-in-out infinite' }}
              >
                <div className="w-5 h-5 rounded-lg bg-emerald-500/20 border border-emerald-400/40 flex items-center justify-center text-emerald-400">
                  <CheckCircle2 className="w-3 h-3" />
                </div>
                <div>
                  <div className="font-semibold text-white leading-tight">Daily Target Met</div>
                  <div className="text-[10px] text-[#94A3B8]">120 min deep work</div>
                </div>
              </div>

              {/* Floating Glass Accent Pill 2 - Bottom Left */}
              <div
                className="hidden sm:flex absolute -bottom-3 -left-2 items-center gap-2 px-3 py-1.5 rounded-xl bg-[#091122]/95 border border-[rgba(71,115,170,0.35)] shadow-[0_8px_20px_rgba(0,0,0,0.5)] text-xs text-[#F1F5F9] z-20"
                style={{ animation: 'float-slow 7s ease-in-out infinite reverse' }}
              >
                <div className="w-5 h-5 rounded-lg bg-[#3978FF]/20 border border-[#3978FF]/40 flex items-center justify-center text-cyan-300">
                  <Zap className="w-3 h-3" />
                </div>
                <div>
                  <div className="font-semibold text-white leading-tight">Focus Flow Activated</div>
                  <div className="text-[10px] text-cyan-300">Clean cognitive state</div>
                </div>
              </div>
            </div>

            {/* Three Compact Feature Highlights */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-0.5">
              {/* Highlight 1: Smart Planner */}
              <div className="p-3 rounded-xl bg-white/[0.02] border border-white/[0.06] hover:border-cyan-500/25 transition-colors">
                <div className="w-7 h-7 rounded-lg bg-cyan-500/10 border border-cyan-500/20 flex items-center justify-center text-cyan-400 mb-2">
                  <Calendar className="w-3.5 h-3.5" />
                </div>
                <h2 className="text-xs sm:text-sm font-semibold text-white">Smart Planner</h2>
                <p className="text-[11px] text-[#94A3B8] mt-0.5 leading-relaxed">
                  Daily focus queue designed for priority execution.
                </p>
              </div>

              {/* Highlight 2: Skill Progress */}
              <div className="p-3 rounded-xl bg-white/[0.02] border border-white/[0.06] hover:border-[#3978FF]/25 transition-colors">
                <div className="w-7 h-7 rounded-lg bg-[#3978FF]/10 border border-[#3978FF]/20 flex items-center justify-center text-[#3978FF] mb-2">
                  <TrendingUp className="w-3.5 h-3.5" />
                </div>
                <h2 className="text-xs sm:text-sm font-semibold text-white">Skill Progress</h2>
                <p className="text-[11px] text-[#94A3B8] mt-0.5 leading-relaxed">
                  Visual mastery logs and retention timelines.
                </p>
              </div>

              {/* Highlight 3: Money Tracker */}
              <div className="p-3 rounded-xl bg-white/[0.02] border border-white/[0.06] hover:border-indigo-500/25 transition-colors">
                <div className="w-7 h-7 rounded-lg bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-indigo-400 mb-2">
                  <IndianRupee className="w-3.5 h-3.5" />
                </div>
                <h2 className="text-xs sm:text-sm font-semibold text-white">Money Tracker</h2>
                <p className="text-[11px] text-[#94A3B8] mt-0.5 leading-relaxed">
                  Financial discipline seamlessly linked with time.
                </p>
              </div>
            </div>
          </div>

          {/* ══════════════════════════════════════════════════════════════════
              RIGHT SIDE: REFINED SOLID DEEP NAVY AUTHENTICATION CARD
              - Positioned high and vertically centered with hero section
              - Solid deep navy #0B1426 with subtle border rgba(71, 115, 170, 0.35)
              - No excessive outer glow or animated luminous shadow
              - Smooth, polished mode transition (300ms ease-out)
          ══════════════════════════════════════════════════════════════════ */}
          <div className="lg:col-span-5 w-full max-w-md mx-auto lg:max-w-none">
            {/* The Authentic Premium Card */}
            <div className="relative rounded-2xl sm:rounded-3xl bg-[#0B1426] border border-[rgba(71,115,170,0.35)] p-6 sm:p-7 shadow-[0_16px_36px_rgba(0,0,0,0.55)] transition-all duration-300 auth-card-entrance">
              
              {/* Segmented Mode Switcher Tabs */}
              <div className="relative p-1 rounded-xl bg-[#070D19] border border-[rgba(71,115,170,0.2)] mb-6 flex">
                {/* Smooth Animated Tab Pill Indicator */}
                <div
                  className="absolute top-1 bottom-1 rounded-lg bg-[#3978FF] shadow-[0_2px_8px_rgba(57,120,255,0.3)] transition-all duration-300 ease-out"
                  style={{
                    left: mode === 'signin' ? '4px' : 'calc(50% + 2px)',
                    width: 'calc(50% - 6px)',
                  }}
                />

                <button
                  type="button"
                  onClick={() => switchMode('signin')}
                  className={`relative z-10 flex-1 py-2 text-xs sm:text-sm font-semibold rounded-lg transition-colors duration-200 ${
                    mode === 'signin' ? 'text-white' : 'text-[#94A3B8] hover:text-[#F1F5F9]'
                  }`}
                >
                  Sign In
                </button>
                <button
                  type="button"
                  onClick={() => switchMode('signup')}
                  className={`relative z-10 flex-1 py-2 text-xs sm:text-sm font-semibold rounded-lg transition-colors duration-200 ${
                    mode === 'signup' ? 'text-white' : 'text-[#94A3B8] hover:text-[#F1F5F9]'
                  }`}
                >
                  Create Account
                </button>
              </div>

              {/* Mode-Specific Content with Smooth Transition */}
              <div key={mode} className="auth-form-transition">
                {/* Card Title & Subtitle */}
                <div className="mb-5 space-y-1">
                  <h2 className="text-xl sm:text-2xl font-bold tracking-tight text-[#F1F5F9]">
                    {mode === 'signin' ? 'Welcome back' : 'Start your journey'}
                  </h2>
                  <p className="text-xs sm:text-sm text-[#94A3B8]">
                    {mode === 'signin'
                      ? 'Enter your credentials to access your dashboard'
                      : 'Create your private account in under 30 seconds'}
                  </p>
                </div>

                {/* Main Auth Form */}
                <form onSubmit={handleSubmit} noValidate className="space-y-4">
                  {/* Full Name Field (Sign Up Only) */}
                  {mode === 'signup' && (
                    <div className="space-y-1.5">
                      <label htmlFor="full_name" className="text-xs font-medium text-[#F1F5F9] flex items-center justify-between">
                        <span>Full Name</span>
                      </label>
                      <div className="relative">
                        <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#94A3B8]">
                          <User className="w-4 h-4" />
                        </div>
                        <input
                          id="full_name"
                          name="full_name"
                          type="text"
                          value={fullName}
                          onChange={e => {
                            setFullName(e.target.value)
                            if (fieldErrors.fullName) {
                              setFieldErrors(prev => ({ ...prev, fullName: undefined }))
                            }
                          }}
                          placeholder="Your Name"
                          disabled={isLoading}
                          className={`w-full h-11 pl-10 pr-4 rounded-xl bg-[#070D19] border text-sm text-[#F1F5F9] placeholder-slate-500 focus:outline-none transition-colors duration-200 ${
                            fieldErrors.fullName
                              ? 'border-red-500/80 focus:border-red-500 focus:ring-1 focus:ring-red-500'
                              : 'border-[rgba(71,115,170,0.25)] focus:border-[#3978FF] focus:ring-1 focus:ring-[#3978FF] hover:border-[rgba(71,115,170,0.4)]'
                          }`}
                        />
                      </div>
                      {fieldErrors.fullName && (
                        <p className="text-xs text-red-400 font-medium flex items-center gap-1.5 mt-1">
                          <AlertCircle className="w-3.5 h-3.5 shrink-0" />
                          <span>{fieldErrors.fullName}</span>
                        </p>
                      )}
                    </div>
                  )}

                  {/* Email Field */}
                  <div className="space-y-1.5">
                    <label htmlFor="email" className="text-xs font-medium text-[#F1F5F9] flex items-center justify-between">
                      <span>Email address</span>
                    </label>
                    <div className="relative">
                      <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#94A3B8]">
                        <Mail className="w-4 h-4" />
                      </div>
                      <input
                        id="email"
                        name="email"
                        type="email"
                        value={email}
                        onChange={e => {
                          setEmail(e.target.value)
                          if (fieldErrors.email) {
                            setFieldErrors(prev => ({ ...prev, email: undefined }))
                          }
                        }}
                        placeholder="you@example.com"
                        disabled={isLoading}
                        autoComplete="email"
                        className={`w-full h-11 pl-10 pr-4 rounded-xl bg-[#070D19] border text-sm text-[#F1F5F9] placeholder-slate-500 focus:outline-none transition-colors duration-200 ${
                          fieldErrors.email
                            ? 'border-red-500/80 focus:border-red-500 focus:ring-1 focus:ring-red-500'
                            : 'border-[rgba(71,115,170,0.25)] focus:border-[#3978FF] focus:ring-1 focus:ring-[#3978FF] hover:border-[rgba(71,115,170,0.4)]'
                        }`}
                      />
                    </div>
                    {fieldErrors.email && (
                      <p className="text-xs text-red-400 font-medium flex items-center gap-1.5 mt-1">
                        <AlertCircle className="w-3.5 h-3.5 shrink-0" />
                        <span>{fieldErrors.email}</span>
                      </p>
                    )}
                  </div>

                  {/* Password Field */}
                  <div className="space-y-1.5">
                    <div className="flex items-center justify-between">
                      <label htmlFor="password" className="text-xs font-medium text-[#F1F5F9]">Password</label>
                      {mode === 'signin' && (
                        <button
                          type="button"
                          onClick={() => {
                            setForgotEmail(email)
                            setShowForgotModal(true)
                            setForgotSuccess(false)
                            setForgotError(null)
                          }}
                          className="text-xs text-[#22C7E8] hover:text-cyan-300 transition-colors focus:outline-none"
                        >
                          Forgot password?
                        </button>
                      )}
                    </div>
                    <div className="relative">
                      <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#94A3B8]">
                        <Lock className="w-4 h-4" />
                      </div>
                      <input
                        id="password"
                        name="password"
                        type="password"
                        value={password}
                        onChange={e => {
                          setPassword(e.target.value)
                          if (fieldErrors.password) {
                            setFieldErrors(prev => ({ ...prev, password: undefined }))
                          }
                        }}
                        placeholder="••••••••"
                        disabled={isLoading}
                        autoComplete={mode === 'signin' ? 'current-password' : 'new-password'}
                        className={`w-full h-11 pl-10 pr-4 rounded-xl bg-[#070D19] border text-sm text-[#F1F5F9] placeholder-slate-500 focus:outline-none transition-colors duration-200 ${
                          fieldErrors.password
                            ? 'border-red-500/80 focus:border-red-500 focus:ring-1 focus:ring-red-500'
                            : 'border-[rgba(71,115,170,0.25)] focus:border-[#3978FF] focus:ring-1 focus:ring-[#3978FF] hover:border-[rgba(71,115,170,0.4)]'
                        }`}
                      />
                    </div>
                    {fieldErrors.password && (
                      <p className="text-xs text-red-400 font-medium flex items-center gap-1.5 mt-1">
                        <AlertCircle className="w-3.5 h-3.5 shrink-0" />
                        <span>{fieldErrors.password}</span>
                      </p>
                    )}
                  </div>

                  {/* Form Error Banner */}
                  {formError && !fieldErrors.email?.includes('already exists') && (
                    <div className="p-3 rounded-xl bg-red-500/10 border border-red-500/20 text-red-400 text-xs font-medium flex items-start gap-2">
                      <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                      <span className="leading-relaxed">{formError}</span>
                    </div>
                  )}

                  {/* Primary Action Button */}
                  <button
                    type="submit"
                    disabled={isLoading}
                    className="relative w-full h-11 mt-2 rounded-xl bg-[#3978FF] hover:bg-[#2F68E6] active:bg-[#2558CC] text-white font-semibold text-sm tracking-wide shadow-[0_4px_16px_rgba(57,120,255,0.25)] hover:shadow-[0_6px_20px_rgba(57,120,255,0.35)] active:scale-[0.99] disabled:opacity-60 disabled:cursor-not-allowed transition-all duration-200 flex items-center justify-center gap-2 group cursor-pointer"
                  >
                    {isLoading ? (
                      <span className="flex items-center gap-2">
                        <Loader2 className="w-4 h-4 animate-spin text-white" />
                        <span>{mode === 'signin' ? 'Authenticating...' : 'Creating Account...'}</span>
                      </span>
                    ) : (
                      <>
                        <span>{mode === 'signin' ? 'Sign In to FocusFlow' : 'Create Free Account'}</span>
                        <ArrowRight className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
                      </>
                    )}
                  </button>
                </form>

                {/* Footer Link */}
                <div className="mt-5 pt-4 border-t border-[rgba(71,115,170,0.18)] flex items-center justify-between text-xs text-[#94A3B8]">
                  <div className="flex items-center gap-1.5">
                    <ShieldCheck className="w-4 h-4 text-[#22C7E8]" />
                    <span>256-bit Encrypted</span>
                  </div>
                  <div>
                    {mode === 'signin' ? (
                      <span>
                        Need an account?{' '}
                        <button
                          type="button"
                          onClick={() => switchMode('signup')}
                          className="text-[#22C7E8] hover:text-cyan-300 font-medium hover:underline cursor-pointer"
                        >
                          Sign Up
                        </button>
                      </span>
                    ) : (
                      <span>
                        Already registered?{' '}
                        <button
                          type="button"
                          onClick={() => switchMode('signin')}
                          className="text-[#22C7E8] hover:text-cyan-300 font-medium hover:underline cursor-pointer"
                        >
                          Sign In
                        </button>
                      </span>
                    )}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>

      {/* ── 4. SUBTLE BOTTOM FOOTER ── */}
      <footer className="relative z-10 w-full max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 text-center text-xs text-[#94A3B8]/80 shrink-0">
        FocusFlow • Consistency platform for personal mastery.
      </footer>

      {/* ── 5. FORGOT PASSWORD MODAL ── */}
      {showForgotModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="relative w-full max-w-md rounded-2xl bg-[#0B1426] border border-[rgba(71,115,170,0.35)] p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold text-white flex items-center gap-2">
                <Lock className="w-4 h-4 text-[#22C7E8]" />
                Reset your password
              </h3>
              <button
                type="button"
                onClick={() => setShowForgotModal(false)}
                className="text-[#94A3B8] hover:text-white text-xs px-2 py-1 rounded-lg hover:bg-white/[0.06] cursor-pointer"
              >
                Close
              </button>
            </div>

            {forgotSuccess ? (
              <div className="p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-300 space-y-2 text-xs">
                <div className="flex items-center gap-2 font-bold text-sm">
                  <Check className="w-4 h-4 text-emerald-400" />
                  Instructions Sent!
                </div>
                <p className="leading-relaxed">
                  We&apos;ve sent a password reset link to <strong className="text-white">{forgotEmail}</strong>. Please check your inbox and spam folder.
                </p>
                <button
                  type="button"
                  onClick={() => setShowForgotModal(false)}
                  className="w-full mt-3 py-2 rounded-xl bg-emerald-500 text-black font-bold text-xs hover:bg-emerald-400 transition-colors cursor-pointer"
                >
                  Return to Sign In
                </button>
              </div>
            ) : (
              <form onSubmit={handleForgotPasswordSubmit} className="space-y-4">
                <p className="text-xs text-[#94A3B8] leading-relaxed">
                  Enter your FocusFlow account email. We&apos;ll send you a secure link to reset your password.
                </p>

                <div className="space-y-1.5">
                  <label htmlFor="forgot_email" className="text-xs font-medium text-[#F1F5F9]">Email Address</label>
                  <input
                    id="forgot_email"
                    type="email"
                    value={forgotEmail}
                    onChange={e => setForgotEmail(e.target.value)}
                    placeholder="you@example.com"
                    required
                    className="w-full h-11 px-4 rounded-xl bg-[#070D19] border border-[rgba(71,115,170,0.3)] text-sm text-[#F1F5F9] focus:outline-none focus:border-[#3978FF] focus:ring-1 focus:ring-[#3978FF]"
                  />
                </div>

                {forgotError && (
                  <div className="p-3 rounded-xl bg-red-500/10 border border-red-500/20 text-red-400 text-xs flex items-center gap-2">
                    <AlertCircle className="w-4 h-4 shrink-0" />
                    <span>{forgotError}</span>
                  </div>
                )}

                <div className="flex items-center gap-2 pt-2">
                  <button
                    type="button"
                    onClick={() => setShowForgotModal(false)}
                    className="flex-1 h-10 rounded-xl bg-white/[0.05] hover:bg-white/[0.1] text-xs font-semibold text-[#94A3B8] hover:text-white transition-colors cursor-pointer"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={forgotLoading}
                    className="flex-1 h-10 rounded-xl bg-[#3978FF] hover:bg-[#2F68E6] text-xs font-bold text-white shadow-[0_2px_10px_rgba(57,120,255,0.3)] transition-all flex items-center justify-center gap-2 cursor-pointer"
                  >
                    {forgotLoading ? (
                      <Loader2 className="w-4 h-4 animate-spin" />
                    ) : (
                      'Send Reset Link'
                    )}
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}

      {/* Scoped CSS for polished transitions and animations */}
      <style jsx global>{`
        /* Smooth card entrance on page load */
        .auth-card-entrance {
          animation: card-enter 350ms cubic-bezier(0.16, 1, 0.3, 1) forwards;
        }

        @keyframes card-enter {
          from {
            opacity: 0;
            transform: translateY(8px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }

        /* Mode switch transition */
        .auth-form-transition {
          animation: form-switch 300ms cubic-bezier(0.16, 1, 0.3, 1) forwards;
        }

        @keyframes form-switch {
          from {
            opacity: 0;
            transform: translateY(8px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }

        @keyframes ambient-drift {
          0% {
            transform: translate(0px, 0px) scale(1);
          }
          50% {
            transform: translate(25px, 15px) scale(1.03);
          }
          100% {
            transform: translate(-15px, 25px) scale(0.98);
          }
        }

        @keyframes float-slow {
          0%, 100% {
            transform: translateY(0px);
          }
          50% {
            transform: translateY(-6px);
          }
        }

        /* Typewriter blinking cursor */
        .typewriter-cursor {
          animation: cursor-blink 1.05s infinite;
        }

        @keyframes cursor-blink {
          0%, 100% {
            opacity: 1;
          }
          50% {
            opacity: 0;
          }
        }

        /* Respect reduced motion */
        @media (prefers-reduced-motion: reduce) {
          .auth-card-entrance,
          .auth-form-transition,
          .typewriter-cursor,
          div[style*="animation: float-slow"] {
            animation: none !important;
          }
        }
      `}</style>
    </div>
  )
}
