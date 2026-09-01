import { Suspense } from "react"
import { createClient } from '@/lib/supabase/server'
import { getSkills } from "@/lib/actions"
import { redirect } from "next/navigation"
import { ProgressClient } from "@/components/planning/ProgressClient"

export const metadata = {
  title: 'Progress & Consistency | FocusFlow',
}

import { getCurrentUser } from '@/lib/auth'

async function ProgressContent() {
  const user = await getCurrentUser()
  if (!user) {
    redirect('/auth/signin')
  }

  const skills = await getSkills()

  return (
    <div className="p-4 md:p-10 max-w-6xl mx-auto space-y-8 pb-24 md:pb-10">
      <ProgressClient skills={skills} />
    </div>
  )
}

export default function ProgressPage() {
  return (
    <Suspense fallback={<div className="p-10 flex justify-center"><div className="animate-pulse h-8 w-32 bg-muted rounded"></div></div>}>
      <ProgressContent />
    </Suspense>
  )
}
