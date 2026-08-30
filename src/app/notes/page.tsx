import { Suspense } from "react"
import { createClient } from '@/lib/supabase/server'
import { getNotes, getSkills } from "@/lib/actions"
import { redirect } from "next/navigation"
import { NoteList } from "@/components/notes/NoteList"
import { NotesHeader } from "@/components/notes/NotesHeader"

async function NotesContent() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    redirect('/auth/signin')
  }

  const [notes, skills] = await Promise.all([
    getNotes(),
    getSkills()
  ])

  return (
    <div className="p-6 md:p-10 max-w-5xl mx-auto space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700 pb-24 md:pb-10">
      <NotesHeader skills={skills} />
      <NoteList notes={notes} skills={skills} />
    </div>
  )
}

export default function NotesPage() {
  return (
    <Suspense fallback={<div className="p-10 flex justify-center"><div className="animate-pulse h-8 w-32 bg-muted rounded"></div></div>}>
      <NotesContent />
    </Suspense>
  )
}
