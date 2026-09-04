import { Suspense } from "react"
import { createClient } from '@/lib/supabase/server'
import { getTasks, getSkills } from "@/lib/actions"
import { redirect } from "next/navigation"
import { TaskListContent } from "@/components/tasks/TaskListContent"

import { getCurrentUser } from '@/lib/auth'

async function TasksContent() {
  const user = await getCurrentUser()
  if (!user) {
    redirect('/auth/signin')
  }

  const [allTasks, skills] = await Promise.all([
    getTasks(),
    getSkills()
  ])
  
  const completed = allTasks.filter(t => t.status === 'Completed')

  return (
    <div className="p-6 md:p-10 max-w-4xl mx-auto space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700 pb-24 md:pb-10">
      <header>
        <h1 className="text-3xl md:text-4xl font-bold tracking-tight">Tasks</h1>
        <p className="text-muted-foreground text-lg mt-2">
          {allTasks.length === 0 
            ? 'No tasks yet. Create one using the + button.'
            : `${allTasks.filter(t => t.status !== 'Completed').length} active, ${completed.length} completed`}
        </p>
      </header>

      <TaskListContent tasks={allTasks} skills={skills} />
    </div>
  )
}

import { TrafficLoader } from "@/components/ui/traffic-loader"

export default function TasksPage() {
  return (
    <Suspense fallback={<div className="p-10 flex justify-center items-center min-h-[40vh]"><TrafficLoader size="md" /></div>}>
      <TasksContent />
    </Suspense>
  )
}
