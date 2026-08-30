import { Suspense } from "react"
import { createClient } from '@/lib/supabase/server'
import { getSkills } from "@/lib/actions"
import { redirect } from "next/navigation"
import { SkillsClient } from "@/components/skills/SkillsClient"

async function SkillsPageContent() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    redirect('/auth/signin')
  }

  const skills = await getSkills()

  return (
    <div className="p-6 md:p-10 max-w-6xl mx-auto animate-in fade-in slide-in-from-bottom-4 duration-700">
      <SkillsClient initialSkills={skills} />
    </div>
  )
}

export default function SkillsPage() {
  return (
    <Suspense fallback={<div className="p-10 flex justify-center"><div className="animate-pulse h-8 w-32 bg-muted rounded"></div></div>}>
      <SkillsPageContent />
    </Suspense>
  )
}
