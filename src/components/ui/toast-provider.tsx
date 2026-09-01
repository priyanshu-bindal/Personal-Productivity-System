'use client'

import { createContext, useContext, useState, useCallback, ReactNode } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { CheckCircle2, XCircle, Info, X } from 'lucide-react'

type ToastType = 'success' | 'error' | 'info'

interface Toast {
  id: string
  type: ToastType
  title: string
  description?: string
}

interface ToastContextType {
  toast: (opts: { type?: ToastType; title: string; description?: string }) => void
  success: (title: string, description?: string) => void
  error: (title: string, description?: string) => void
}

const ToastContext = createContext<ToastContextType | null>(null)

export function useToast() {
  const ctx = useContext(ToastContext)
  if (!ctx) throw new Error('useToast must be used within ToastProvider')
  return ctx
}

let toastCounter = 0

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([])

  const addToast = useCallback((opts: { type?: ToastType; title: string; description?: string }) => {
    const id = `toast-${++toastCounter}`
    const newToast: Toast = { id, type: opts.type || 'info', title: opts.title, description: opts.description }
    
    setToasts(prev => [...prev, newToast])

    // Auto-dismiss after 2.5s
    setTimeout(() => {
      setToasts(prev => prev.filter(t => t.id !== id))
    }, 2500)
  }, [])

  const dismiss = useCallback((id: string) => {
    setToasts(prev => prev.filter(t => t.id !== id))
  }, [])

  const contextValue: ToastContextType = {
    toast: addToast,
    success: (title, description) => addToast({ type: 'success', title, description }),
    error: (title, description) => addToast({ type: 'error', title, description }),
  }

  const icons: Record<ToastType, ReactNode> = {
    success: <CheckCircle2 className="h-4 w-4 text-emerald-500" />,
    error: <XCircle className="h-4 w-4 text-red-500" />,
    info: <Info className="h-4 w-4 text-primary" />,
  }

  const borderColors: Record<ToastType, string> = {
    success: 'border-emerald-500/30',
    error: 'border-red-500/30',
    info: 'border-primary/30',
  }

  return (
    <ToastContext.Provider value={contextValue}>
      {children}

      {/* Toast Container — fixed bottom-right on desktop, bottom-center on mobile */}
      <div className="fixed bottom-20 md:bottom-6 right-4 md:right-6 z-[100] flex flex-col gap-2 items-end pointer-events-none">
        <AnimatePresence mode="popLayout">
          {toasts.map(t => (
            <motion.div
              key={t.id}
              layout
              initial={{ opacity: 0, y: 16, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -8, scale: 0.95 }}
              transition={{ duration: 0.2, ease: [0.22, 1, 0.36, 1] }}
              className={`pointer-events-auto flex items-center gap-3 px-4 py-3 rounded-xl border bg-card shadow-lg backdrop-blur-sm min-w-[220px] max-w-[340px] ${borderColors[t.type]}`}
            >
              <span className="shrink-0">{icons[t.type]}</span>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium leading-tight">{t.title}</p>
                {t.description && (
                  <p className="text-xs text-muted-foreground mt-0.5 leading-tight truncate">{t.description}</p>
                )}
              </div>
              <button
                onClick={() => dismiss(t.id)}
                className="shrink-0 text-muted-foreground hover:text-foreground transition-colors"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>
    </ToastContext.Provider>
  )
}
