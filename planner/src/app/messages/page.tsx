'use client'

import { useState, useEffect, useRef } from 'react'
import { createClient } from '@/lib/supabase/client'
import { ensureFirebaseAuth } from '@/lib/firebase/authBridge'
import {
  ensureUserChatId,
  lookupUserByChatId,
  getOrCreateConversation,
  sendMessage,
  markMessagesAsSeen,
  subscribeToConversations,
  subscribeToMessages,
  Conversation,
  Message,
  getUserShortId,
  getUserProfile,
  UserProfile
} from '@/lib/firebase/chatService'
import {
  ArrowLeft,
  Check,
  CheckCheck,
  Clock3,
  Copy,
  Hash,
  MoreHorizontal,
  Plus,
  Send,
  Search,
  MessageSquare,
  AlertCircle,
  X
} from 'lucide-react'

// ─── Helpers ────────────────────────────────────────────────────────────────

function formatTime(ts: any): string {
  if (!ts) return ''
  const d = ts?.toDate ? ts.toDate() : new Date(ts)
  return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

function shortAgo(ts: any): string {
  if (!ts) return ''
  try {
    const d = ts?.toDate ? ts.toDate() : new Date(ts)
    const diff = Date.now() - d.getTime()
    if (diff < 60000) return 'now'
    if (diff < 3600000) return `${Math.floor(diff / 60000)}m`
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}h`
    return `${Math.floor(diff / 86400000)}d`
  } catch { return '' }
}

function formatDetailedTimestamp(ts: any): { dateLine: string; timeLine: string; fullStr: string } | null {
  if (!ts) return null
  try {
    const d = ts?.toDate ? ts.toDate() : (ts instanceof Date ? ts : new Date(ts))
    if (isNaN(d.getTime())) return null

    const now = new Date()
    const isToday = now.toDateString() === d.toDateString()

    const yesterday = new Date(now)
    yesterday.setDate(now.getDate() - 1)
    const isYesterday = yesterday.toDateString() === d.toDateString()

    const timeLine = d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true })

    if (isToday) {
      return { dateLine: 'Today', timeLine, fullStr: `Today at ${timeLine}` }
    } else if (isYesterday) {
      return { dateLine: 'Yesterday', timeLine, fullStr: `Yesterday at ${timeLine}` }
    } else {
      const dateLine = d.toLocaleDateString([], { month: 'long', day: 'numeric', year: 'numeric' })
      return { dateLine, timeLine, fullStr: `${dateLine} at ${timeLine}` }
    }
  } catch {
    return null
  }
}

function idToColor(id: string): string {
  const colors = [
    '#3B5B8C', '#7E9ED4', '#324D75', '#2A4164',
    '#4A6FA5', '#5A7FB8', '#345280', '#2C456E'
  ]
  let hash = 0
  for (let i = 0; i < id.length; i++) hash = id.charCodeAt(i) + ((hash << 5) - hash)
  return colors[Math.abs(hash) % colors.length]
}

// ─── Sub-components ──────────────────────────────────────────────────────────

function IdMarker({ id, name, size = 'md' }: { id: string; name?: string; size?: 'sm' | 'md' | 'lg' }) {
  const cleanName = name?.trim()
  const initials = cleanName
    ? cleanName.split(' ').map((n: string) => n[0]).join('').slice(0, 2).toUpperCase()
    : id.slice(0, 2).toUpperCase()
  const dims = size === 'sm' ? 'w-8 h-8 text-[11px]' : size === 'lg' ? 'w-11 h-11 text-sm' : 'w-9 h-9 text-xs'
  return (
    <div
      className={`${dims} rounded-xl flex items-center justify-center font-bold shrink-0 select-none transition-transform duration-200`}
      style={{
        backgroundColor: 'rgba(59, 91, 140, 0.12)',
        color: '#7E9ED4',
        border: '1px solid rgba(59, 91, 140, 0.35)'
      }}
    >
      {initials}
    </div>
  )
}

function StatusIcon({ status, className }: { status: Message['status']; className?: string }) {
  if (status === 'sending') return <Clock3 className={className || "h-3 w-3 animate-spin text-[#70707a]"} />
  if (status === 'sent') return <Check className={className || "h-3 w-3 text-[#70707a]"} />
  if (status === 'seen') return <CheckCheck className={className || "h-3.5 w-3.5 text-[#3B5B8C]"} />
  return null
}

// ─── Empty States ─────────────────────────────────────────────────────────────

function EmptyConversations({ onNew }: { onNew: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center h-full px-6 py-12 text-center">
      <div className="w-12 h-12 rounded-2xl bg-[#202025] border border-[#2a2a31] flex items-center justify-center mx-auto mb-4 text-[#7E9ED4]">
        <MessageSquare className="h-6 w-6" />
      </div>
      <h3 className="text-sm font-semibold text-[#f1f1f3] mb-1">No messages yet</h3>
      <p className="text-xs text-[#9a9aa5] leading-relaxed mb-5 max-w-[200px]">
        Start a private conversation using a Focus ID.
      </p>
      <button
        onClick={onNew}
        className="inline-flex items-center gap-1.5 px-3.5 py-2 ios-glass-button text-xs font-bold active:scale-95 shadow-xs"
      >
        <Plus className="h-3.5 w-3.5" /> Start New Chat
      </button>
    </div>
  )
}

function EmptyChatArea({ otherId }: { otherId: string }) {
  return (
    <div className="flex flex-col items-center justify-center h-full px-8 text-center">
      <div className="w-12 h-12 rounded-2xl bg-[#202025] border border-[#2a2a31] flex items-center justify-center mx-auto mb-3 text-[#7E9ED4]">
        <MessageSquare className="h-6 w-6" />
      </div>
      <h3 className="text-sm font-semibold text-[#f1f1f3] mb-1">Start the conversation</h3>
      <p className="text-xs text-[#9a9aa5]">
        Send a message to start chatting with <span className="font-mono font-bold text-[#7E9ED4]">#{otherId}</span>.
      </p>
    </div>
  )
}

function NoConversationSelected({ onNew }: { onNew: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center h-full px-8 text-center">
      <div className="w-14 h-14 rounded-2xl bg-[#202025] border border-[#2a2a31] flex items-center justify-center mx-auto mb-4 text-[#70707a]">
        <MessageSquare className="h-7 w-7 opacity-70" />
      </div>
      <h3 className="text-sm font-semibold text-[#f1f1f3] mb-1">Select a conversation</h3>
      <p className="text-xs text-[#9a9aa5] mb-5 max-w-[220px]">
        Choose an existing chat from the left or start a new private conversation.
      </p>
      <button
        onClick={onNew}
        className="inline-flex items-center gap-1.5 px-4 py-2 ios-glass-button text-xs font-bold active:scale-95 shadow-xs"
      >
        <Plus className="h-3.5 w-3.5" /> Start New Chat
      </button>
    </div>
  )
}

// ─── Seen Info Popup Dropdown ───────────────────────────────────────────────

// ─── Seen Info & Context Menu Glass Popover ─────────────────────────────────

function SeenInfoPopup({
  msg,
  isOut,
  onClose
}: {
  msg: Message
  isOut: boolean
  onClose: () => void
}) {
  const popupRef = useRef<HTMLDivElement>(null)
  const [isClosing, setIsClosing] = useState(false)

  const handleClose = () => {
    setIsClosing(true)
    setTimeout(onClose, 120)
  }

  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (popupRef.current && !popupRef.current.contains(e.target as Node)) {
        handleClose()
      }
    }
    function handleKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') handleClose()
    }
    document.addEventListener('mousedown', handleClickOutside)
    document.addEventListener('keydown', handleKeyDown)
    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
      document.removeEventListener('keydown', handleKeyDown)
    }
  }, [])

  const seenFormatted = msg.status === 'seen' ? formatDetailedTimestamp(msg.seenAt || msg.createdAt) : null
  const sentFormatted = formatDetailedTimestamp(msg.deliveredAt || msg.createdAt)

  return (
    <div className="relative">
      {/* Blurred Color Glow Behind Popover */}
      <div
        className={`glass-popover-glow ${
          isOut ? 'right-6 bottom-3' : 'left-6 bottom-3'
        } ${isClosing ? 'animate-glow-out' : 'animate-glow-in'}`}
      />

      <div
        ref={popupRef}
        className={`absolute z-50 bottom-full mb-3 ${
          isOut ? 'right-6 origin-bottom-right' : 'left-6 origin-bottom-left'
        } w-64 glass-popover text-white ${
          isClosing ? 'animate-popover-out' : 'animate-popover-in'
        }`}
      >
        {/* Header row: icon (17px, light blue #93C5FD) + title (15px/500 white), close icon right-aligned at 55% opacity */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <StatusIcon status={msg.status} className="w-[17px] h-[17px] text-[#93C5FD]" />
            <span className="text-[15px] font-medium text-white capitalize">
              {msg.status === 'seen' ? 'Seen' : msg.status === 'sent' ? 'Sent' : 'Sending...'}
            </span>
          </div>
          <button
            onClick={handleClose}
            className="w-5 h-5 rounded-md flex items-center justify-center text-white/55 hover:text-white/90 transition-opacity duration-150"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        {/* Divider: 1px solid rgba(255,255,255,0.15), margin-top 12px, padding-top 12px */}
        <div className="border-t border-white/15 pt-3 mt-3 space-y-2">
          {msg.status === 'sending' ? (
            <p className="text-[13px] text-white/70">Sending message to recipient…</p>
          ) : msg.status === 'seen' ? (
            <div>
              <p className="text-[10px] font-bold text-white/50 tracking-[0.06em] uppercase mb-1">SEEN AT</p>
              {seenFormatted ? (
                <>
                  <p className="text-[14px] font-medium text-white">{seenFormatted.dateLine}</p>
                  <p className="text-[13px] font-mono text-[#93C5FD] mt-0.5">{seenFormatted.timeLine}</p>
                </>
              ) : (
                <p className="text-[14px] font-medium text-white">Seen by recipient</p>
              )}
            </div>
          ) : (
            <div>
              <p className="text-[10px] font-bold text-white/50 tracking-[0.06em] uppercase mb-1">SENT AT</p>
              {sentFormatted ? (
                <>
                  <p className="text-[14px] font-medium text-white">{sentFormatted.dateLine}</p>
                  <p className="text-[13px] font-mono text-[#93C5FD] mt-0.5">{sentFormatted.timeLine}</p>
                </>
              ) : (
                <p className="text-[14px] font-medium text-white">Delivered to server</p>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

// ─── New Chat Panel / Modal ──────────────────────────────────────────────────

function NewChatPanel({
  onClose,
  onSuccess,
  currentChatId,
  currentFirebaseUid,
  onConvCreated
}: {
  onClose: () => void
  onSuccess: (convId: string, otherId: string, targetUid: string) => void
  currentChatId: string | null
  currentFirebaseUid: string | null
  onConvCreated: (targetUid: string, shortId: string) => void
}) {
  const [input, setInput] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [copied, setCopied] = useState(false)
  const [isClosing, setIsClosing] = useState(false)

  const handleClose = () => {
    setIsClosing(true)
    setTimeout(() => {
      onClose()
    }, 250)
  }

  const handleCopy = () => {
    if (!currentChatId) return
    navigator.clipboard.writeText(currentChatId)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    const sanitized = input.trim().toUpperCase().replace(/[^A-Z0-9]/g, '')
    if (!sanitized || sanitized.length < 4) { setError('Please enter a valid Focus ID.'); return }
    if (sanitized === currentChatId) { setError('You cannot message yourself.'); return }
    if (!currentFirebaseUid) { setError('Auth not ready. Please wait.'); return }

    setLoading(true)
    try {
      const targetUid = await lookupUserByChatId(sanitized)
      if (!targetUid) { setError('No user found with this Focus ID.'); setLoading(false); return }
      const convId = await getOrCreateConversation(currentFirebaseUid, targetUid)
      onConvCreated(targetUid, sanitized)
      onSuccess(convId, sanitized, targetUid)
    } catch (err: any) {
      setError(err.message || 'Failed to start conversation.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div
      className={`flex flex-col h-full bg-[#18181b] text-[#f1f1f3] ${
        isClosing ? 'animate-panel-out' : 'animate-panel-in'
      }`}
    >
      {/* Header */}
      <div className="flex items-center gap-3 px-5 py-4 border-b border-[#2a2a31] bg-[#18181b]">
        <button
          onClick={handleClose}
          className="w-8 h-8 rounded-xl flex items-center justify-center hover:bg-[#202025] text-[#9a9aa5] hover:text-[#f1f1f3] transition-colors"
        >
          <ArrowLeft className="h-4 w-4" />
        </button>
        <div>
          <p className="text-sm font-bold text-[#f1f1f3]">New Conversation</p>
          <p className="text-[11px] text-[#9a9aa5]">Connect privately using a Focus ID.</p>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-5 space-y-4 msg-scrollbar">
        {/* Input Card - iOS Glassmorphism */}
        <div className="ios-glass-card p-5 animate-card-stagger-1">
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <label className="flex items-center gap-1.5 text-xs font-medium text-[#BFDBFE]">
                <Hash className="h-3.5 w-3.5 text-[#60A5FA]" />
                Recipient Focus ID
              </label>
              <input
                value={input}
                onChange={e => { setInput(e.target.value.toUpperCase()); setError('') }}
                placeholder="Enter Focus ID (e.g. 6TXPK)"
                maxLength={7}
                className="w-full h-12 px-4 ios-glass-input font-mono text-center text-lg font-bold tracking-widest text-[#FFFFFF] placeholder:text-[#70707a] placeholder:font-sans placeholder:text-xs placeholder:tracking-normal uppercase"
                autoFocus
                autoComplete="off"
                spellCheck={false}
              />
              <p className="text-[11px] text-[#9a9aa5] text-center">
                Enter the 5-character ID shared with you.
              </p>
            </div>

            {error && (
              <div className="flex items-center gap-2 p-3 rounded-xl bg-red-500/10 border border-red-500/20 text-red-400 text-xs">
                <AlertCircle className="h-3.5 w-3.5 shrink-0" />
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={!input.trim() || loading}
              className="w-full h-11 ios-glass-button text-xs font-bold disabled:opacity-40 disabled:cursor-not-allowed active:scale-[0.98]"
            >
              {loading ? 'Searching...' : 'Start Conversation →'}
            </button>
          </form>
        </div>

        {/* Identity Card - iOS Glassmorphism */}
        {currentChatId && (
          <div className="ios-glass-card p-5 animate-card-stagger-2">
            <div className="flex items-center gap-2 mb-2">
              <Hash className="h-3.5 w-3.5 text-[#60A5FA]" />
              <p className="text-[10px] font-bold tracking-wider text-[#9a9aa5] uppercase">YOUR FOCUS ID</p>
            </div>
            <div className="flex items-center justify-between">
              <span className="font-mono text-xl font-bold tracking-widest text-[#BFDBFE]">#{currentChatId}</span>
              <button
                onClick={handleCopy}
                className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl border border-white/20 bg-white/10 hover:bg-white/15 text-xs font-semibold text-[#BFDBFE] hover:text-[#FFFFFF] transition-all"
              >
                {copied ? <Check className="h-3.5 w-3.5 text-[#60A5FA]" /> : <Copy className="h-3.5 w-3.5" />}
                {copied ? 'Copied' : 'Copy'}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

// ─── Main Page Component ──────────────────────────────────────────────────────

export default function MessagesPage() {
  const [supabaseUser, setSupabaseUser] = useState<any>(null)
  const [firebaseUid, setFirebaseUid] = useState<string | null>(null)
  const [currentChatId, setCurrentChatId] = useState<string | null>(null)
  const [isLoadingAuth, setIsLoadingAuth] = useState(true)
  const [firebaseError, setFirebaseError] = useState<string | null>(null)

  const [conversations, setConversations] = useState<Conversation[]>([])
  const [shortIdCache, setShortIdCache] = useState<Record<string, string>>({})
  const [userProfiles, setUserProfiles] = useState<Record<string, UserProfile>>({})

  const [activeConvId, setActiveConvId] = useState<string | null>(null)
  const [activeOtherShortId, setActiveOtherShortId] = useState<string>('')

  const [messages, setMessages] = useState<Message[]>([])
  const [inputText, setInputText] = useState('')
  const [isSending, setIsSending] = useState(false)
  const [searchQuery, setSearchQuery] = useState('')
  const [copiedId, setCopiedId] = useState(false)
  const [activeMenuMsgId, setActiveMenuMsgId] = useState<string | null>(null)

  const messagesEndRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)
  const [showNewChat, setShowNewChat] = useState(false)

  const handleCopyMyId = () => {
    if (!currentChatId) return
    navigator.clipboard.writeText(currentChatId)
    setCopiedId(true)
    setTimeout(() => setCopiedId(false), 2000)
  }

  // 1. Initialize Auth — use Firebase UID for Firestore
  useEffect(() => {
    async function initAuth() {
      try {
        const supabase = createClient()
        const { data: { user } } = await supabase.auth.getUser()
        if (user) {
          setSupabaseUser(user)
          const fbUid = await ensureFirebaseAuth(user.id, user.email)
          setFirebaseUid(fbUid)
          const name = user.user_metadata?.full_name || user.user_metadata?.name || user.email?.split('@')[0] || ''
          const shortId = await ensureUserChatId(fbUid, name)
          setCurrentChatId(shortId)
        }
      } catch (err: any) {
        console.error('Error initializing chat:', err)
        setFirebaseError(err?.message || 'Failed to initialize chat.')
      } finally {
        setIsLoadingAuth(false)
      }
    }
    initAuth()
  }, [])

  // 2. Subscribe to Conversations & Load Profiles
  useEffect(() => {
    if (!firebaseUid) return
    const unsub = subscribeToConversations(firebaseUid, async (rawConvs) => {
      setConversations(rawConvs)
      
      const missingUids = rawConvs
        .map(c => c.participants.find(p => p !== firebaseUid)!)
        .filter(uid => uid && !userProfiles[uid])

      if (missingUids.length > 0) {
        const entries: Record<string, UserProfile> = {}
        const sidEntries: Record<string, string> = {}
        for (const uid of missingUids) {
          try {
            const prof = await getUserProfile(uid)
            if (prof) {
              entries[uid] = prof
              if (prof.shortUserId) sidEntries[uid] = prof.shortUserId
            }
          } catch {}
        }
        setUserProfiles(prev => ({ ...prev, ...entries }))
        setShortIdCache(prev => ({ ...prev, ...sidEntries }))
      }
    })
    return () => unsub()
  }, [firebaseUid])

  // 3. Subscribe to Messages & Mark Seen
  useEffect(() => {
    if (!activeConvId || !firebaseUid) return

    markMessagesAsSeen(activeConvId, firebaseUid)

    const unsub = subscribeToMessages(activeConvId, (msgs) => {
      setMessages(msgs)
      const hasUnseen = msgs.some(m => m.receiverId === firebaseUid && m.status !== 'seen')
      if (hasUnseen) {
        markMessagesAsSeen(activeConvId, firebaseUid)
      }
      setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }), 80)
    })
    return () => unsub()
  }, [activeConvId, firebaseUid])

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const handleSendMessage = async (e?: React.FormEvent) => {
    if (e) e.preventDefault()
    const text = inputText.trim()
    if (!text || !activeConvId || !firebaseUid || isSending) return

    const conv = conversations.find(c => c.id === activeConvId)
    const receiverId = conv?.participants.find(p => p !== firebaseUid) || ''

    setInputText('')
    setIsSending(true)

    const optimistic: Message = {
      id: `temp_${Date.now()}`,
      senderId: firebaseUid,
      receiverId,
      text,
      status: 'sending',
      createdAt: new Date()
    }
    setMessages(prev => [...prev, optimistic])

    try {
      await sendMessage(activeConvId, firebaseUid, receiverId, text)
    } catch (err) {
      console.error('Send error:', err)
    } finally {
      setIsSending(false)
      setTimeout(() => inputRef.current?.focus(), 50)
    }
  }

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); handleSendMessage() }
  }

  const openConversation = (convId: string, otherId: string) => {
    setActiveConvId(convId)
    setActiveOtherShortId(otherId)
    setShowNewChat(false)
    setActiveMenuMsgId(null)
  }

  // Filter conversations by search query
  const filteredConversations = conversations.filter(conv => {
    if (!searchQuery.trim()) return true
    const q = searchQuery.toLowerCase()
    const otherUid = conv.participants.find(p => p !== firebaseUid) || ''
    const profile = conv.participantProfiles?.[otherUid] || userProfiles[otherUid]
    const shortId = (conv.otherUserShortId && conv.otherUserShortId.length <= 6 ? conv.otherUserShortId : null) || profile?.shortUserId || shortIdCache[otherUid] || ''
    const name = profile?.displayName || ''
    return shortId.toLowerCase().includes(q) || name.toLowerCase().includes(q)
  })

  // ─── Loading ──────────────────────────────────────────────────────────────
  if (isLoadingAuth) {
    return (
      <div className="flex items-center justify-center h-[calc(100vh-6rem)] bg-[#111113]">
        <div className="flex flex-col items-center gap-3">
          <div className="w-10 h-10 rounded-2xl bg-[rgba(59,91,140,0.12)] border border-[rgba(59,91,140,0.35)] flex items-center justify-center animate-pulse">
            <MessageSquare className="h-5 w-5 text-[#3B5B8C]" />
          </div>
          <p className="text-xs font-medium text-[#9a9aa5]">Connecting to FocusFlow Messages…</p>
        </div>
      </div>
    )
  }

  // ─── Layout ───────────────────────────────────────────────────────────────
  return (
    <div
      className="h-[calc(100vh-4rem)] md:h-[calc(100vh-2rem)] flex flex-col bg-[#111113] text-[#f1f1f3]"
      style={{ fontFamily: "'Inter', system-ui, sans-serif" }}
    >
      <style jsx global>{`
        .msg-scrollbar::-webkit-scrollbar {
          width: 6px;
        }
        .msg-scrollbar::-webkit-scrollbar-track {
          background: transparent;
        }
        .msg-scrollbar::-webkit-scrollbar-thumb {
          background: #2a2a31;
          border-radius: 10px;
        }
        .msg-scrollbar::-webkit-scrollbar-thumb:hover {
          background: #3b3b45;
        }

        /* iOS Glassmorphism Custom Tokens */
        .ios-glass-button {
          background: rgba(59, 130, 246, 0.45);
          backdrop-filter: blur(20px) saturate(180%);
          -webkit-backdrop-filter: blur(20px) saturate(180%);
          border: 1px solid rgba(147, 197, 253, 0.40);
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.30), inset 0 1px 0 rgba(255, 255, 255, 0.35);
          border-radius: 16px;
          color: #ffffff;
          transition: all 150ms ease;
        }
        .ios-glass-button:hover {
          background: rgba(59, 130, 246, 0.65);
          border-color: rgba(147, 197, 253, 0.60);
          box-shadow: 0 12px 36px rgba(0, 0, 0, 0.40), inset 0 1px 0 rgba(255, 255, 255, 0.45);
        }

        .ios-glass-card {
          background: rgba(255, 255, 255, 0.08);
          backdrop-filter: blur(20px) saturate(180%);
          -webkit-backdrop-filter: blur(20px) saturate(180%);
          border: 1px solid rgba(255, 255, 255, 0.20);
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.30), inset 0 1px 0 rgba(255, 255, 255, 0.25);
          border-radius: 18px;
          transition: all 150ms ease;
        }

        .ios-glass-input {
          background: rgba(255, 255, 255, 0.07);
          backdrop-filter: blur(20px) saturate(180%);
          -webkit-backdrop-filter: blur(20px) saturate(180%);
          border: 1px solid rgba(255, 255, 255, 0.20);
          box-shadow: 0 4px 20px rgba(0, 0, 0, 0.25), inset 0 1px 0 rgba(255, 255, 255, 0.20);
          border-radius: 16px;
          transition: all 150ms ease;
        }
        .ios-glass-input:focus {
          border-color: rgba(147, 197, 253, 0.55);
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.35), inset 0 1px 0 rgba(255, 255, 255, 0.35), 0 0 16px rgba(59, 130, 246, 0.35);
          outline: none;
        }

        /* Shared Glass Popover Utility & Glow */
        .glass-popover-glow {
          position: absolute;
          width: 180px;
          height: 180px;
          background: radial-gradient(circle, rgba(59, 130, 246, 0.35), transparent 70%);
          filter: blur(50px);
          z-index: 40;
          pointer-events: none;
        }

        .glass-popover {
          background: rgba(255, 255, 255, 0.14);
          backdrop-filter: blur(28px) saturate(200%);
          -webkit-backdrop-filter: blur(28px) saturate(200%);
          border: 1px solid rgba(255, 255, 255, 0.28);
          border-radius: 18px;
          padding: 16px 18px;
          box-shadow: 
            0 12px 40px rgba(0, 0, 0, 0.50),
            inset 0 1px 0 rgba(255, 255, 255, 0.45),
            inset 0 -1px 0 rgba(0, 0, 0, 0.15);
        }

        /* Glass Popover Keyframes */
        @keyframes glassPopoverIn {
          from {
            opacity: 0;
            transform: scale(0.92) translateY(4px);
          }
          to {
            opacity: 1;
            transform: scale(1) translateY(0);
          }
        }
        @keyframes glassPopoverOut {
          from {
            opacity: 1;
            transform: scale(1) translateY(0);
          }
          to {
            opacity: 0;
            transform: scale(0.92) translateY(4px);
          }
        }
        @keyframes glowIn {
          from {
            opacity: 0;
            transform: scale(0.85);
          }
          to {
            opacity: 1;
            transform: scale(1);
          }
        }
        @keyframes glowOut {
          from {
            opacity: 1;
            transform: scale(1);
          }
          to {
            opacity: 0;
            transform: scale(0.85);
          }
        }
        .animate-popover-in {
          animation: glassPopoverIn 180ms cubic-bezier(0.16, 1, 0.3, 1) forwards;
        }
        .animate-popover-out {
          animation: glassPopoverOut 120ms cubic-bezier(0.16, 1, 0.3, 1) forwards;
        }
        .animate-glow-in {
          animation: glowIn 140ms ease-out forwards;
        }
        .animate-glow-out {
          animation: glowOut 120ms ease-out forwards;
        }

        /* Glass Panel Animation Keyframes */
        @keyframes glassPanelIn {
          from {
            opacity: 0;
            transform: translateX(16px);
          }
          to {
            opacity: 1;
            transform: translateX(0);
          }
        }
        @keyframes glassPanelOut {
          from {
            opacity: 1;
            transform: translateX(0);
          }
          to {
            opacity: 0;
            transform: translateX(16px);
          }
        }
        @keyframes glassCardStagger {
          from {
            opacity: 0;
            transform: translateY(12px) scale(0.98);
          }
          to {
            opacity: 1;
            transform: translateY(0) scale(1);
          }
        }
        .animate-panel-in {
          animation: glassPanelIn 300ms cubic-bezier(0.16, 1, 0.3, 1) forwards;
        }
        .animate-panel-out {
          animation: glassPanelOut 250ms cubic-bezier(0.16, 1, 0.3, 1) forwards;
        }
        .animate-card-stagger-1 {
          animation: glassCardStagger 320ms cubic-bezier(0.16, 1, 0.3, 1) 60ms both;
        }
        .animate-card-stagger-2 {
          animation: glassCardStagger 320ms cubic-bezier(0.16, 1, 0.3, 1) 140ms both;
        }
      `}</style>

      {/* Connection Warning Banner */}
      {firebaseError && (
        <div className="mx-4 mt-3 p-3 rounded-xl bg-amber-500/10 border border-amber-500/20 text-amber-400 text-xs flex items-start gap-2.5 shrink-0">
          <AlertCircle className="h-4 w-4 shrink-0 mt-0.5 text-amber-400" />
          <div>
            <p className="font-semibold mb-0.5">Connection Notice</p>
            <p className="opacity-80">{firebaseError}</p>
          </div>
        </div>
      )}

      {/* Main Content Card Container */}
      <div className="flex-1 flex overflow-hidden m-2 sm:m-3 md:m-4 rounded-2xl border border-[#2a2a31] bg-[#1d1d21] shadow-2xl min-h-0">

        {/* ── LEFT PANEL (Conversations Sidebar) ── */}
        <div
          className={`flex flex-col border-r border-[#2a2a31] bg-[#18181b] shrink-0 transition-all duration-200 ${
            showNewChat || activeConvId ? 'w-0 md:w-72 lg:w-80 overflow-hidden' : 'w-full md:w-72 lg:w-80'
          } ${
            showNewChat ? 'hidden md:flex' : activeConvId ? 'hidden md:flex' : 'flex'
          }`}
        >
          {/* Header */}
          <div className="px-4 pt-4 pb-3 border-b border-[#2a2a31]">
            <div className="flex items-center justify-between mb-3">
              <div>
                <h1 className="text-lg font-bold text-[#f1f1f3] tracking-tight">Messages</h1>
                <p className="text-[11px] text-[#9a9aa5]">Private conversations, simply connected.</p>
              </div>

              <button
                onClick={() => { setShowNewChat(true); setActiveConvId(null) }}
                className="flex items-center gap-1.5 px-3.5 py-1.5 ios-glass-button text-xs font-bold active:scale-95 shrink-0"
              >
                <Plus className="h-3.5 w-3.5" />
                New Chat
              </button>
            </div>

            {/* Search Input */}
            <div className="relative">
              <Search className="absolute left-3 top-2.5 h-3.5 w-3.5 text-[#70707a]" />
              <input
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
                placeholder="Search conversations..."
                className="w-full h-8 pl-8 pr-3 rounded-lg border border-[#2a2a31] bg-[#202025] text-xs text-[#f1f1f3] placeholder-[#70707a] focus:border-[#3B5B8C] focus:outline-none transition-colors"
              />
            </div>
          </div>

          {/* User ID Identity Card - iOS Glassmorphism */}
          {currentChatId && (
            <div className="mx-3 my-2.5 p-3.5 ios-glass-card flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div
                  className="w-7 h-7 rounded-lg flex items-center justify-center shrink-0"
                  style={{
                    backgroundColor: 'rgba(59, 130, 246, 0.20)',
                    color: '#BFDBFE',
                    border: '1px solid rgba(147, 197, 253, 0.40)'
                  }}
                >
                  <Hash className="h-3.5 w-3.5" />
                </div>
                <div>
                  <p className="text-[9px] font-bold tracking-wider text-[#9a9aa5] uppercase">YOUR FOCUS ID</p>
                  <p className="font-mono font-bold text-xs tracking-widest text-[#BFDBFE]">#{currentChatId}</p>
                </div>
              </div>
              <button
                onClick={handleCopyMyId}
                className="px-2.5 py-1 rounded-lg border border-white/20 bg-white/10 text-[11px] font-semibold text-[#BFDBFE] hover:text-[#FFFFFF] hover:border-white/40 transition-all flex items-center gap-1"
              >
                {copiedId ? <Check className="h-3 w-3 text-[#60A5FA]" /> : <Copy className="h-3 w-3" />}
                {copiedId ? 'Copied' : 'Copy'}
              </button>
            </div>
          )}

          {/* Conversation List */}
          <div className="flex-1 overflow-y-auto msg-scrollbar">
            {filteredConversations.length === 0 ? (
              <EmptyConversations onNew={() => { setShowNewChat(true); setActiveConvId(null) }} />
            ) : (
              <div className="py-1 space-y-0.5 px-1.5">
                {filteredConversations.map((conv) => {
                  const otherUid = conv.participants.find(p => p !== firebaseUid) || ''
                  const profile = conv.participantProfiles?.[otherUid] || userProfiles[otherUid]
                  const displayId = (conv.otherUserShortId && conv.otherUserShortId.length <= 6 ? conv.otherUserShortId : null) || profile?.shortUserId || shortIdCache[otherUid] || '···'
                  const displayName = profile?.displayName
                  const isActive = conv.id === activeConvId
                  const timeStr = shortAgo(conv.lastMessageAt)
                  const unreadCount = conv.unreadCounts?.[firebaseUid || ''] || 0

                  return (
                    <button
                      key={conv.id}
                      onClick={() => openConversation(conv.id, displayId)}
                      style={{
                        background: isActive ? 'rgba(59, 91, 140, 0.10)' : undefined,
                        borderLeft: isActive ? '2px solid #3B5B8C' : '2px solid transparent'
                      }}
                      className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-left transition-colors duration-150 group ${
                        !isActive ? 'hover:bg-[#202025]' : ''
                      }`}
                    >
                      {/* Avatar */}
                      <IdMarker id={displayId} name={displayName} size="md" />

                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between mb-0.5">
                          <span className={`text-xs font-semibold truncate ${isActive ? 'text-[#f1f1f3]' : 'text-[#9a9aa5]'}`}>
                            {displayName ? (
                              <>
                                {displayName}{' '}
                                <span className="font-mono text-[11px] font-normal text-[#70707a]">({displayId})</span>
                              </>
                            ) : (
                              <span className="font-mono font-bold tracking-wide text-[#f1f1f3]">#{displayId}</span>
                            )}
                          </span>
                          {timeStr && (
                            <span className="text-[10px] text-[#70707a] shrink-0 ml-1.5">{timeStr}</span>
                          )}
                        </div>
                        <p className={`text-[11px] truncate leading-relaxed ${isActive ? 'text-[#9a9aa5]' : 'text-[#70707a]'}`}>
                          {conv.lastMessage || 'No messages yet'}
                        </p>
                      </div>

                      {unreadCount > 0 && !isActive ? (
                        <div
                          style={{
                            background: 'rgba(59, 91, 140, 0.20)',
                            border: '1px solid rgba(59, 91, 140, 0.35)',
                            color: '#7E9ED4'
                          }}
                          className="min-w-[20px] h-5 px-1.5 rounded-full font-bold text-[11px] flex items-center justify-center shrink-0"
                        >
                          {unreadCount > 99 ? '99+' : unreadCount}
                        </div>
                      ) : isActive ? (
                        <div className="w-1.5 h-1.5 rounded-full bg-[#3B5B8C] shrink-0 shadow-xs" />
                      ) : null}
                    </button>
                  )
                })}
              </div>
            )}
          </div>
        </div>

        {/* ── NEW CHAT PANEL Overlay ── */}
        <div
          className={`flex flex-col shrink-0 transition-all duration-200 ${
            showNewChat ? 'w-full md:w-72 lg:w-80 flex' : 'w-0 hidden'
          }`}
        >
          {showNewChat && (
            <NewChatPanel
              onClose={() => setShowNewChat(false)}
              currentChatId={currentChatId}
              currentFirebaseUid={firebaseUid}
              onConvCreated={(uid, sid) => setShortIdCache(prev => ({ ...prev, [uid]: sid }))}
              onSuccess={(convId, sid) => {
                setShowNewChat(false)
                setActiveConvId(convId)
                setActiveOtherShortId(sid)
              }}
            />
          )}
        </div>

        {/* ── RIGHT CHAT AREA ── */}
        <div className={`flex-1 flex flex-col min-w-0 bg-[#1d1d21] ${activeConvId ? 'flex' : 'hidden md:flex'}`}>
          {activeConvId ? (
            <>
              {/* Chat Header */}
              {(() => {
                const activeConv = conversations.find(c => c.id === activeConvId)
                const activeOtherUid = activeConv?.participants.find(p => p !== firebaseUid) || ''
                const targetProfile = activeConv?.participantProfiles?.[activeOtherUid] || userProfiles[activeOtherUid]
                const headerShortId = (activeOtherShortId && activeOtherShortId.length <= 6 ? activeOtherShortId : null) || activeConv?.otherUserShortId || targetProfile?.shortUserId || shortIdCache[activeOtherUid] || 'Chat'
                const headerDisplayName = targetProfile?.displayName

                return (
                  <div className="flex items-center justify-between px-5 py-3 border-b border-[#2a2a31] bg-[#1d1d21] shrink-0">
                    <div className="flex items-center gap-3">
                      <button
                        onClick={() => setActiveConvId(null)}
                        className="md:hidden w-8 h-8 rounded-lg flex items-center justify-center hover:bg-[#202025] text-[#9a9aa5]"
                      >
                        <ArrowLeft className="h-4 w-4" />
                      </button>
                      <IdMarker id={headerShortId} name={headerDisplayName} size="sm" />
                      <div>
                        {headerDisplayName ? (
                          <div className="flex items-baseline gap-1.5">
                            <p className="font-bold text-sm text-[#f1f1f3]">{headerDisplayName}</p>
                            <p className="font-mono text-xs font-normal text-[#70707a]">({headerShortId})</p>
                          </div>
                        ) : (
                          <p className="font-mono font-bold text-sm text-[#f1f1f3] tracking-wide">#{headerShortId}</p>
                        )}
                        <p className="text-[10px] text-[#70707a]">Private conversation</p>
                      </div>
                    </div>

                    <button className="w-8 h-8 rounded-lg flex items-center justify-center hover:bg-[#202025] text-[#9a9aa5] transition-colors">
                      <MoreHorizontal className="h-4 w-4" />
                    </button>
                  </div>
                )
              })()}

              {/* Messages Stream Area */}
              <div className="flex-1 overflow-y-auto px-4 sm:px-6 py-4 space-y-2 bg-[#111113] msg-scrollbar">
                {messages.length === 0 ? (
                  <EmptyChatArea otherId={activeOtherShortId} />
                ) : (
                  (() => {
                    const rendered: React.ReactNode[] = []
                    let lastDateStr = ''
                    messages.forEach((msg, i) => {
                      const isOut = msg.senderId === firebaseUid
                      const ts = msg.createdAt?.toDate ? msg.createdAt.toDate() : new Date(msg.createdAt)
                      const dateStr = ts.toLocaleDateString([], { weekday: 'long', month: 'short', day: 'numeric' })
                      const timeStr = formatTime(msg.createdAt)
                      const isMenuOpen = activeMenuMsgId === msg.id

                      // Date divider
                      if (dateStr !== lastDateStr) {
                        lastDateStr = dateStr
                        const isToday = new Date().toDateString() === ts.toDateString()
                        rendered.push(
                          <div key={`date-${i}`} className="flex items-center justify-center py-3">
                            <span
                              style={{
                                background: '#1d1d21',
                                border: '1px solid #2a2a31',
                                color: '#70707a'
                              }}
                              className="px-3 py-0.5 rounded-full text-[10px] font-medium tracking-wide"
                            >
                              {isToday ? 'Today' : dateStr}
                            </span>
                          </div>
                        )
                      }

                      rendered.push(
                        <div
                          key={msg.id}
                          className={`flex ${isOut ? 'justify-end' : 'justify-start'} animate-in fade-in slide-in-from-bottom-1 duration-150`}
                        >
                          <div className={`max-w-[75%] sm:max-w-[62%] ${isOut ? 'items-end' : 'items-start'} flex flex-col relative group`}>
                            
                            {/* Message Bubble + Action Button Container */}
                            <div className={`flex items-center gap-1.5 ${isOut ? 'flex-row' : 'flex-row-reverse'}`}>
                              
                              {/* Action Button (Three dots ...) */}
                              <div className="relative">
                                <button
                                  type="button"
                                  onClick={(e) => {
                                    e.stopPropagation()
                                    setActiveMenuMsgId(isMenuOpen ? null : msg.id)
                                  }}
                                  className={`w-6 h-6 rounded-md bg-[#202025] hover:bg-[#2a2a31] border border-[#2a2a31] text-[#9a9aa5] hover:text-[#f1f1f3] flex items-center justify-center cursor-pointer shadow-xs transition-all duration-150 ${
                                    isMenuOpen
                                      ? 'opacity-100 scale-100 pointer-events-auto'
                                      : 'opacity-0 scale-90 pointer-events-none group-hover:opacity-100 group-hover:scale-100 group-hover:pointer-events-auto'
                                  }`}
                                  title="View message status & delivery info"
                                >
                                  <MoreHorizontal className="h-3.5 w-3.5" />
                                </button>

                                {/* Seen Info Popup Dropdown */}
                                {isMenuOpen && (
                                  <SeenInfoPopup
                                    msg={msg}
                                    isOut={isOut}
                                    onClose={() => setActiveMenuMsgId(null)}
                                  />
                                )}
                              </div>

                              {/* Bubble */}
                              <div
                                style={
                                  isOut
                                    ? {
                                        background: 'rgba(59, 91, 140, 0.14)',
                                        border: '1px solid rgba(59, 91, 140, 0.30)',
                                        color: '#f1f1f3',
                                        borderRadius: '14px'
                                      }
                                    : {
                                        background: '#202025',
                                        border: '1px solid #2a2a31',
                                        color: '#f1f1f3',
                                        borderRadius: '14px'
                                      }
                                }
                                className="px-4 py-2.5 text-sm leading-relaxed shadow-xs"
                              >
                                <p className="whitespace-pre-wrap break-words">{msg.text}</p>
                              </div>

                            </div>

                            {/* Timestamp & Status Icon below bubble */}
                            <div className={`flex items-center gap-1 mt-1 px-1 ${isOut ? 'flex-row-reverse' : ''}`}>
                              <span className="text-[10px] text-[#70707a]">{timeStr}</span>
                              {isOut && <StatusIcon status={msg.status} />}
                            </div>
                          </div>
                        </div>
                      )
                    })
                    return rendered
                  })()
                )}
                <div ref={messagesEndRef} />
              </div>

              {/* Message Input Area (Composer) */}
              <div className="px-4 sm:px-5 py-3 border-t border-[#2a2a31] bg-[#1d1d21] shrink-0">
                <form onSubmit={handleSendMessage} className="flex items-center gap-2.5">
                  <input
                    ref={inputRef}
                    value={inputText}
                    onChange={e => setInputText(e.target.value)}
                    onKeyDown={handleKeyDown}
                    placeholder="Write a message…"
                    style={{
                      background: '#202025',
                      border: '1px solid #2a2a31',
                      color: '#f1f1f3'
                    }}
                    className="flex-1 h-10 px-4 rounded-xl text-sm placeholder:text-[#70707a] focus:outline-none focus:border-[#3B5B8C]/60 focus:ring-2 focus:ring-[#3B5B8C]/10 transition-all"
                    autoComplete="off"
                  />
                  <button
                    type="submit"
                    disabled={!inputText.trim() || isSending}
                    className="w-10 h-10 rounded-xl bg-[#3B5B8C] hover:bg-[#324D75] text-[#ffffff] font-bold flex items-center justify-center shrink-0 active:scale-95 disabled:opacity-40 disabled:cursor-not-allowed transition-all shadow-xs"
                  >
                    <Send className="h-4 w-4" />
                  </button>
                </form>
              </div>
            </>
          ) : (
            <NoConversationSelected onNew={() => { setShowNewChat(true); setActiveConvId(null) }} />
          )}
        </div>

      </div>
    </div>
  )
}
