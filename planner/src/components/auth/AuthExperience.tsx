'use client'

import React, { useState, useEffect, useRef } from 'react'
import Link from 'next/link'
import {
  motion,
  AnimatePresence,
  useMotionValue,
  useSpring,
  useMotionTemplate,
  useReducedMotion,
  type Variants,
} from 'framer-motion'
import {
  LayoutDashboard,
  MessageSquare,
  BookOpen,
  Calendar,
  TrendingUp,
  StickyNote,
  IndianRupee,
  Loader2,
  Eye,
  EyeOff,
  ArrowRight,
  Download,
} from 'lucide-react'
import QRCode from 'qrcode'
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

function AndroidIcon({ className = 'w-4 h-4' }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="currentColor"
      className={className}
      aria-hidden="true"
    >
      <path d="M17.523 15.3414c-.5511 0-.9993-.4486-.9993-.9997s.4482-.9993.9993-.9993c.551 0 .9993.4482.9993.9993.0001.5511-.4483.9997-.9993.9997m-11.046 0c-.5511 0-.9993-.4486-.9993-.9997s.4482-.9993.9993-.9993c.5511 0 .9993.4482.9993.9993 0 .5511-.4482.9997-.9993.9997m11.4045-6.02l1.9973-3.4592a.416.416 0 00-.1521-.5676.416.416 0 00-.5676.1521l-2.0223 3.503C15.5898 8.4116 13.8497 8.1 12 8.1s-3.5898.3116-5.1368.8507L4.8409 5.4477a.416.416 0 00-.5676-.1521.416.416 0 00-.1521.5676l1.9973 3.4592C2.6889 11.1867.3432 14.6589 0 18.761h24c-.3432-4.1021-2.6889-7.5743-6.1185-9.4396" />
    </svg>
  )
}

const DEFAULT_QR_SVG = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 31 31" shape-rendering="crispEdges"><path fill="#ffffff" d="M0 0h31v31H0z"/><path stroke="#000000" d="M1 1.5h7m2 0h3m3 0h2m1 0h3m1 0h7M1 2.5h1m5 0h1m2 0h3m5 0h1m2 0h1m1 0h1m5 0h1M1 3.5h1m1 0h3m1 0h1m1 0h3m1 0h1m1 0h1m1 0h1m1 0h3m1 0h1m1 0h3m1 0h1M1 4.5h1m1 0h3m1 0h1m1 0h2m1 0h2m4 0h1m1 0h1m2 0h1m1 0h3m1 0h1M1 5.5h1m1 0h3m1 0h1m1 0h8m1 0h3m2 0h1m1 0h3m1 0h1M1 6.5h1m5 0h1m1 0h1m1 0h1m1 0h6m4 0h1m5 0h1M1 7.5h7m1 0h1m1 0h1m1 0h1m1 0h1m1 0h1m1 0h1m1 0h1m1 0h7M9 8.5h1m1 0h4M1 9.5h1m1 0h5m2 0h1m1 0h2m1 0h1m2 0h1m2 0h1m1 0h5M4 10.5h1m1 0h1m3 0h4m3 0h1m1 0h3m1 0h3m3 0h1M3 11.5h1m2 0h3m2 0h2m3 0h1m1 0h2m2 0h1m1 0h2M2 12.5h3m1 0h1m2 0h3m1 0h1m1 0h2m6 0h4m1 0h1M2 13.5h1m1 0h1m2 0h2m1 0h1m1 0h2m2 0h3m2 0h1m2 0h1m1 0h2M6 14.5h1m2 0h2m2 0h3m1 0h1m2 0h6m3 0h1M3 15.5h1m3 0h2m1 0h1m1 0h6m3 0h1m2 0h1m1 0h2M3 16.5h4m2 0h3m1 0h2m1 0h1m5 0h2m1 0h1m2 0h1M1 17.5h1m1 0h1m1 0h1m1 0h2m1 0h2m1 0h1m1 0h2m1 0h1m7 0h2M1 18.5h1m1 0h1m1 0h1m5 0h2m4 0h1m2 0h6m1 0h1m1 0h1M1 19.5h1m1 0h2m1 0h3m4 0h1m2 0h1m1 0h2m3 0h2m2 0h1M1 20.5h1m1 0h1m2 0h1m1 0h3m2 0h1m1 0h1m1 0h1m2 0h3m1 0h1m3 0h1M1 21.5h1m1 0h5m1 0h1m1 0h1m6 0h1m1 0h6m1 0h3M9 22.5h1m1 0h1m2 0h2m3 0h1m1 0h1m3 0h5M1 23.5h7m3 0h1m1 0h6m1 0h2m1 0h1m1 0h3M1 24.5h1m5 0h1m1 0h1m2 0h3m2 0h1m1 0h1m1 0h1m3 0h1m3 0h1M1 25.5h1m1 0h3m1 0h1m1 0h5m1 0h4m2 0h5m1 0h2M1 26.5h1m1 0h3m1 0h1m1 0h1m1 0h1m1 0h2m2 0h5m4 0h4M1 27.5h1m1 0h3m1 0h1m1 0h4m2 0h3m2 0h1m1 0h7M1 28.5h1m5 0h1m3 0h3m1 0h1m1 0h1m1 0h3m1 0h1m2 0h1m1 0h1M1 29.5h7m1 0h7m2 0h1m1 0h1m2 0h3m1 0h1"/></svg>`

