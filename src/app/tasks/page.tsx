import { Suspense } from "react"
import { createClient } from '@/lib/supabase/server'
import { getTasks, getSkills } from "@/lib/actions"
import { redirect } from "next/navigation"
import { TaskListContent } from "@/components/tasks/TaskListContent"

async function TasksContent() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
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

export default function TasksPage() {
  return (
    <Suspense fallback={<div className="p-10 flex justify-center"><div className="animate-pulse h-8 w-32 bg-muted rounded"></div></div>}>
      <TasksContent />
    </Suspense>
  )
}
