'use client'

import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { useToast } from '@/components/ui/toast-provider'
import { 
  User, 
  Clock, 
  Bell, 
  ShieldCheck, 
  Download, 
  LogOut, 
  AlertTriangle, 
  KeyRound,
  MessageSquare,
  Copy,
  Check
} from 'lucide-react'
import { TrafficLoader } from '@/components/ui/traffic-loader'
import { 
  updateProfile, 
  updatePreferences, 
  changePassword, 
  exportUserData, 
  deleteAccountData 
} from '@/lib/settings-actions'
import { signout } from '@/app/auth/actions'
import { useRouter } from 'next/navigation'
import { useEffect } from 'react'
import { ensureFirebaseAuth } from '@/lib/firebase/authBridge'
import { ensureUserChatId } from '@/lib/firebase/chatService'

interface ProfileData {
  id: string
  email: string
  fullName: string
  avatarUrl: string
  defaultSessionDuration: number
  practiceReminders: boolean
  dailyReminderTime: string
}

export function SettingsClient({ initialProfile }: { initialProfile: ProfileData }) {
  const [activeTab, setActiveTab] = useState<'account' | 'practice' | 'notifications' | 'data' | 'danger'>('account')
  
  // Chat ID state
  const [chatId, setChatId] = useState<string | null>(null)
  const [isCopied, setIsCopied] = useState(false)

  useEffect(() => {
    async function loadChatId() {
      try {
        // ensureFirebaseAuth returns the Firebase bridge UID which must be used for Firestore paths
        // (Firestore rules check request.auth.uid, which is the Firebase UID, not the Supabase UID)
        const firebaseUid = await ensureFirebaseAuth(initialProfile.id, initialProfile.email)
        const id = await ensureUserChatId(firebaseUid)
        setChatId(id)
      } catch (err) {
        console.error('Failed to load Chat ID in settings:', err)
      }
    }
    loadChatId()
  }, [initialProfile.id, initialProfile.email])

  const handleCopyChatId = () => {
    if (!chatId) return
    navigator.clipboard.writeText(chatId)
    setIsCopied(true)
    setTimeout(() => setIsCopied(false), 2000)
  }
  
  // Account state
  const [fullName, setFullName] = useState(initialProfile.fullName)
  const [avatarUrl, setAvatarUrl] = useState(initialProfile.avatarUrl)
  const [isSavingAccount, setIsSavingAccount] = useState(false)
  
  // Password change dialog state
  const [isPasswordModalOpen, setIsPasswordModalOpen] = useState(false)
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [isChangingPassword, setIsChangingPassword] = useState(false)

  // Practice preferences state
  const [sessionDuration, setSessionDuration] = useState(initialProfile.defaultSessionDuration.toString())
  const [practiceReminders, setPracticeReminders] = useState(initialProfile.practiceReminders)
  const [dailyReminderTime, setDailyReminderTime] = useState(initialProfile.dailyReminderTime)
  const [isSavingPreferences, setIsSavingPreferences] = useState(false)

  // Export & Delete state
  const [isExporting, setIsExporting] = useState(false)
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false)
  const [deleteConfirmation, setDeleteConfirmation] = useState('')
  const [isDeletingAccount, setIsDeletingAccount] = useState(false)

  const { success, error: showError } = useToast()
  const router = useRouter()

  // Handle Account Save
  const handleSaveAccount = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSavingAccount(true)
    try {
      await updateProfile({ fullName, avatarUrl })
      success('Profile updated', 'Your account details have been saved.')
    } catch (err: any) {
      showError("Couldn't save profile", err.message || 'Please try again.')
    } finally {
      setIsSavingAccount(false)
    }
  }

  // Handle Password Change
  const handleChangePasswordSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (newPassword !== confirmPassword) {
      showError("Passwords don't match", "Please make sure both passwords match.")
      return
    }
    setIsChangingPassword(true)
    try {
      await changePassword(newPassword)
      success('Password changed', 'Your password has been updated securely.')
      setIsPasswordModalOpen(false)
      setNewPassword('')
      setConfirmPassword('')
    } catch (err: any) {
      showError("Password update failed", err.message || 'Please try again.')
    } finally {
      setIsChangingPassword(false)
    }
  }

  // Handle Practice Preferences Save
  const handleSavePracticePreferences = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSavingPreferences(true)
    try {
      await updatePreferences({
        defaultSessionDuration: parseInt(sessionDuration) || 60,
        practiceReminders,
        dailyReminderTime
      })
      success('Preferences saved', 'Default practice settings updated.')
    } catch (err: any) {
      showError("Couldn't save preferences", err.message || 'Please try again.')
    } finally {
      setIsSavingPreferences(false)
    }
  }

  // Handle Data Export
  const handleExportData = async () => {
    setIsExporting(true)
    try {
      const data = await exportUserData()
      const jsonString = `data:text/json;charset=utf-8,${encodeURIComponent(JSON.stringify(data, null, 2))}`
      const downloadAnchor = document.createElement('a')
      downloadAnchor.setAttribute('href', jsonString)
      downloadAnchor.setAttribute('download', `FocusFlow_Backup_${new Date().toISOString().split('T')[0]}.json`)
      document.body.appendChild(downloadAnchor)
      downloadAnchor.click()
      downloadAnchor.remove()
      success('Data exported', 'Your backup JSON file has been downloaded.')
    } catch (err: any) {
      showError("Export failed", err.message || 'Please try again.')
    } finally {
      setIsExporting(false)
    }
  }

  // Handle Account Deletion
  const handleDeleteAccountSubmit = async () => {
    if (deleteConfirmation !== 'DELETE') {
      showError('Confirmation mismatch', 'Please type DELETE to confirm.')
      return
    }
    setIsDeletingAccount(true)
    try {
      await deleteAccountData()
      success('Account deleted', 'Your account data has been removed.')
      router.push('/auth/signin')
    } catch (err: any) {
      showError("Deletion failed", err.message || 'Please try again.')
      setIsDeletingAccount(false)
    }
  }

  const tabs = [
    { id: 'account', label: 'Account', icon: User },
    { id: 'practice', label: 'Practice', icon: Clock },
    { id: 'notifications', label: 'Notifications', icon: Bell },
    { id: 'data', label: 'Data & Privacy', icon: ShieldCheck },
    { id: 'danger', label: 'Danger Zone', icon: AlertTriangle },
  ] as const

  return (
    <div className="space-y-6 sm:space-y-8 min-w-0 w-full animate-in fade-in slide-in-from-bottom-4 duration-500">
      <header className="border-b pb-6 min-w-0">
        <h1 className="text-2xl sm:text-3xl md:text-4xl font-bold tracking-tight">Settings</h1>
        <p className="text-muted-foreground text-xs sm:text-base md:text-lg mt-1">
          Manage your account and app preferences.
        </p>
      </header>

      <div className="grid grid-cols-1 md:grid-cols-12 gap-6 md:gap-8 min-w-0">
        {/* Mobile: Horizontal scrollable tab bar | Desktop: Left Nav */}
        <nav className="md:col-span-4 lg:col-span-3 flex overflow-x-auto gap-1.5 pb-2 scrollbar-none min-w-0 w-full md:flex-col md:space-y-1 md:overflow-x-visible md:pb-0">
          {tabs.map((tab) => {
            const Icon = tab.icon
            const isActive = activeTab === tab.id
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center gap-2 px-3 py-2 sm:px-4 sm:py-3 rounded-xl text-xs sm:text-sm font-medium transition-colors text-left shrink-0 md:w-full ${
                  isActive 
                    ? 'bg-primary text-primary-foreground font-semibold shadow-sm' 
                    : 'text-muted-foreground bg-card border md:border-transparent hover:bg-muted hover:text-foreground'
                } ${tab.id === 'danger' && !isActive ? 'hover:text-destructive' : ''}`}
              >
                <Icon className="h-3.5 w-3.5 sm:h-4 sm:w-4 shrink-0" />
                <span className="whitespace-nowrap">{tab.label}</span>
              </button>
            )
          })}
        </nav>

        {/* Content Area */}
        <div className="md:col-span-8 lg:col-span-9 space-y-6 min-w-0">
          
          {/* ACCOUNT SECTION */}
          {activeTab === 'account' && (
            <Card className="min-w-0">
              <CardHeader className="p-4 sm:p-6 pb-3">
                <CardTitle className="flex items-center gap-2 text-base sm:text-lg">
                  <User className="h-4 w-4 sm:h-5 sm:w-5 text-primary shrink-0" /> Profile Details
                </CardTitle>
                <CardDescription className="text-xs sm:text-sm">Update your personal information and display name.</CardDescription>
              </CardHeader>

              <form onSubmit={handleSaveAccount}>
                <CardContent className="p-4 sm:p-6 pt-0 space-y-4 min-w-0">
                  <div className="space-y-1.5">
                    <Label htmlFor="email" className="text-xs sm:text-sm">Email Address</Label>
                    <Input id="email" value={initialProfile.email} disabled className="bg-muted opacity-75 cursor-not-allowed text-xs sm:text-sm" />
                    <p className="text-[11px] text-muted-foreground">Your email is managed by your authentication provider.</p>
                  </div>

                  <div className="p-4 border rounded-xl bg-primary/5 border-primary/20 space-y-2">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <MessageSquare className="h-4 w-4 text-primary" />
                        <span className="text-xs sm:text-sm font-semibold">Your Chat ID</span>
                      </div>
                      {chatId && (
                        <Button 
                          type="button" 
                          variant="ghost" 
                          size="sm" 
                          onClick={handleCopyChatId}
                          className="h-8 gap-1.5 text-xs text-primary hover:text-primary hover:bg-primary/10"
                        >
                          {isCopied ? <Check className="h-3.5 w-3.5" /> : <Copy className="h-3.5 w-3.5" />}
                          {isCopied ? 'Copied' : 'Copy'}
                        </Button>
                      )}
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="font-mono text-lg font-bold tracking-widest text-primary">
                        {chatId || 'Loading...'}
                      </span>
                      <span className="text-[11px] text-muted-foreground">Share with others to start direct 1-to-1 chats</span>
                    </div>
                  </div>

                  <div className="space-y-1.5">
                    <Label htmlFor="fullName" className="text-xs sm:text-sm">Display Name</Label>
                    <Input 
                      id="fullName" 
                      value={fullName} 
                      onChange={e => setFullName(e.target.value)} 
                      placeholder="Your Full Name" 
                      required 
                      className="text-xs sm:text-sm"
                    />
                  </div>

                  <div className="space-y-1.5">
                    <Label htmlFor="avatarUrl" className="text-xs sm:text-sm">Avatar Image URL (Optional)</Label>
                    <Input 
                      id="avatarUrl" 
                      value={avatarUrl} 
                      onChange={e => setAvatarUrl(e.target.value)} 
                      placeholder="https://example.com/avatar.jpg" 
                      className="text-xs sm:text-sm"
                    />
                  </div>
                </CardContent>

                <CardFooter className="p-4 sm:p-6 flex flex-col sm:flex-row gap-2.5 justify-between border-t">
                  <Button 
                    type="button" 
                    variant="outline" 
                    onClick={() => setIsPasswordModalOpen(true)}
                    className="gap-2 text-xs sm:text-sm w-full sm:w-auto"
                  >
                    <KeyRound className="h-4 w-4" /> Change Password
                  </Button>

                  <Button type="submit" disabled={isSavingAccount} className="w-full sm:w-auto text-xs sm:text-sm">
                    {isSavingAccount ? (
                      <><TrafficLoader size="sm" className="mr-2" /> Saving...</>
                    ) : (
                      'Save Changes'
                    )}
                  </Button>
                </CardFooter>
              </form>
            </Card>
          )}

          {/* PRACTICE PREFERENCES SECTION */}
          {activeTab === 'practice' && (
            <Card className="min-w-0">
              <CardHeader className="p-4 sm:p-6 pb-3">
                <CardTitle className="flex items-center gap-2 text-base sm:text-lg">
                  <Clock className="h-4 w-4 sm:h-5 sm:w-5 text-primary shrink-0" /> Practice Preferences
                </CardTitle>
                <CardDescription className="text-xs sm:text-sm">Customize your default learning session durations and workflow.</CardDescription>
              </CardHeader>

              <form onSubmit={handleSavePracticePreferences}>
                <CardContent className="p-4 sm:p-6 pt-0 space-y-5 min-w-0">
                  <div className="space-y-1.5">
                    <Label className="text-xs sm:text-sm">Default Session Duration</Label>
                    <Select value={sessionDuration} onValueChange={(val) => val && setSessionDuration(val)}>
                      <SelectTrigger className="w-full sm:w-[260px] text-xs sm:text-sm">
                        <SelectValue placeholder="Select duration" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="30">30 minutes</SelectItem>
                        <SelectItem value="45">45 minutes</SelectItem>
                        <SelectItem value="60">60 minutes (1 hr)</SelectItem>
                        <SelectItem value="90">90 minutes (1.5 hrs)</SelectItem>
                        <SelectItem value="120">120 minutes (2 hrs)</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-1.5 pt-2 border-t">
                    <Label className="text-sm font-semibold">Weekly Planning Strategy</Label>
                    <div className="p-3.5 border rounded-xl bg-muted/20 space-y-1">
                      <div className="font-medium text-xs sm:text-sm text-foreground">Use My Skill Schedules</div>
                      <p className="text-[11px] sm:text-xs text-muted-foreground">
                        FocusFlow automatically schedules daily learning sessions based on your preferred practice days per skill.
                      </p>
                    </div>
                  </div>
                </CardContent>

                <CardFooter className="p-4 sm:p-6 border-t flex justify-end">
                  <Button type="submit" disabled={isSavingPreferences} className="w-full sm:w-auto text-xs sm:text-sm">
                    {isSavingPreferences ? (
                      <><TrafficLoader size="sm" className="mr-2" /> Saving...</>
                    ) : (
                      'Save Preferences'
                    )}
                  </Button>
                </CardFooter>
              </form>
            </Card>
          )}

          {/* NOTIFICATIONS SECTION */}
          {activeTab === 'notifications' && (
            <Card className="min-w-0">
              <CardHeader className="p-4 sm:p-6 pb-3">
                <CardTitle className="flex items-center gap-2 text-base sm:text-lg">
                  <Bell className="h-4 w-4 sm:h-5 sm:w-5 text-primary shrink-0" /> Notifications
                </CardTitle>
                <CardDescription className="text-xs sm:text-sm">Manage practice reminders and alert preferences.</CardDescription>
              </CardHeader>

              <CardContent className="p-4 sm:p-6 pt-0 space-y-4 min-w-0">
                <div className="flex items-center justify-between p-3.5 sm:p-4 border rounded-xl bg-card min-w-0 gap-3">
                  <div className="space-y-0.5 min-w-0">
                    <p className="font-medium text-xs sm:text-sm">Daily Practice Reminders</p>
                    <p className="text-[11px] sm:text-xs text-muted-foreground">Receive reminders for scheduled learning sessions.</p>
                  </div>
                  <button
                    type="button"
                    onClick={() => {
                      const next = !practiceReminders
                      setPracticeReminders(next)
                      updatePreferences({ practiceReminders: next }).catch(console.error)
                      success('Reminder updated', next ? 'Practice reminders enabled' : 'Practice reminders disabled')
                    }}
                    className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out ${
                      practiceReminders ? 'bg-primary' : 'bg-muted'
                    }`}
                  >
                    <span
                      className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow-lg ring-0 transition duration-200 ease-in-out ${
                        practiceReminders ? 'translate-x-5' : 'translate-x-0'
                      }`}
                    />
                  </button>
                </div>

                {practiceReminders && (
                  <div className="space-y-1.5 p-3.5 sm:p-4 border rounded-xl bg-muted/20 min-w-0">
                    <Label htmlFor="reminderTime" className="text-xs sm:text-sm">Daily Reminder Time</Label>
                    <Input 
                      id="reminderTime" 
                      type="time" 
                      value={dailyReminderTime} 
                      onChange={e => {
                        setDailyReminderTime(e.target.value)
                        updatePreferences({ dailyReminderTime: e.target.value }).catch(console.error)
                      }} 
                      className="w-full sm:w-[180px] text-xs sm:text-sm"
                    />
                  </div>
                )}
              </CardContent>
            </Card>
          )}

          {/* DATA & PRIVACY SECTION */}
          {activeTab === 'data' && (
            <Card className="min-w-0">
              <CardHeader className="p-4 sm:p-6 pb-3">
                <CardTitle className="flex items-center gap-2 text-base sm:text-lg">
                  <ShieldCheck className="h-4 w-4 sm:h-5 sm:w-5 text-emerald-500 shrink-0" /> Data & Privacy
                </CardTitle>
                <CardDescription className="text-xs sm:text-sm">Your skills, learning sessions, notes, and expenses belong entirely to your account.</CardDescription>
              </CardHeader>

              <CardContent className="p-4 sm:p-6 pt-0 space-y-4 min-w-0">
                <div className="p-3.5 sm:p-4 border rounded-xl bg-muted/20 space-y-1 min-w-0">
                  <p className="text-xs sm:text-sm font-medium">Account Owner</p>
                  <p className="text-xs text-muted-foreground truncate">Signed in as: <span className="font-semibold text-foreground">{initialProfile.email}</span></p>
                </div>

                <div className="space-y-2 pt-1 min-w-0">
                  <h4 className="font-semibold text-xs sm:text-sm">Export Data Backup</h4>
                  <p className="text-[11px] sm:text-xs text-muted-foreground">
                    Download a full copy of your skills, learning history, expenses, notes, and goals in standard JSON format.
                  </p>
                  <Button onClick={handleExportData} disabled={isExporting} variant="outline" className="gap-2 text-xs sm:text-sm w-full sm:w-auto">
                    {isExporting ? <TrafficLoader size="sm" /> : <Download className="h-4 w-4" />}
                    Export My Data (JSON)
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}

          {/* DANGER ZONE SECTION */}
          {activeTab === 'danger' && (
            <Card className="border-destructive/40 bg-destructive/5 min-w-0">
              <CardHeader className="p-4 sm:p-6 pb-3">
                <CardTitle className="flex items-center gap-2 text-destructive text-base sm:text-lg">
                  <AlertTriangle className="h-4 w-4 sm:h-5 sm:w-5 shrink-0" /> Danger Zone
                </CardTitle>
                <CardDescription className="text-xs sm:text-sm">Irreversible actions for your FocusFlow account.</CardDescription>
              </CardHeader>

              <CardContent className="p-4 sm:p-6 pt-0 space-y-4 min-w-0">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between p-3.5 sm:p-4 border border-destructive/20 rounded-xl bg-card gap-3 min-w-0">
                  <div className="min-w-0">
                    <p className="font-semibold text-xs sm:text-sm">Sign Out of Account</p>
                    <p className="text-[11px] sm:text-xs text-muted-foreground">Sign out of your active session on this device.</p>
                  </div>
                  <form action={signout} className="w-full sm:w-auto">
                    <Button type="submit" variant="outline" className="gap-2 text-xs sm:text-sm w-full sm:w-auto shrink-0">
                      <LogOut className="h-4 w-4" /> Sign Out
                    </Button>
                  </form>
                </div>

                <div className="flex flex-col sm:flex-row sm:items-center justify-between p-3.5 sm:p-4 border border-destructive/30 rounded-xl bg-destructive/10 gap-3 min-w-0">
                  <div className="min-w-0">
                    <p className="font-semibold text-xs sm:text-sm text-destructive">Delete FocusFlow Account Data</p>
                    <p className="text-[11px] sm:text-xs text-muted-foreground">Permanently delete all skills, sessions, notes, expenses, and goals associated with your account.</p>
                  </div>
                  <Button 
                    variant="destructive" 
                    onClick={() => setIsDeleteModalOpen(true)}
                    className="text-xs sm:text-sm w-full sm:w-auto shrink-0"
                  >
                    Delete Account Data
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}

        </div>
      </div>

      {/* Change Password Dialog */}
      {isPasswordModalOpen && (
        <Dialog open={isPasswordModalOpen} onOpenChange={setIsPasswordModalOpen}>
          <DialogContent className="sm:max-w-[400px] p-4 sm:p-6">
            <DialogHeader>
              <DialogTitle className="text-base sm:text-lg">Change Password</DialogTitle>
            </DialogHeader>

            <form onSubmit={handleChangePasswordSubmit} className="space-y-4 py-2 min-w-0">
              <div className="space-y-1.5 min-w-0">
                <Label htmlFor="newPassword" className="text-xs sm:text-sm">New Password</Label>
                <Input 
                  id="newPassword" 
                  type="password" 
                  value={newPassword} 
                  onChange={e => setNewPassword(e.target.value)} 
                  minLength={6} 
                  required 
                  className="text-xs sm:text-sm"
                />
              </div>

              <div className="space-y-1.5 min-w-0">
                <Label htmlFor="confirmPassword" className="text-xs sm:text-sm">Confirm New Password</Label>
                <Input 
                  id="confirmPassword" 
                  type="password" 
                  value={confirmPassword} 
                  onChange={e => setConfirmPassword(e.target.value)} 
                  minLength={6} 
                  required 
                  className="text-xs sm:text-sm"
                />
              </div>

              <DialogFooter className="pt-2 gap-2 flex flex-row justify-end">
                <Button type="button" variant="outline" size="sm" onClick={() => setIsPasswordModalOpen(false)} disabled={isChangingPassword} className="text-xs">
                  Cancel
                </Button>
                <Button type="submit" size="sm" disabled={isChangingPassword || !newPassword || newPassword !== confirmPassword} className="text-xs">
                  {isChangingPassword ? <TrafficLoader size="sm" className="mr-2" /> : 'Update Password'}
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      )}

      {/* Delete Account Confirmation Dialog */}
      {isDeleteModalOpen && (
        <Dialog open={isDeleteModalOpen} onOpenChange={setIsDeleteModalOpen}>
          <DialogContent className="sm:max-w-[425px] p-4 sm:p-6">
            <DialogHeader>
              <DialogTitle className="text-destructive flex items-center gap-2 text-base sm:text-lg">
                <AlertTriangle className="h-5 w-5 shrink-0" /> Permanently Delete Data
              </DialogTitle>
            </DialogHeader>

            <div className="space-y-3 py-2 text-xs sm:text-sm min-w-0">
              <p className="text-muted-foreground">
                This action <strong className="text-foreground">cannot be undone</strong>. All your tracked skills, practice sessions, financial expenses, notes, and goals will be permanently deleted.
              </p>

              <div className="space-y-1.5 min-w-0">
                <Label htmlFor="confirmDelete" className="text-xs sm:text-sm">Type <strong className="text-destructive font-mono">DELETE</strong> to confirm:</Label>
                <Input 
                  id="confirmDelete" 
                  value={deleteConfirmation} 
                  onChange={e => setDeleteConfirmation(e.target.value)} 
                  placeholder="DELETE" 
                  className="text-xs sm:text-sm"
                />
              </div>
            </div>

            <DialogFooter className="gap-2 flex flex-row justify-end pt-2">
              <Button variant="outline" size="sm" onClick={() => setIsDeleteModalOpen(false)} disabled={isDeletingAccount} className="text-xs">
                Cancel
              </Button>
              <Button 
                variant="destructive" 
                size="sm"
                onClick={handleDeleteAccountSubmit} 
                disabled={isDeletingAccount || deleteConfirmation !== 'DELETE'}
                className="text-xs"
              >
                {isDeletingAccount ? <TrafficLoader size="sm" className="mr-2" /> : 'Delete Everything'}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}
    </div>
  )
}
