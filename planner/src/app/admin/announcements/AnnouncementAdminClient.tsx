'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog'
import { Bell, Send, CheckCircle2, AlertCircle, Sparkles, Smartphone, Users, History, Link as LinkIcon, RefreshCw, RotateCw } from 'lucide-react'
import { TrafficLoader } from '@/components/ui/traffic-loader'

interface AnnouncementRecord {
  id: string
  announcementId: string
  title: string
  message: string
  route?: string | null
  createdAt: string | null
  recipientCount: number
  successCount: number
  failureCount: number
}

export function AnnouncementAdminClient() {
  const [title, setTitle] = useState('')
  const [message, setMessage] = useState('')
  const [route, setRoute] = useState('')

  // Confirmation dialog state
  const [isConfirmOpen, setIsConfirmOpen] = useState(false)
  const [isSending, setIsSending] = useState(false)

  // Feedback states
  const [successInfo, setSuccessInfo] = useState<{
    recipientUsers: number
    deviceCount: number
    uniqueTokens: number
    totalDevices: number
    successCount: number
    failureCount: number
  } | null>(null)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  // Recent announcements state
  const [recentList, setRecentList] = useState<AnnouncementRecord[]>([])
  const [isLoadingHistory, setIsLoadingHistory] = useState(false)

  const fetchRecent = async () => {
    setIsLoadingHistory(true)
    try {
      const res = await fetch('/api/notify/announcement')
      if (res.ok) {
        const data = await res.json()
        if (data?.announcements) {
          setRecentList(data.announcements)
        }
      }
    } catch {
      // ignore
    } finally {
      setIsLoadingHistory(false)
    }
  }

  useEffect(() => {
    fetchRecent()
  }, [])

  const handleOpenConfirm = (e: React.FormEvent) => {
    e.preventDefault()
    setErrorMessage(null)
    setSuccessInfo(null)

    if (!title.trim()) {
      setErrorMessage('Please enter an announcement title.')
      return
    }
    if (!message.trim()) {
      setErrorMessage('Please write your announcement message.')
      return
    }

    setIsConfirmOpen(true)
  }

  const handleSendAnnouncement = async () => {
    setIsSending(true)
    setErrorMessage(null)

    try {
      const res = await fetch('/api/notify/announcement', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          title: title.trim(),
          message: message.trim(),
          route: route.trim() || undefined,
        }),
      })

      const data = await res.json()

      if (!res.ok || !data.success) {
        setErrorMessage(data?.error || 'Unable to send announcement. Please try again.')
        setIsConfirmOpen(false)
        return
      }

      // Success
      setSuccessInfo({
        recipientUsers: data.recipientUsers ?? 0,
        deviceCount: data.deviceCount ?? (data.totalDevices ?? 0),
        uniqueTokens: data.uniqueTokens ?? (data.totalDevices ?? 0),
        totalDevices: data.totalDevices ?? 0,
        successCount: data.successCount ?? 0,
        failureCount: data.failureCount ?? 0,
      })

      // Clear the form
      setTitle('')
      setMessage('')
      setRoute('')
      setIsConfirmOpen(false)

      // Refresh recent announcements list
      fetchRecent()
    } catch (err: any) {
      setErrorMessage('Unable to send announcement. Please try again.')
      setIsConfirmOpen(false)
    } finally {
      setIsSending(false)
    }
  }

  const handleRepeatAnnouncement = (item: AnnouncementRecord) => {
    setTitle(item.title)
    setMessage(item.message)
    setRoute(item.route || '')
    setErrorMessage(null)
    setSuccessInfo(null)
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      {/* Header */}
      <div className="space-y-2">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg bg-blue-500/10 border border-blue-500/20 flex items-center justify-center text-blue-400">
            <Bell className="w-4 h-4" />
          </div>
          <span className="text-xs uppercase tracking-widest text-blue-400 font-medium">Administration</span>
        </div>
        <h1 className="text-2xl md:text-3xl font-semibold tracking-tight text-zinc-100">Announcements</h1>
        <p className="text-sm text-zinc-400">
          Send important updates to FocusFlow users.
        </p>
      </div>

      {/* Delivery Feedback Banner */}
      {successInfo && (
        <div className={`rounded-xl border p-4 md:p-5 flex items-start gap-3 backdrop-blur-md animate-in fade-in slide-in-from-top-2 duration-300 ${
          successInfo.successCount > 0 
            ? 'border-emerald-500/20 bg-emerald-950/30' 
            : 'border-amber-500/20 bg-amber-950/30'
        }`}>
          {successInfo.successCount > 0 ? (
            <CheckCircle2 className="w-5 h-5 text-emerald-400 shrink-0 mt-0.5" />
          ) : (
            <AlertCircle className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />
          )}
          <div className="space-y-1">
            <h3 className={`text-sm font-medium ${
              successInfo.successCount > 0 ? 'text-emerald-200' : 'text-amber-200'
            }`}>
              {successInfo.successCount > 0 ? 'Announcement sent' : 'Delivery Incomplete'}
            </h3>
            <p className={`text-xs ${
              successInfo.successCount > 0 ? 'text-emerald-300/80' : 'text-amber-300/80'
            }`}>
              {successInfo.successCount > 0 ? (
                <>
                  <span className="font-semibold text-emerald-200">{successInfo.recipientUsers}</span> user(s), <span className="font-semibold text-emerald-200">{successInfo.deviceCount}</span> device(s), <span className="font-semibold text-emerald-200">{successInfo.uniqueTokens}</span> unique token(s) ({successInfo.successCount} delivered
                  {successInfo.failureCount > 0 && (
                    <span className="text-zinc-400">, {successInfo.failureCount} failed</span>
                  )}
                  ).
                </>
              ) : successInfo.totalDevices > 0 ? (
                `Broadcast attempted to ${successInfo.recipientUsers} user(s) (${successInfo.totalDevices} device(s)), but delivery failed. Device registration tokens may be expired or invalid.`
              ) : (
                'Broadcast completed. Currently 0 active devices are registered with announcements enabled.'
              )}
            </p>
          </div>
        </div>
      )}

      {/* Error Banner */}
      {errorMessage && (
        <div className="rounded-xl border border-red-500/20 bg-red-950/30 p-4 md:p-5 flex items-start gap-3 backdrop-blur-md animate-in fade-in slide-in-from-top-2 duration-300">
          <AlertCircle className="w-5 h-5 text-red-400 shrink-0 mt-0.5" />
          <div className="space-y-1">
            <h3 className="text-sm font-medium text-red-200">Delivery Notice</h3>
            <p className="text-xs text-red-300/80">{errorMessage}</p>
          </div>
        </div>
      )}

      {/* Main Composer Card */}
      <Card className="border-zinc-800/80 bg-zinc-950/60 backdrop-blur-xl shadow-2xl">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="space-y-1">
              <CardTitle className="text-lg text-zinc-100">Broadcast Composer</CardTitle>
              <CardDescription className="text-xs text-zinc-400">
                Pushes directly through Firebase Cloud Messaging to physical devices.
              </CardDescription>
            </div>
            <div className="hidden sm:flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-zinc-900 border border-zinc-800 text-[11px] text-zinc-400">
              <Sparkles className="w-3 h-3 text-blue-400" />
              <span>High Priority Delivery</span>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleOpenConfirm} className="space-y-5">
            {/* Title */}
            <div className="space-y-2">
              <div className="flex justify-between items-center">
                <Label htmlFor="title" className="text-xs font-medium text-zinc-300">Title</Label>
                <span className="text-[11px] text-zinc-500">{title.length}/100</span>
              </div>
              <Input
                id="title"
                placeholder="Enter announcement title"
                value={title}
                onChange={(e) => setTitle(e.target.value.slice(0, 100))}
                className="bg-zinc-900/60 border-zinc-800 text-zinc-100 placeholder:text-zinc-600 focus-visible:ring-blue-500 text-sm h-10"
                disabled={isSending}
              />
            </div>

            {/* Message */}
            <div className="space-y-2">
              <div className="flex justify-between items-center">
                <Label htmlFor="message" className="text-xs font-medium text-zinc-300">Message</Label>
                <span className="text-[11px] text-zinc-500">{message.length}/500</span>
              </div>
              <textarea
                id="message"
                rows={4}
                placeholder="Write your announcement..."
                value={message}
                onChange={(e) => setMessage(e.target.value.slice(0, 500))}
                className="w-full rounded-md border border-zinc-800 bg-zinc-900/60 px-3 py-2 text-sm text-zinc-100 placeholder:text-zinc-600 shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-500 disabled:opacity-50 resize-none"
                disabled={isSending}
              />
            </div>

            {/* Optional Deep Link */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label htmlFor="route" className="text-xs font-medium text-zinc-300 flex items-center gap-1.5">
                  <LinkIcon className="w-3 h-3 text-zinc-500" />
                  <span>Deep Link</span>
                  <span className="text-[10px] text-zinc-500 font-normal">(Optional)</span>
                </Label>
              </div>
              <Input
                id="route"
                placeholder="/today"
                value={route}
                onChange={(e) => setRoute(e.target.value)}
                className="bg-zinc-900/60 border-zinc-800 text-zinc-100 placeholder:text-zinc-600 focus-visible:ring-blue-500 text-sm h-10 font-mono text-xs"
                disabled={isSending}
              />
              <p className="text-[11px] text-zinc-500">
                Optional route to navigate to when the user taps the notification (e.g. <code className="text-zinc-400">/today</code>, <code className="text-zinc-400">/messages</code>).
              </p>
            </div>

            {/* Target Audience Notice */}
            <div className="rounded-lg bg-zinc-900/40 border border-zinc-800/60 p-3.5 flex items-center gap-3">
              <Users className="w-4 h-4 text-zinc-400 shrink-0" />
              <div className="text-xs text-zinc-400">
                <span className="text-zinc-300 font-medium">Recipients: </span>
                All users with Announcements enabled
              </div>
            </div>

            {/* Submit Button */}
            <div className="pt-2 flex justify-end">
              <Button
                type="submit"
                disabled={isSending || !title.trim() || !message.trim()}
                className="bg-blue-600 hover:bg-blue-500 text-white font-medium text-sm px-6 h-10 shadow-lg shadow-blue-600/20 transition-all gap-2"
              >
                {isSending ? (
                  <>
                    <TrafficLoader size="sm" />
                    <span>Broadcasting...</span>
                  </>
                ) : (
                  <>
                    <Send className="w-4 h-4" />
                    <span>Send Announcement</span>
                  </>
                )}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      {/* Confirmation Dialog */}
      <Dialog open={isConfirmOpen} onOpenChange={setIsConfirmOpen}>
        <DialogContent className="border-zinc-800 bg-zinc-950 text-zinc-100 max-w-md">
          <DialogHeader>
            <div className="w-10 h-10 rounded-full bg-blue-500/10 border border-blue-500/20 flex items-center justify-center text-blue-400 mb-2">
              <Smartphone className="w-5 h-5" />
            </div>
            <DialogTitle className="text-lg">Send announcement?</DialogTitle>
            <DialogDescription className="text-xs text-zinc-400">
              This will send this notification to all FocusFlow users who have enabled Announcements &amp; Updates.
            </DialogDescription>
          </DialogHeader>

          {/* Preview Box */}
          <div className="rounded-lg border border-zinc-800 bg-zinc-900/70 p-4 space-y-2">
            <div className="text-[11px] uppercase tracking-wider text-zinc-500 font-semibold">Notification Preview</div>
            <div className="text-sm font-semibold text-zinc-100">{title}</div>
            <div className="text-xs text-zinc-300 whitespace-pre-wrap leading-relaxed">{message}</div>
            {route && (
              <div className="text-[11px] text-zinc-500 pt-1 font-mono">
                Tap action: {route}
              </div>
            )}
          </div>

          <DialogFooter className="gap-2 sm:gap-0">
            <Button
              type="button"
              variant="outline"
              onClick={() => setIsConfirmOpen(false)}
              disabled={isSending}
              className="border-zinc-800 text-zinc-300 hover:bg-zinc-900"
            >
              Cancel
            </Button>
            <Button
              type="button"
              onClick={handleSendAnnouncement}
              disabled={isSending}
              className="bg-blue-600 hover:bg-blue-500 text-white gap-2"
            >
              {isSending ? (
                <>
                  <TrafficLoader size="sm" />
                  <span>Sending...</span>
                </>
              ) : (
                <span>Send</span>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Recent Announcements Section */}
      <div className="space-y-4 pt-4 border-t border-zinc-900">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <History className="w-4 h-4 text-zinc-400" />
            <h2 className="text-sm font-medium text-zinc-200">Recent Announcements</h2>
          </div>
          <Button
            variant="ghost"
            size="sm"
            onClick={fetchRecent}
            disabled={isLoadingHistory}
            className="text-xs text-zinc-400 hover:text-zinc-200 h-8 gap-1.5"
          >
            <RefreshCw className={`w-3 h-3 ${isLoadingHistory ? 'animate-spin' : ''}`} />
            <span>Refresh</span>
          </Button>
        </div>

        {recentList.length === 0 ? (
          <div className="rounded-xl border border-dashed border-zinc-800/80 p-8 text-center">
            <p className="text-xs text-zinc-500">No announcements sent yet.</p>
          </div>
        ) : (
          <div className="space-y-2.5">
            {recentList.map((item) => (
              <div
                key={item.id}
                className="rounded-xl border border-zinc-800/60 bg-zinc-950/40 p-4 space-y-2 hover:border-zinc-800 transition-colors"
              >
                <div className="flex items-start justify-between gap-4">
                  <h4 className="text-sm font-medium text-zinc-200">{item.title}</h4>
                  <div className="flex items-center gap-2 shrink-0">
                    <span className="text-[11px] text-zinc-500 font-mono">
                      {item.createdAt ? new Date(item.createdAt).toLocaleDateString(undefined, {
                        month: 'short',
                        day: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit',
                      }) : ''}
                    </span>
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      onClick={() => handleRepeatAnnouncement(item)}
                      title="Repeat this announcement"
                      className="h-7 px-2 text-xs text-blue-400 hover:text-blue-300 hover:bg-blue-500/10 gap-1 border border-blue-500/20 rounded-md"
                    >
                      <RotateCw className="w-3 h-3" />
                      <span>Repeat</span>
                    </Button>
                  </div>
                </div>
                <p className="text-xs text-zinc-400 leading-relaxed">{item.message}</p>
                <div className="flex items-center gap-4 pt-1 text-[11px] text-zinc-500">
                  <span>
                    Delivered: <strong className="text-zinc-300 font-medium">{item.successCount}</strong> / {item.recipientCount}
                  </span>
                  {item.failureCount > 0 && (
                    <span className="text-red-400">Failed: {item.failureCount}</span>
                  )}
                  {item.route && (
                    <span className="font-mono text-zinc-400">Route: {item.route}</span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
