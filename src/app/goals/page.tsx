import { Suspense } from "react"
import { createClient } from '@/lib/supabase/server'
import { getGoals } from "@/lib/actions"
import { redirect } from "next/navigation"
import { GoalList } from "@/components/goals/GoalList"
import { GoalsHeader } from "@/components/goals/GoalsHeader"

async function GoalsContent() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    redirect('/auth/signin')
  }

  const goals = await getGoals()

  return (
    <div className="p-6 md:p-10 max-w-5xl mx-auto space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700 pb-24 md:pb-10">
      <GoalsHeader />
      <GoalList goals={goals} />
    </div>
  )
}

export default function GoalsPage() {
  return (
    <Suspense fallback={<div className="p-10 flex justify-center"><div className="animate-pulse h-8 w-32 bg-muted rounded"></div></div>}>
      <GoalsContent />
    </Suspense>
  )
}
