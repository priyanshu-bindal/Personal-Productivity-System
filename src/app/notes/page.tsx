import { Suspense } from "react"
import { getNotes, getSimpleSkills } from "@/lib/actions"
import { redirect } from "next/navigation"
import { NoteList } from "@/components/notes/NoteList"
import { NotesHeader } from "@/components/notes/NotesHeader"

import { getCurrentUser } from '@/lib/auth'

async function NotesContent() {
  const user = await getCurrentUser()
  if (!user) {
    redirect('/auth/signin')
  }

  const [notes, skills] = await Promise.all([
    getNotes(),
    getSimpleSkills()
  ])

  return (
    <div className="p-6 md:p-10 max-w-5xl mx-auto space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700 pb-24 md:pb-10">
      <NotesHeader skills={skills} />
      <NoteList notes={notes} skills={skills} />
    </div>
  )
}

import { TrafficLoader } from "@/components/ui/traffic-loader"

export default function NotesPage() {
  return (
    <Suspense fallback={<div className="p-10 flex justify-center items-center min-h-[40vh]"><TrafficLoader size="md" /></div>}>
      <NotesContent />
    </Suspense>
  )
}