const features = [
  { label: 'Today', icon: LayoutDashboard, desc: 'Your focus queue for the day' },
  { label: 'Messages', icon: MessageSquare, desc: 'Direct updates and chat feed' },
  { label: 'My Skills', icon: BookOpen, desc: 'Active practice & habit mastery' },
  { label: 'Calendar', icon: Calendar, desc: 'Schedule and routine planner' },
  { label: 'Progress', icon: TrendingUp, desc: 'Visual analytics and streak stats' },
  { label: 'Notes', icon: StickyNote, desc: 'Quick capture for thoughts & docs' },
  { label: 'Money', icon: IndianRupee, desc: 'Track spending and savings' },
]

const headlineWords = ['Plan,', 'learn,', 'and', 'track', 'your', 'day.']

const EASE_OUT: [number, number, number, number] = [0.22, 1, 0.36, 1]

export function AuthExperience({
  initialMode = 'signin',
  initialError = null,
}: AuthExperienceProps) {
  const shouldReduceMotion = useReducedMotion()
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
  const [showPassword, setShowPassword] = useState(false)
  const [fieldErrors, setFieldErrors] = useState<FieldErrors>({})
  const [formError, setFormError] = useState<string | null>(initialError)
  const [isLoading, setIsLoading] = useState(false)
  const [isSuccess, setIsSuccess] = useState(false)
  const [shake, setShake] = useState(false)

  // Interactivity states
  const [isTouchDevice, setIsTouchDevice] = useState(false)
  const [isApkHovered, setIsApkHovered] = useState(false)
  const [qrSvg, setQrSvg] = useState<string>('')
  const [isCardHovered, setIsCardHovered] = useState(false)

  // Card 3D tilt & border highlight tracking
  const cardRef = useRef<HTMLDivElement>(null)
  const cardRotateX = useMotionValue(0)
  const cardRotateY = useMotionValue(0)
  const smoothCardRotateX = useSpring(cardRotateX, { stiffness: 220, damping: 24, mass: 0.4 })
  const smoothCardRotateY = useSpring(cardRotateY, { stiffness: 220, damping: 24, mass: 0.4 })
  const cardBorderX = useMotionValue(-1000)
  const cardBorderY = useMotionValue(-1000)

  // Background spotlight tracking (lerped)
  const spotlightX = useMotionValue(-1000)
  const spotlightY = useMotionValue(-1000)
  const smoothSpotlightX = useSpring(spotlightX, { stiffness: 120, damping: 25, mass: 0.5 })
  const smoothSpotlightY = useSpring(spotlightY, { stiffness: 120, damping: 25, mass: 0.5 })

  // Heading refined oval grey backdrop parallax
  const headingRef = useRef<HTMLHeadingElement>(null)
  const ellipseParallaxX = useMotionValue(0)
  const ellipseParallaxY = useMotionValue(0)
  const smoothEllipseX = useSpring(ellipseParallaxX, { stiffness: 90, damping: 20, mass: 0.5 })
  const smoothEllipseY = useSpring(ellipseParallaxY, { stiffness: 90, damping: 20, mass: 0.5 })

  const spotlightBackground = useMotionTemplate`radial-gradient(550px circle at ${smoothSpotlightX}px ${smoothSpotlightY}px, rgba(255, 255, 255, 0.035), transparent 80%)`
  const cardBorderBackground = useMotionTemplate`radial-gradient(180px circle at ${cardBorderX}px ${cardBorderY}px, rgba(59, 130, 246, 0.4), transparent 75%)`

  useEffect(() => {
    if (typeof window === 'undefined') return
    const isTouch = window.matchMedia('(pointer: coarse)').matches
    setIsTouchDevice(isTouch)

    // Generate dynamic QR code matching origin
    const url = `https://github.com/priyanshu-bindal/Personal-Productivity-System/releases/download/v1.0.0/FocusFlow.apk`
    QRCode.toString(url, {
      type: 'svg',
      margin: 1,
      color: { dark: '#000000', light: '#ffffff' },
    })
      .then(setQrSvg)
      .catch(() => setQrSvg(DEFAULT_QR_SVG))

    if (isTouch || shouldReduceMotion) {
      headingRef.current?.style.setProperty('--px', '0px')
      headingRef.current?.style.setProperty('--py', '0px')
      return
    }

    const handleWindowMouseMove = (e: MouseEvent) => {
      spotlightX.set(e.clientX)
      spotlightY.set(e.clientY)

      // Slight parallax: shift ellipse up to 12px toward cursor
      if (headingRef.current) {
        const rect = headingRef.current.getBoundingClientRect()
        const centerX = rect.left + rect.width / 2
        const centerY = rect.top + rect.height / 2
        const halfW = window.innerWidth / 2 || 1
        const halfH = window.innerHeight / 2 || 1
        const normX = Math.max(-1, Math.min(1, (e.clientX - centerX) / halfW))
        const normY = Math.max(-1, Math.min(1, (e.clientY - centerY) / halfH))
        ellipseParallaxX.set(normX * 12)
        ellipseParallaxY.set(normY * 12)
      }
    }

    const unsubX = smoothEllipseX.on('change', (latestX) => {
      headingRef.current?.style.setProperty('--px', `${latestX.toFixed(2)}px`)
    })
    const unsubY = smoothEllipseY.on('change', (latestY) => {
      headingRef.current?.style.setProperty('--py', `${latestY.toFixed(2)}px`)
    })

    window.addEventListener('mousemove', handleWindowMouseMove, { passive: true })
    return () => {
      window.removeEventListener('mousemove', handleWindowMouseMove)
      unsubX()
      unsubY()
    }
  }, [spotlightX, spotlightY, isTouchDevice, shouldReduceMotion, ellipseParallaxX, ellipseParallaxY, smoothEllipseX, smoothEllipseY])

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

  const triggerErrorShake = (errorMsg: string) => {
    setFormError(errorMsg)
    if (!shouldReduceMotion) {
      setShake(true)
      setTimeout(() => setShake(false), 400)
    }
  }

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    if (isLoading || isSuccess) return

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
      triggerErrorShake('Please correct the highlighted fields.')
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
          triggerErrorShake(result.error)
          if (
            result.error.toLowerCase().includes('already exists') ||
            result.error.toLowerCase().includes('sign in')
          ) {
            setFieldErrors(prev => ({ ...prev, email: result.error }))
          }
          setIsLoading(false)
        } else if (result?.success) {
          setIsLoading(false)
          setIsSuccess(true)
          setTimeout(() => {
            window.location.href = '/'
          }, 450)
        }
      } else {
        const result = await login(formData)
        if (result?.error) {
          triggerErrorShake(result.error)
          setIsLoading(false)
        } else if (result?.success) {
          setIsLoading(false)
          setIsSuccess(true)
          setTimeout(() => {
            window.location.href = '/'
          }, 450)
        }
      }
    } catch (err: any) {
      if (err?.message !== 'NEXT_REDIRECT') {
        triggerErrorShake(
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

  const handleCardMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (isTouchDevice || shouldReduceMotion) return
    const rect = e.currentTarget.getBoundingClientRect()
    const x = e.clientX - rect.left
    const y = e.clientY - rect.top
    const centerX = rect.width / 2
    const centerY = rect.height / 2
    const rX = ((y - centerY) / centerY) * -3
    const rY = ((x - centerX) / centerX) * 3
    cardRotateX.set(rX)
    cardRotateY.set(rY)
    cardBorderX.set(x)
    cardBorderY.set(y)
    setIsCardHovered(true)
  }

  const handleCardMouseLeave = () => {
    cardRotateX.set(0)
    cardRotateY.set(0)
    setIsCardHovered(false)
  }

  // Animation variants
  const containerVariants: Variants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: shouldReduceMotion ? 0 : 0.06,
        delayChildren: 0.05,
      },
    },
  }

  const itemVariants: Variants = {
    hidden: {
      opacity: 0,
      y: shouldReduceMotion ? 0 : 12,
    },
    visible: {
      opacity: 1,
      y: 0,
      transition: {
        duration: 0.4,
        ease: EASE_OUT,
      },
    },
  }

  const headlineContainerVariants: Variants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: shouldReduceMotion ? 0 : 0.045,
      },
    },
  }

  const wordVariants: Variants = {
    hidden: {
      opacity: 0,
      y: shouldReduceMotion ? 0 : 8,
    },
    visible: {
      opacity: 1,
      y: 0,
      transition: {
        duration: 0.35,
        ease: EASE_OUT,
      },
    },
  }

  return (
    <div className="relative min-h-screen w-full bg-[#0A0A0B] text-[#FAFAFA] flex items-center justify-center p-6 sm:p-8 lg:p-12 antialiased overflow-x-clip">
      
      {/* ── 1. BACKGROUND: DOT-GRID (4% OPACITY) ── */}
      <div
        className="fixed inset-0 pointer-events-none z-0"
        style={{
          backgroundImage: 'radial-gradient(rgba(250, 250, 250, 0.25) 1px, transparent 1px)',
          backgroundSize: '24px 24px',
          opacity: 0.04,
        }}
      />

      {/* ── 2. BACKGROUND: LERPED RADIAL SPOTLIGHT (HIDDEN ON TOUCH & REDUCED MOTION) ── */}
      {!isTouchDevice && !shouldReduceMotion && (
        <motion.div
          className="fixed inset-0 pointer-events-none z-0"
          style={{
            background: spotlightBackground,
          }}
        />
      )}

      {/* ── 3. MAIN CONTENT CONTAINER (STAGGERED ENTRANCE) ── */}
      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="relative z-10 w-full max-w-6xl mx-auto"
      >
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          
          {/* ══════════════════════════════════════════
              LEFT COLUMN
          ══════════════════════════════════════════ */}
          <div className="flex flex-col justify-center space-y-8 lg:space-y-10 lg:pr-6">
            
            {/* 1. Logo + Name */}
            <motion.div variants={itemVariants}>
              <Link
                href="/"
                className="inline-flex items-center gap-3 w-fit focus:outline-none focus-visible:ring-1 focus-visible:ring-[#3B82F6] rounded-md transition-opacity duration-150 hover:opacity-90"
              >
                <div className="w-9 h-9 rounded-[8px] bg-[#111113] border border-[#232326] flex items-center justify-center text-[#FAFAFA]">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 32 32"
                    className="w-5 h-5 text-[#FAFAFA]"
                    fill="none"
                    aria-hidden="true"
                  >
                    <path
                      d="M10 8L4 16l6 8M22 8l6 8-6 8M19 6l-6 20"
                      stroke="currentColor"
                      strokeWidth="2.25"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </svg>
                </div>
                <span className="text-xl font-semibold tracking-tight text-[#FAFAFA]">
                  FocusFlow
                </span>
              </Link>
            </motion.div>

            {/* 2. Headline & Subtext (Refined oval grey backdrop via ::before pseudo-element) */}
            <div className="space-y-4">
              <motion.h1
                ref={headingRef}
                variants={itemVariants}
                className="hero-heading text-3xl sm:text-4xl lg:text-[46px] font-bold text-white tracking-tight leading-[1.12]"
              >
                <motion.span
                  variants={headlineContainerVariants}
                  className="inline-block"
                >
                  {headlineWords.map((word, i) => (
                    <motion.span
                      key={i}
                      variants={wordVariants}
                      className="inline-block mr-[0.25em] last:mr-0 text-white"
                    >
                      {word}
                    </motion.span>
                  ))}
                </motion.span>
              </motion.h1>

              {/* 3. Subtext */}
              <motion.p
                variants={itemVariants}
                className="text-base sm:text-[17px] text-[#A1A1AA] leading-relaxed max-w-lg font-normal"
              >
                One private workspace for your tasks, skills and money.
              </motion.p>
            </div>

            {/* 4. Features (small icon + label, 2-column grid, interactive hover) */}
            <motion.div
              variants={itemVariants}
              className="grid grid-cols-2 gap-x-6 gap-y-3.5 pt-2"
            >
              {features.map((feature) => {
                const Icon = feature.icon
                return (
                  <div
                    key={feature.label}
                    className="group relative flex items-start gap-2.5 p-1.5 -ml-1.5 rounded-[8px] transition-transform duration-200 ease-[cubic-bezier(0.22,1,0.36,1)] hover:translate-x-1 cursor-default min-h-[44px]"
                  >
                    <div className="mt-0.5 shrink-0 transition-transform duration-200 ease-[cubic-bezier(0.22,1,0.36,1)] group-hover:scale-110">
                      <Icon
                        className="w-4 h-4 text-[#A1A1AA] transition-colors duration-150 group-hover:text-[#3B82F6]"
                        strokeWidth={1.75}
                      />
                    </div>
                    <div className="min-w-0">
                      <span className="text-sm font-medium text-[#FAFAFA] block leading-tight transition-colors duration-150 group-hover:text-[#FAFAFA]">
                        {feature.label}
                      </span>
                      <p className="text-xs text-[#71717A] mt-0.5 leading-tight opacity-0 -translate-y-0.5 group-hover:opacity-100 group-hover:translate-y-0 transition-all duration-200 ease-[cubic-bezier(0.22,1,0.36,1)] truncate">
                        {feature.desc}
                      </p>
                    </div>
                  </div>
                )
              })}
            </motion.div>

            {/* 5. APK Button Section with Bounce & QR Popover */}
            <motion.div variants={itemVariants} className="pt-2">
              <div
                className="relative inline-block"
                onMouseEnter={() => setIsApkHovered(true)}
                onMouseLeave={() => setIsApkHovered(false)}
              >
                <a
                  href="https://github.com/priyanshu-bindal/Personal-Productivity-System/releases/download/v1.0.0/FocusFlow.apk"
                  download="FocusFlow.apk"
                  className="inline-flex items-center justify-center gap-2.5 h-[44px] px-5 rounded-[8px] bg-[#111113] border border-[#232326] hover:border-[#3B82F6] hover:bg-[#18181B] text-[#FAFAFA] text-sm font-medium transition-colors duration-150 focus:outline-none focus-visible:ring-1 focus-visible:ring-[#3B82F6] group cursor-pointer"
                >
                  <AndroidIcon className="w-4 h-4 shrink-0 text-[#FAFAFA]" />
                  <span>Download Android App (APK)</span>
                  <motion.div
                    animate={
                      isApkHovered && !shouldReduceMotion
                        ? { y: [0, 4, 0] }
                        : { y: 0 }
                    }
                    transition={{ duration: 0.3, ease: EASE_OUT }}
                    className="shrink-0 text-[#A1A1AA] group-hover:text-[#3B82F6] transition-colors duration-150"
                  >
                    <Download className="w-4 h-4" strokeWidth={1.75} />
                  </motion.div>
                </a>

                {/* Scan to install QR Popover (Desktop only) */}
                <AnimatePresence>
                  {isApkHovered && (
                    <motion.div
                      role="tooltip"
                      initial={{ opacity: 0, y: shouldReduceMotion ? 0 : 8, scale: 0.96 }}
                      animate={{ opacity: 1, y: 0, scale: 1 }}
                      exit={{ opacity: 0, y: shouldReduceMotion ? 0 : 6, scale: 0.96 }}
                      transition={{ duration: 0.18, ease: EASE_OUT }}
                      className="hidden lg:block absolute bottom-full mb-3 left-0 z-30 w-44 rounded-[12px] bg-[#111113] border border-[#232326] p-3 shadow-2xl pointer-events-none"
                    >
                      <div className="flex flex-col items-center text-center space-y-2">
                        <div className="w-28 h-28 rounded-[6px] bg-white p-1.5 flex items-center justify-center overflow-hidden">
                          <div
                            className="w-full h-full [&>svg]:w-full [&>svg]:h-full"
                            dangerouslySetInnerHTML={{ __html: qrSvg || DEFAULT_QR_SVG }}
                          />
                        </div>
                        <div className="space-y-0.5">
                          <p className="text-xs font-medium text-[#FAFAFA]">Scan to install</p>
                          <p className="text-[11px] text-[#A1A1AA]">Instant install • Free &amp; private on mobile</p>
                        </div>
                      </div>
                      {/* Triangle Pointer */}
                      <div className="absolute top-full left-8 -mt-[1px] w-2 h-2 rotate-45 bg-[#111113] border-r border-b border-[#232326]" />
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
              <div className="mt-2.5 flex items-center gap-2 text-xs text-[#A1A1AA]">
                <span className="relative flex h-2 w-2">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
                  <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500" />
                </span>
                <span className="font-medium text-[#E4E4E7]">Take your focus anywhere • 100% free &amp; private</span>
              </div>
            </motion.div>
          </div>

          {/* ══════════════════════════════════════════
              RIGHT COLUMN: AUTH CARD (GLASSY, SHARP, HIGHLIGHTED)
          ══════════════════════════════════════════ */}
          <motion.div
            variants={itemVariants}
            className="relative flex items-center justify-center lg:justify-end w-full"
            style={{ perspective: 1000 }}
          >
            {/* Ambient Backlight Highlight behind the card */}
            <div
              className="absolute -inset-4 sm:-inset-6 -z-10 rounded-3xl pointer-events-none opacity-80"
              style={{
                background:
                  'radial-gradient(ellipse at center, rgba(59, 130, 246, 0.12) 0%, rgba(255, 255, 255, 0.04) 45%, transparent 75%)',
                filter: 'blur(36px)',
              }}
              aria-hidden="true"
            />

            <motion.div
              ref={cardRef}
              onMouseMove={handleCardMouseMove}
              onMouseLeave={handleCardMouseLeave}
              animate={
                shake && !shouldReduceMotion
                  ? { x: [0, -6, 6, -4, 4, -2, 2, 0] }
                  : { x: 0 }
              }
              transition={
                shake
                  ? { duration: 0.35, ease: EASE_OUT }
                  : { duration: 0.2 }
              }
              style={{
                rotateX: shouldReduceMotion ? 0 : smoothCardRotateX,
                rotateY: shouldReduceMotion ? 0 : smoothCardRotateY,
                transformStyle: 'preserve-3d',
              }}
              className="relative w-full max-w-[420px] rounded-[14px] bg-[#121316]/80 backdrop-blur-2xl border border-white/[0.14] p-6 sm:p-8 overflow-hidden shadow-[0_24px_50px_-12px_rgba(0,0,0,0.85),0_0_0_1px_rgba(255,255,255,0.06),0_1px_2px_rgba(255,255,255,0.08)_inset]"
            >
              {/* Top specular glass rim reflection */}
              <div className="absolute inset-x-0 top-0 h-[1px] bg-gradient-to-r from-transparent via-white/[0.28] to-transparent pointer-events-none z-20" />

              {/* Inner ambient glass sheen */}
              <div className="absolute inset-0 bg-gradient-to-b from-white/[0.035] via-transparent to-black/[0.2] pointer-events-none rounded-[14px]" />

              {/* 1px Border Highlight Tracking Pointer */}
              <motion.div
                className="absolute -inset-[1px] rounded-[15px] pointer-events-none z-20"
                style={{
                  opacity: isCardHovered && !isTouchDevice && !shouldReduceMotion ? 1 : 0,
                  transition: 'opacity 200ms ease',
                  background: cardBorderBackground,
                  mask: 'linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0)',
                  maskComposite: 'exclude',
                  WebkitMask: 'linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0)',
                  WebkitMaskComposite: 'xor',
                  padding: '1px',
                }}
              />

              {/* Tabs: Sign In / Create Account with Sliding Pill */}
              <div
                role="tablist"
                aria-label="Authentication Options"
                className="relative grid grid-cols-2 p-1 mb-6 rounded-[8px] bg-[#0A0B0E]/85 backdrop-blur-md border border-white/[0.1] z-10 shadow-inner"
              >
                <button
                  type="button"
                  role="tab"
                  id="tab-signin"
                  aria-selected={mode === 'signin'}
                  aria-controls="panel-signin"
                  onClick={() => switchMode('signin')}
                  className="relative h-9 text-xs sm:text-sm font-medium rounded-[6px] transition-colors duration-150 focus:outline-none focus-visible:ring-1 focus-visible:ring-[#3B82F6] cursor-pointer"
                >
                  {mode === 'signin' && (
                    <motion.div
                      layoutId="tab-pill"
                      className="absolute inset-0 bg-white/[0.09] border border-white/[0.18] rounded-[6px] shadow-[0_2px_8px_rgba(0,0,0,0.5)] z-0"
                      transition={{ type: 'spring', stiffness: 450, damping: 35 }}
                    />
                  )}
                  <span
                    className={`relative z-10 transition-colors duration-150 ${
                      mode === 'signin' ? 'text-white font-semibold' : 'text-[#A1A1AA] hover:text-white'
                    }`}
                  >
                    Sign In
                  </span>
                </button>
                <button
                  type="button"
                  role="tab"
                  id="tab-signup"
                  aria-selected={mode === 'signup'}
                  aria-controls="panel-signup"
                  onClick={() => switchMode('signup')}
                  className="relative h-9 text-xs sm:text-sm font-medium rounded-[6px] transition-colors duration-150 focus:outline-none focus-visible:ring-1 focus-visible:ring-[#3B82F6] cursor-pointer"
                >
                  {mode === 'signup' && (
                    <motion.div
                      layoutId="tab-pill"
                      className="absolute inset-0 bg-white/[0.09] border border-white/[0.18] rounded-[6px] shadow-[0_2px_8px_rgba(0,0,0,0.5)] z-0"
                      transition={{ type: 'spring', stiffness: 450, damping: 35 }}
                    />
                  )}
                  <span
                    className={`relative z-10 transition-colors duration-150 ${
                      mode === 'signup' ? 'text-white font-semibold' : 'text-[#A1A1AA] hover:text-white'
                    }`}
                  >
                    Create Account
                  </span>
                </button>
              </div>

              {/* Form Content: Cross-Fade with 8px Slide on Switch */}
              <AnimatePresence mode="wait" initial={false}>
                <motion.form
                  key={mode}
                  id={mode === 'signin' ? 'panel-signin' : 'panel-signup'}
                  role="tabpanel"
                  aria-labelledby={mode === 'signin' ? 'tab-signin' : 'tab-signup'}
                  initial={{ opacity: 0, x: shouldReduceMotion ? 0 : mode === 'signin' ? -8 : 8 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: shouldReduceMotion ? 0 : mode === 'signin' ? 8 : -8 }}
                  transition={{ duration: 0.2, ease: EASE_OUT }}
                  onSubmit={handleSubmit}
                  noValidate
                  className="space-y-4 relative z-10"
                >
                  {/* Full Name Field (Sign Up Only) */}
                  {mode === 'signup' && (
                    <div className="space-y-1.5 group">
                      <label
                        htmlFor="full_name"
                        className="block text-xs font-medium text-[#E4E4E7] transition-colors duration-150 group-focus-within:text-[#3B82F6]"
                      >
                        Full Name
                      </label>
                      <input
                        id="full_name"
                        name="full_name"
                        type="text"
                        autoComplete="name"
                        value={fullName}
                        onChange={e => {
                          setFullName(e.target.value)
                          if (fieldErrors.fullName) {
                            setFieldErrors(prev => ({ ...prev, fullName: undefined }))
                          }
                        }}
                        placeholder="Enter your name"
                        disabled={isLoading || isSuccess}
                        className={`w-full h-[44px] px-3.5 rounded-[8px] bg-[#0A0B0E]/70 backdrop-blur-md border text-sm text-[#FAFAFA] placeholder:text-[#71717A] focus:outline-none transition-all duration-150 ${
                          fieldErrors.fullName
                            ? 'border-red-500 focus:border-red-500 focus:ring-1 focus:ring-red-500'
                            : 'border-white/[0.12] hover:border-white/[0.22] focus:border-[#3B82F6] focus:ring-2 focus:ring-[#3B82F6]/30'
                        }`}
                      />
                      {fieldErrors.fullName && (
                        <p className="text-xs text-red-400 mt-1">{fieldErrors.fullName}</p>
                      )}
                    </div>
                  )}

                  {/* Email Field */}
                  <div className="space-y-1.5 group">
                    <label
                      htmlFor="email"
                      className="block text-xs font-medium text-[#E4E4E7] transition-colors duration-150 group-focus-within:text-[#3B82F6]"
                    >
                      Email
                    </label>
                    <input
                      id="email"
                      name="email"
                      type="email"
                      autoComplete="email"
                      value={email}
                      onChange={e => {
                        setEmail(e.target.value)
                        if (fieldErrors.email) {
                          setFieldErrors(prev => ({ ...prev, email: undefined }))
                        }
                      }}
                      placeholder="Enter your email"
                      disabled={isLoading || isSuccess}
                      className={`w-full h-[44px] px-3.5 rounded-[8px] bg-[#0A0B0E]/70 backdrop-blur-md border text-sm text-[#FAFAFA] placeholder:text-[#71717A] focus:outline-none transition-all duration-150 ${
                        fieldErrors.email
                          ? 'border-red-500 focus:border-red-500 focus:ring-1 focus:ring-red-500'
                          : 'border-white/[0.12] hover:border-white/[0.22] focus:border-[#3B82F6] focus:ring-2 focus:ring-[#3B82F6]/30'
                      }`}
                    />
                    {fieldErrors.email && (
                      <p className="text-xs text-red-400 mt-1">{fieldErrors.email}</p>
                    )}
                  </div>

                  {/* Password Field with Eye Toggle Morph */}
                  <div className="space-y-1.5 group">
                    <div className="flex items-center justify-between">
                      <label
                        htmlFor="password"
                        className="block text-xs font-medium text-[#E4E4E7] transition-colors duration-150 group-focus-within:text-[#3B82F6]"
                      >
                        Password
                      </label>
                      {mode === 'signin' && (
                        <button
                          type="button"
                          onClick={() => {
                            setForgotEmail(email)
                            setShowForgotModal(true)
                            setForgotSuccess(false)
                            setForgotError(null)
                          }}
                          className="text-xs text-[#3B82F6] hover:underline transition-colors duration-150 focus:outline-none focus-visible:ring-1 focus-visible:ring-[#3B82F6] rounded"
                        >
                          Forgot password?
                        </button>
                      )}
                    </div>
                    <div className="relative">
                      <input
                        id="password"
                        name="password"
                        type={showPassword ? 'text' : 'password'}
                        autoComplete={mode === 'signin' ? 'current-password' : 'new-password'}
                        value={password}
                        onChange={e => {
                          setPassword(e.target.value)
                          if (fieldErrors.password) {
                            setFieldErrors(prev => ({ ...prev, password: undefined }))
                          }
                        }}
                        placeholder="Enter your password"
                        disabled={isLoading || isSuccess}
                        className={`w-full h-[44px] pl-3.5 pr-10 rounded-[8px] bg-[#0A0B0E]/70 backdrop-blur-md border text-sm text-[#FAFAFA] placeholder:text-[#71717A] focus:outline-none transition-all duration-150 ${
                          fieldErrors.password
                            ? 'border-red-500 focus:border-red-500 focus:ring-1 focus:ring-red-500'
                            : 'border-white/[0.12] hover:border-white/[0.22] focus:border-[#3B82F6] focus:ring-2 focus:ring-[#3B82F6]/30'
                        }`}
                      />
                      <button
                        type="button"
                        onClick={() => setShowPassword(p => !p)}
                        className="absolute right-3 top-1/2 -translate-y-1/2 text-[#71717A] hover:text-[#FAFAFA] transition-colors duration-150 focus:outline-none focus-visible:ring-1 focus-visible:ring-[#3B82F6] rounded p-1 cursor-pointer"
                        aria-label={showPassword ? 'Hide password' : 'Show password'}
                      >
                        <AnimatePresence mode="wait" initial={false}>
                          {showPassword ? (
                            <motion.div
                              key="eye-off"
                              initial={{ opacity: 0, scale: 0.8, rotate: -20 }}
                              animate={{ opacity: 1, scale: 1, rotate: 0 }}
                              exit={{ opacity: 0, scale: 0.8, rotate: 20 }}
                              transition={{ duration: 0.15, ease: EASE_OUT }}
                            >
                              <EyeOff className="w-4 h-4" />
                            </motion.div>
                          ) : (
                            <motion.div
                              key="eye"
                              initial={{ opacity: 0, scale: 0.8, rotate: 20 }}
                              animate={{ opacity: 1, scale: 1, rotate: 0 }}
                              exit={{ opacity: 0, scale: 0.8, rotate: -20 }}
                              transition={{ duration: 0.15, ease: EASE_OUT }}
                            >
                              <Eye className="w-4 h-4" />
                            </motion.div>
                          )}
                        </AnimatePresence>
                      </button>
                    </div>
                    {fieldErrors.password && (
                      <p className="text-xs text-red-400 mt-1">{fieldErrors.password}</p>
                    )}
                  </div>

                  {/* Inline Error Message */}
                  <AnimatePresence>
                    {formError && !fieldErrors.email?.includes('already exists') && (
                      <motion.div
                        initial={{ opacity: 0, y: -4 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: -4 }}
                        transition={{ duration: 0.2, ease: EASE_OUT }}
                        className="p-3 rounded-[8px] bg-red-500/10 border border-red-500/20 text-xs text-red-400 leading-relaxed"
                      >
                        {formError}
                      </motion.div>
                    )}
                  </AnimatePresence>

                  {/* Primary Action Button (Premium iOS Style Glass) */}
                  <motion.button
                    type="submit"
                    disabled={isLoading || isSuccess}
                    whileHover={shouldReduceMotion ? undefined : { y: -0.5, filter: 'brightness(1.05)' }}
                    whileTap={shouldReduceMotion ? undefined : { scale: 0.985, filter: 'brightness(0.95)' }}
                    transition={{ duration: 0.15, ease: EASE_OUT }}
                    className="relative w-full h-[40px] mt-2.5 rounded-[10px] bg-gradient-to-b from-[#3B82F6]/95 via-[#2563EB]/90 to-[#1D4ED8]/95 backdrop-blur-xl border border-white/25 hover:border-white/35 text-white text-[13.5px] font-semibold tracking-[-0.01em] transition-all duration-150 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#3B82F6] focus-visible:ring-offset-2 focus-visible:ring-offset-[#111113] disabled:opacity-60 disabled:cursor-not-allowed flex items-center justify-center gap-1.5 cursor-pointer group shadow-[inset_0_1px_1px_rgba(255,255,255,0.45),inset_0_-1px_1px_rgba(0,0,0,0.3),0_4px_14px_-2px_rgba(37,99,235,0.45),0_1px_3px_rgba(0,0,0,0.3)] overflow-hidden"
                  >
                    {/* Top specular glass reflection line */}
                    <div className="absolute inset-x-0 top-0 h-[1px] bg-gradient-to-r from-transparent via-white/60 to-transparent pointer-events-none" />

                    {/* Upper subtle glass sheen */}
                    <div className="absolute inset-x-0 top-0 h-1/2 bg-gradient-to-b from-white/[0.12] to-transparent pointer-events-none rounded-t-[10px]" />

                    <AnimatePresence mode="wait" initial={false}>
                      {isSuccess ? (
                        <motion.div
                          key="success"
                          initial={{ opacity: 0, scale: 0.8 }}
                          animate={{ opacity: 1, scale: 1 }}
                          exit={{ opacity: 0 }}
                          transition={{ duration: 0.2, ease: EASE_OUT }}
                          className="relative z-10 flex items-center gap-1.5"
                        >
                          <svg
                            viewBox="0 0 24 24"
                            className="w-4 h-4 text-white drop-shadow-[0_1px_1px_rgba(0,0,0,0.3)]"
                            fill="none"
                            stroke="currentColor"
                            strokeWidth={2.5}
                            strokeLinecap="round"
                            strokeLinejoin="round"
                          >
                            <motion.path
                              d="M5 13l4 4L19 7"
                              initial={{ pathLength: 0 }}
                              animate={{ pathLength: 1 }}
                              transition={{ duration: 0.3, ease: EASE_OUT }}
                            />
                          </svg>
                        </motion.div>
                      ) : isLoading ? (
                        <motion.span
                          key="loading"
                          initial={{ opacity: 0 }}
                          animate={{ opacity: 1 }}
                          exit={{ opacity: 0 }}
                          className="relative z-10 flex items-center gap-2 drop-shadow-[0_1px_1px_rgba(0,0,0,0.3)]"
                        >
                          <Loader2 className="w-3.5 h-3.5 animate-spin text-white" />
                          <span>{mode === 'signin' ? 'Signing in…' : 'Creating account…'}</span>
                        </motion.span>
                      ) : (
                        <motion.span
                          key="default"
                          initial={{ opacity: 0 }}
                          animate={{ opacity: 1 }}
                          exit={{ opacity: 0 }}
                          className="relative z-10 flex items-center gap-1.5 drop-shadow-[0_1px_1px_rgba(0,0,0,0.3)]"
                        >
                          <span>{mode === 'signin' ? 'Sign in' : 'Create account'}</span>
                          <ArrowRight className="w-3.5 h-3.5 stroke-[2.25] transition-transform duration-150 group-hover:translate-x-0.5" />
                        </motion.span>
                      )}
                    </AnimatePresence>
                  </motion.button>
                </motion.form>
              </AnimatePresence>
            </motion.div>
          </motion.div>

        </div>
      </motion.div>

      {/* ── FORGOT PASSWORD MODAL ── */}
      <AnimatePresence>
        {showForgotModal && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.15 }}
            role="dialog"
            aria-modal="true"
            aria-labelledby="forgot-modal-title"
            className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70"
          >
            <motion.div
              initial={{ opacity: 0, scale: shouldReduceMotion ? 1 : 0.98, y: shouldReduceMotion ? 0 : 8 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: shouldReduceMotion ? 1 : 0.98, y: shouldReduceMotion ? 0 : 6 }}
              transition={{ duration: 0.2, ease: EASE_OUT }}
              className="relative w-full max-w-md rounded-[14px] bg-[#121316]/90 backdrop-blur-2xl border border-white/[0.14] p-6 space-y-4 shadow-[0_24px_50px_rgba(0,0,0,0.85),0_0_0_1px_rgba(255,255,255,0.06),0_1px_2px_rgba(255,255,255,0.08)_inset] overflow-hidden"
            >
              <div className="absolute inset-x-0 top-0 h-[1px] bg-gradient-to-r from-transparent via-white/[0.28] to-transparent pointer-events-none" />
              <div className="flex items-center justify-between">
                <h3 id="forgot-modal-title" className="text-base font-semibold text-[#FAFAFA]">
                  Reset your password
                </h3>
                <button
                  type="button"
                  onClick={() => setShowForgotModal(false)}
                  className="text-xs text-[#A1A1AA] hover:text-[#FAFAFA] transition-colors duration-150 focus:outline-none focus-visible:ring-1 focus-visible:ring-[#3B82F6] rounded px-1.5 py-0.5 cursor-pointer"
                >
                  Close
                </button>
              </div>

              {forgotSuccess ? (
                <div className="p-4 rounded-[8px] bg-[#0A0A0B] border border-[#232326] space-y-3 text-xs text-[#A1A1AA]">
                  <p className="text-sm font-medium text-[#FAFAFA]">
                    Instructions sent
                  </p>
                  <p className="leading-relaxed">
                    We&apos;ve sent a password reset link to <strong className="text-[#FAFAFA]">{forgotEmail}</strong>. Please check your inbox.
                  </p>
                  <button
                    type="button"
                    onClick={() => setShowForgotModal(false)}
                    className="w-full h-[44px] rounded-[8px] bg-[#18181B] hover:bg-[#202024] border border-[#232326] text-[#FAFAFA] text-sm font-medium transition-colors duration-150 cursor-pointer"
                  >
                    Return to Sign In
                  </button>
                </div>
              ) : (
                <form onSubmit={handleForgotPasswordSubmit} noValidate className="space-y-4">
                  <p className="text-xs text-[#A1A1AA] leading-relaxed">
                    Enter your email address and we&apos;ll send you a link to reset your password.
                  </p>

                  <div className="space-y-1.5 group">
                    <label
                      htmlFor="forgot_email"
                      className="block text-xs font-medium text-[#FAFAFA] transition-colors duration-150 group-focus-within:text-[#3B82F6]"
                    >
                      Email
                    </label>
                    <input
                      id="forgot_email"
                      type="email"
                      autoComplete="email"
                      value={forgotEmail}
                      onChange={e => setForgotEmail(e.target.value)}
                      placeholder="Enter your email"
                      required
                      className="w-full h-[44px] px-3.5 rounded-[8px] bg-[#0A0B0E]/70 backdrop-blur-md border border-white/[0.12] hover:border-white/[0.22] text-sm text-[#FAFAFA] placeholder:text-[#71717A] focus:outline-none focus:border-[#3B82F6] focus:ring-2 focus:ring-[#3B82F6]/30 transition-all duration-150"
                    />
                  </div>

                  {forgotError && (
                    <div className="p-3 rounded-[8px] bg-red-500/10 border border-red-500/20 text-xs text-red-400">
                      {forgotError}
                    </div>
                  )}

                  <div className="flex items-center gap-2.5 pt-2">
                    <button
                      type="button"
                      onClick={() => setShowForgotModal(false)}
                      className="flex-1 h-[40px] rounded-[10px] bg-white/[0.04] hover:bg-white/[0.08] border border-white/[0.1] text-xs font-medium text-[#A1A1AA] hover:text-white transition-colors duration-150 cursor-pointer"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      disabled={forgotLoading}
                      className="relative flex-1 h-[40px] rounded-[10px] bg-gradient-to-b from-[#3B82F6]/95 via-[#2563EB]/90 to-[#1D4ED8]/95 backdrop-blur-xl border border-white/25 hover:border-white/35 text-white text-[13px] font-semibold tracking-[-0.01em] shadow-[inset_0_1px_1px_rgba(255,255,255,0.45),inset_0_-1px_1px_rgba(0,0,0,0.3),0_4px_14px_-2px_rgba(37,99,235,0.45)] transition-all duration-150 flex items-center justify-center gap-2 cursor-pointer disabled:opacity-60 overflow-hidden"
                    >
                      <div className="absolute inset-x-0 top-0 h-[1px] bg-gradient-to-r from-transparent via-white/60 to-transparent pointer-events-none" />
                      {forgotLoading ? (
                        <Loader2 className="w-3.5 h-3.5 animate-spin text-white" />
                      ) : (
                        'Send reset link'
                      )}
                    </button>
                  </div>
                </form>
              )}
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
