'use client'

import { useState, useEffect } from 'react'
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
  CheckCircle2
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
    { id: 'practice', label: 'Practice Preferences', icon: Clock },
    { id: 'notifications', label: 'Notifications', icon: Bell },
    { id: 'data', label: 'Data & Privacy', icon: ShieldCheck },
    { id: 'danger', label: 'Danger Zone', icon: AlertTriangle },
  ] as const

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <header className="border-b pb-6">
        <h1 className="text-3xl md:text-4xl font-bold tracking-tight">Settings</h1>
        <p className="text-muted-foreground text-base md:text-lg mt-1">
          Manage your account and app preferences.
        </p>
      </header>

      <div className="grid grid-cols-1 md:grid-cols-12 gap-8">
        {/* Desktop Left Nav Tabs */}
        <nav className="md:col-span-4 lg:col-span-3 space-y-1">
          {tabs.map((tab) => {
            const Icon = tab.icon
            const isActive = activeTab === tab.id
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-colors text-left ${
                  isActive 
                    ? 'bg-primary text-primary-foreground font-semibold shadow-sm' 
                    : 'text-muted-foreground hover:bg-muted hover:text-foreground'
                } ${tab.id === 'danger' && !isActive ? 'hover:text-destructive' : ''}`}
              >
                <Icon className="h-4 w-4 shrink-0" />
                <span>{tab.label}</span>
              </button>
            )
          })}
        </nav>

        {/* Content Area */}
        <div className="md:col-span-8 lg:col-span-9 space-y-6">
          
          {/* ACCOUNT SECTION */}
          {activeTab === 'account' && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <User className="h-5 w-5 text-primary" /> Profile Details
                </CardTitle>
                <CardDescription>Update your personal information and display name.</CardDescription>
              </CardHeader>

              <form onSubmit={handleSaveAccount}>
                <CardContent className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="email">Email Address</Label>
                    <Input id="email" value={initialProfile.email} disabled className="bg-muted opacity-75 cursor-not-allowed" />
                    <p className="text-xs text-muted-foreground">Your email is managed by your authentication provider.</p>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="fullName">Display Name</Label>
                    <Input 
                      id="fullName" 
                      value={fullName} 
                      onChange={e => setFullName(e.target.value)} 
                      placeholder="Your Full Name" 
                      required 
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="avatarUrl">Avatar Image URL (Optional)</Label>
                    <Input 
                      id="avatarUrl" 
                      value={avatarUrl} 
                      onChange={e => setAvatarUrl(e.target.value)} 
                      placeholder="https://example.com/avatar.jpg" 
                    />
                  </div>
                </CardContent>

                <CardFooter className="flex flex-col sm:flex-row gap-3 justify-between border-t pt-4">
                  <Button 
                    type="button" 
                    variant="outline" 
                    onClick={() => setIsPasswordModalOpen(true)}
                    className="gap-2 shrink-0"
                  >
                    <KeyRound className="h-4 w-4" /> Change Password
                  </Button>

                  <Button type="submit" disabled={isSavingAccount} className="min-w-[130px]">
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
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Clock className="h-5 w-5 text-primary" /> Practice Preferences
                </CardTitle>
                <CardDescription>Customize your default learning session durations and workflow.</CardDescription>
              </CardHeader>

              <form onSubmit={handleSavePracticePreferences}>
                <CardContent className="space-y-6">
                  <div className="space-y-2">
                    <Label>Default Session Duration</Label>
                    <Select value={sessionDuration} onValueChange={(val) => val && setSessionDuration(val)}>
                      <SelectTrigger className="w-full sm:w-[260px]">
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

                  <div className="space-y-2 pt-2 border-t">
                    <Label className="text-base font-semibold">Weekly Planning Strategy</Label>
                    <div className="p-4 border rounded-xl bg-muted/20 space-y-1">
                      <div className="font-medium text-sm text-foreground">Use My Skill Schedules</div>
                      <p className="text-xs text-muted-foreground">
                        FocusFlow automatically schedules daily learning sessions based on your preferred practice days per skill.
                      </p>
                    </div>
                  </div>
                </CardContent>

                <CardFooter className="border-t pt-4 flex justify-end">
                  <Button type="submit" disabled={isSavingPreferences} className="min-w-[140px]">
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
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Bell className="h-5 w-5 text-primary" /> Notifications
                </CardTitle>
                <CardDescription>Manage practice reminders and alert preferences.</CardDescription>
              </CardHeader>

              <CardContent className="space-y-6">
                <div className="flex items-center justify-between p-4 border rounded-xl bg-card">
                  <div className="space-y-0.5">
                    <p className="font-medium text-sm">Daily Practice Reminders</p>
                    <p className="text-xs text-muted-foreground">Receive reminders for scheduled learning sessions.</p>
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
                  <div className="space-y-2 p-4 border rounded-xl bg-muted/20">
                    <Label htmlFor="reminderTime">Daily Reminder Time</Label>
                    <Input 
                      id="reminderTime" 
                      type="time" 
                      value={dailyReminderTime} 
                      onChange={e => {
                        setDailyReminderTime(e.target.value)
                        updatePreferences({ dailyReminderTime: e.target.value }).catch(console.error)
                      }} 
                      className="w-[180px]"
                    />
                  </div>
                )}
              </CardContent>
            </Card>
          )}

          {/* DATA & PRIVACY SECTION */}
          {activeTab === 'data' && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <ShieldCheck className="h-5 w-5 text-emerald-500" /> Data & Privacy
                </CardTitle>
                <CardDescription>Your skills, learning sessions, notes, and expenses belong entirely to your account.</CardDescription>
              </CardHeader>

              <CardContent className="space-y-6">
                <div className="p-4 border rounded-xl bg-muted/20 space-y-2">
                  <p className="text-sm font-medium">Account Owner</p>
                  <p className="text-xs text-muted-foreground">Signed in as: <span className="font-semibold text-foreground">{initialProfile.email}</span></p>
                </div>

                <div className="space-y-3 pt-2">
                  <h4 className="font-semibold text-sm">Export Data Backup</h4>
                  <p className="text-xs text-muted-foreground">
                    Download a full copy of your skills, learning history, expenses, notes, and goals in standard JSON format.
                  </p>
                  <Button onClick={handleExportData} disabled={isExporting} variant="outline" className="gap-2">
                    {isExporting ? <TrafficLoader size="sm" /> : <Download className="h-4 w-4" />}
                    Export My Data (JSON)
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}

          {/* DANGER ZONE SECTION */}
          {activeTab === 'danger' && (
            <Card className="border-destructive/40 bg-destructive/5">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-destructive">
                  <AlertTriangle className="h-5 w-5" /> Danger Zone
                </CardTitle>
                <CardDescription>Irreversible actions for your FocusFlow account.</CardDescription>
              </CardHeader>

              <CardContent className="space-y-6">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between p-4 border border-destructive/20 rounded-xl bg-card gap-4">
                  <div>
                    <p className="font-semibold text-sm">Sign Out of Account</p>
                    <p className="text-xs text-muted-foreground">Sign out of your active session on this device.</p>
                  </div>
                  <form action={signout}>
                    <Button type="submit" variant="outline" className="gap-2 shrink-0">
                      <LogOut className="h-4 w-4" /> Sign Out
                    </Button>
                  </form>
                </div>

                <div className="flex flex-col sm:flex-row sm:items-center justify-between p-4 border border-destructive/30 rounded-xl bg-destructive/10 gap-4">
                  <div>
                    <p className="font-semibold text-sm text-destructive">Delete FocusFlow Account Data</p>
                    <p className="text-xs text-muted-foreground">Permanently delete all skills, sessions, notes, expenses, and goals associated with your account.</p>
                  </div>
                  <Button 
                    variant="destructive" 
                    onClick={() => setIsDeleteModalOpen(true)}
                    className="shrink-0"
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
          <DialogContent className="sm:max-w-[400px]">
            <DialogHeader>
              <DialogTitle>Change Password</DialogTitle>
            </DialogHeader>

            <form onSubmit={handleChangePasswordSubmit} className="space-y-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="newPassword">New Password</Label>
                <Input 
                  id="newPassword" 
                  type="password" 
                  value={newPassword} 
                  onChange={e => setNewPassword(e.target.value)} 
                  minLength={6} 
                  required 
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="confirmPassword">Confirm New Password</Label>
                <Input 
                  id="confirmPassword" 
                  type="password" 
                  value={confirmPassword} 
                  onChange={e => setConfirmPassword(e.target.value)} 
                  minLength={6} 
                  required 
                />
              </div>

              <DialogFooter className="pt-4">
                <Button type="button" variant="outline" onClick={() => setIsPasswordModalOpen(false)} disabled={isChangingPassword}>
                  Cancel
                </Button>
                <Button type="submit" disabled={isChangingPassword || !newPassword || newPassword !== confirmPassword}>
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
          <DialogContent className="sm:max-w-[425px]">
            <DialogHeader>
              <DialogTitle className="text-destructive flex items-center gap-2">
                <AlertTriangle className="h-5 w-5" /> Permanently Delete Data
              </DialogTitle>
            </DialogHeader>

            <div className="space-y-4 py-4 text-sm">
              <p className="text-muted-foreground">
                This action <strong className="text-foreground">cannot be undone</strong>. All your tracked skills, practice sessions, financial expenses, notes, and goals will be permanently deleted.
              </p>

              <div className="space-y-2">
                <Label htmlFor="confirmDelete">Type <strong className="text-destructive font-mono">DELETE</strong> to confirm:</Label>
                <Input 
                  id="confirmDelete" 
                  value={deleteConfirmation} 
                  onChange={e => setDeleteConfirmation(e.target.value)} 
                  placeholder="DELETE" 
                />
              </div>
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => setIsDeleteModalOpen(false)} disabled={isDeletingAccount}>
                Cancel
              </Button>
              <Button 
                variant="destructive" 
                onClick={handleDeleteAccountSubmit} 
                disabled={isDeletingAccount || deleteConfirmation !== 'DELETE'}
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
