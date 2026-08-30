'use server'

import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'

// --- SKILLS ---
export async function getSkills() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return []

  const { data, error } = await supabase
    .from('skills')
    .select('*, topics:skill_topics(*), learningSessions:learning_sessions(*), tasks:tasks(*)')
    .order('created_at', { ascending: false })

  if (error) {
    console.error('getSkills error:', error)
    return []
  }

  return (data || []).map(skill => {
    let computedProgress = skill.progress || 0
    if (skill.topics && skill.topics.length > 0) {
      computedProgress = Math.round(skill.topics.reduce((acc: number, t: any) => acc + (t.progress || 0), 0) / skill.topics.length)
    } else if (skill.tasks && skill.tasks.length > 0) {
      const completed = skill.tasks.filter((t: any) => t.status === 'completed').length
      computedProgress = Math.round((completed / skill.tasks.length) * 100)
    }

    return {
      ...skill,
      progress: computedProgress,
      weeklyTarget: skill.weekly_target,
      progressSource: skill.topics?.length > 0 ? 'Automatic' : 'Tasks',
      icon: 'BookOpen'
    }
  })
}

export async function getSkillById(id: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return null

  const { data, error } = await supabase
    .from('skills')
    .select('*, topics:skill_topics(*), learningSessions:learning_sessions(*)')
    .eq('id', id)
    .single()

  if (error || !data) return null

  return {
    ...data,
    weeklyTarget: data.weekly_target,
    progressSource: 'Manual',
    icon: 'BookOpen'
  }
}

export async function createSkill(data: any) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
  
  const { error } = await supabase.from('skills').insert({
    name: data.name,
    category: data.category,
    description: data.description,
    level: data.level,
    progress: data.progress || 0,
    target: data.target,
    weekly_target: data.weeklyTarget ? parseInt(data.weeklyTarget) : 0,
    user_id: user.id
  })
  
  if (error) {
    console.error('createSkill error:', error)
    throw new Error(error.message)
  }
  
  revalidatePath('/skills')
  revalidatePath('/')
}

export async function updateSkill(id: string, data: any) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
  
  const updateData: any = {}
  if (data.name !== undefined) updateData.name = data.name
  if (data.category !== undefined) updateData.category = data.category
  if (data.description !== undefined) updateData.description = data.description
  if (data.level !== undefined) updateData.level = data.level
  if (data.progress !== undefined) updateData.progress = data.progress
  if (data.target !== undefined) updateData.target = data.target
  if (data.weeklyTarget !== undefined) updateData.weekly_target = parseInt(data.weeklyTarget)
  
  const { error } = await supabase.from('skills').update(updateData).eq('id', id)
  
  if (error) {
    console.error('updateSkill error:', error)
    throw new Error(error.message)
  }
  
  revalidatePath('/skills')
  revalidatePath(`/skills/${id}`)
}

export async function deleteSkill(id: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
  
  const { error } = await supabase.from('skills').delete().eq('id', id)
  if (error) throw new Error(error.message)
  
  revalidatePath('/skills')
  revalidatePath('/')
}

// --- TOPICS ---
export async function createSkillTopic(skillId: string, name: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
    
  const { error } = await supabase.from('skill_topics').insert({
    skill_id: skillId,
    name,
    user_id: user.id
  })
  
  if (error) throw new Error(error.message)
  revalidatePath(`/skills/${skillId}`)
}

export async function updateTopicProgress(id: string, progress: number) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
    
  const { data, error } = await supabase
    .from('skill_topics')
    .update({ progress })
    .eq('id', id)
    .select('skill_id')
    .single()
    
  if (error) throw new Error(error.message)
  revalidatePath('/skills')
  if (data) revalidatePath(`/skills/${data.skill_id}`)
}

export async function deleteSkillTopic(id: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
  
  const { data } = await supabase.from('skill_topics').select('skill_id').eq('id', id).single()
  
  const { error } = await supabase.from('skill_topics').delete().eq('id', id)
  if (error) throw new Error(error.message)
  
  if (data) revalidatePath(`/skills/${data.skill_id}`)
}

// --- LEARNING SESSIONS ---
export async function addLearningSession(skillId: string, inputData: { duration: number, notes?: string, topics?: string }) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
    
  const { error } = await supabase.from('learning_sessions').insert({
    skill_id: skillId,
    duration_minutes: inputData.duration,
    notes: inputData.notes,
    user_id: user.id
  })
  
  if (error) throw new Error(error.message)
  
  revalidatePath('/skills')
  revalidatePath(`/skills/${skillId}`)
  revalidatePath('/')
}

// --- TASKS ---
export async function getTasks(dateRange?: { start: Date, end: Date }) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return []
  
  let query = supabase
    .from('tasks')
    .select('*, skill:skills(*)')
    .order('scheduled_date', { ascending: true, nullsFirst: true })
    
  if (dateRange) {
    query = query
      .gte('scheduled_date', dateRange.start.toISOString())
      .lte('scheduled_date', dateRange.end.toISOString())
  }
  
  const { data, error } = await query
  if (error) {
    console.error('getTasks error:', error)
    return []
  }
  
  const dbToFrontendStatus: Record<string, string> = {
    'not_started': 'Not Started',
    'in_progress': 'In Progress',
    'completed': 'Completed',
    'skipped': 'Skipped'
  }
  
  // Map snake_case to camelCase for the frontend
  return (data || []).map(t => ({
    ...t,
    status: dbToFrontendStatus[t.status] || t.status || 'Not Started',
    skillId: t.skill_id,
    goalId: t.goal_id,
    scheduledDate: t.scheduled_date ? new Date(t.scheduled_date) : null,
    scheduledTime: t.scheduled_time,
    duration: t.duration_minutes
  }))
}

export async function createTask(inputData: any) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")

  const { title, description, scheduledDate, duration, priority, skillId } = inputData

  const { error } = await supabase.from('tasks').insert({
    title,
    description: description || null,
    scheduled_date: scheduledDate ? new Date(scheduledDate).toISOString() : null,
    duration_minutes: typeof duration === 'number' ? duration : (duration ? parseInt(duration) : null),
    priority: priority?.toLowerCase() || 'medium',
    skill_id: skillId && skillId !== 'none' ? skillId : null,
    user_id: user.id,
  })
  
  if (error) {
    console.error('createTask error:', error)
    throw new Error(error.message)
  }
  
  revalidatePath('/tasks')
  revalidatePath('/calendar')
  revalidatePath('/')
}

export async function updateTaskStatus(id: string, status: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
  
  let dbStatus = 'not_started'
  if (status === 'In Progress') dbStatus = 'in_progress'
  else if (status === 'Completed') dbStatus = 'completed'
  else if (status === 'Skipped') dbStatus = 'skipped'
  
  const { error } = await supabase.from('tasks').update({ status: dbStatus }).eq('id', id)
  if (error) throw new Error(error.message)
  
  revalidatePath('/tasks')
  revalidatePath('/')
}

export async function updateTask(id: string, inputData: any) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")

  const { title, description, scheduledDate, duration, priority, skillId } = inputData

  const { error } = await supabase.from('tasks').update({
    title,
    description: description || null,
    scheduled_date: scheduledDate ? new Date(scheduledDate).toISOString() : null,
    duration_minutes: duration ? parseInt(duration) : null,
    priority: priority?.toLowerCase() || 'medium',
    skill_id: skillId && skillId !== 'none' ? skillId : null,
  }).eq('id', id)
  
  if (error) throw new Error(error.message)
  
  revalidatePath('/tasks')
  revalidatePath('/calendar')
  revalidatePath('/')
}

export async function deleteTask(id: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
  
  const { error } = await supabase.from('tasks').delete().eq('id', id)
  if (error) throw new Error(error.message)
  
  revalidatePath('/tasks')
  revalidatePath('/calendar')
  revalidatePath('/')
}

export async function getProgressStats() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return null

  const [
    { count: tasksCompleted }, 
    { count: totalTasks }, 
    { data: sessions }, 
    { count: totalSkills }
  ] = await Promise.all([
    supabase.from('tasks').select('*', { count: 'exact', head: true }).eq('status', 'completed'),
    supabase.from('tasks').select('*', { count: 'exact', head: true }),
    supabase.from('learning_sessions').select('duration_minutes'),
    supabase.from('skills').select('*', { count: 'exact', head: true })
  ])

  const totalLearningMinutes = (sessions || []).reduce((acc, s) => acc + (s.duration_minutes || 0), 0)
  const streak = (sessions?.length || 0) > 0 ? 3 : 0 // Mock streak

  return {
    tasksCompleted: tasksCompleted || 0,
    totalTasks: totalTasks || 0,
    learningHours: Math.round((totalLearningMinutes / 60) * 10) / 10,
    streak,
    totalSkills: totalSkills || 0
  }
}

export async function getDailyLoad(dateString: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return 0
  
  const start = new Date(dateString)
  start.setHours(0, 0, 0, 0)
  const end = new Date(dateString)
  end.setHours(23, 59, 59, 999)
  
  const { data } = await supabase
    .from('tasks')
    .select('duration_minutes')
    .gte('scheduled_date', start.toISOString())
    .lte('scheduled_date', end.toISOString())
  
  return (data || []).reduce((acc, t) => acc + (t.duration_minutes || 0), 0)
}

// --- WEEKLY PLANS ---
export async function getWeeklyPlans() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return []
  
  const { data } = await supabase.from('weekly_plans').select('*')
  return (data || []).map(p => ({
    ...p,
    dayOfWeek: p.week_start
  }))
}

export async function updateWeeklyPlans(plans: { dayOfWeek: string, skillId: string, duration: number }[]) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
  
  await supabase.from('weekly_plans').delete().neq('id', '00000000-0000-0000-0000-000000000000') // clear all
  
  // Note: the schema doesn't perfectly match the frontend array yet.
  revalidatePath('/')
  revalidatePath('/progress')
}

// --- GOALS & NOTES ---
export async function getGoals() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return []
  
  const { data, error } = await supabase
    .from('goals')
    .select('*, milestones(*), tasks(*)')
    .order('created_at', { ascending: false })
    
  if (error) {
    console.error('getGoals error:', error)
    return []
  }

  return (data || []).map(goal => {
    let computedProgress = goal.progress || 0
    if (goal.milestones && goal.milestones.length > 0) {
      const completed = goal.milestones.filter((m: any) => m.completed).length
      computedProgress = Math.round((completed / goal.milestones.length) * 100)
    } else if (goal.tasks && goal.tasks.length > 0) {
      const completed = goal.tasks.filter((t: any) => t.status === 'completed').length
      computedProgress = Math.round((completed / goal.tasks.length) * 100)
    }

    return {
      ...goal,
      progress: computedProgress
    }
  })
}

export async function getNotes() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return []
  
  const { data } = await supabase
    .from('notes')
    .select('*, skill:skills(*)')
    .order('created_at', { ascending: false })
    
  return (data || []).map(n => ({
    ...n,
    skillId: n.skill_id
  }))
}

export async function createNote(inputData: any) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
    
  const { error } = await supabase.from('notes').insert({
    title: inputData.title,
    content: inputData.content,
    tags: inputData.tags ? inputData.tags.split(',').map((t: string) => t.trim()) : [],
    skill_id: inputData.skillId && inputData.skillId !== 'none' ? inputData.skillId : null,
    user_id: user.id
  })
  
  if (error) throw new Error(error.message)
  revalidatePath('/notes')
}

export async function updateNote(id: string, inputData: any) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
  
  const updatePayload: any = {
    title: inputData.title,
    content: inputData.content,
  }
  if (inputData.tags !== undefined) {
    updatePayload.tags = inputData.tags ? inputData.tags.split(',').map((t: string) => t.trim()) : []
  }
  if (inputData.skillId !== undefined) {
    updatePayload.skill_id = inputData.skillId && inputData.skillId !== 'none' ? inputData.skillId : null
  }
  
  const { error } = await supabase.from('notes').update(updatePayload).eq('id', id)
  if (error) throw new Error(error.message)
  revalidatePath('/notes')
}

export async function deleteNote(id: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
  
  const { error } = await supabase.from('notes').delete().eq('id', id)
  if (error) throw new Error(error.message)
  revalidatePath('/notes')
}

export async function createGoal(inputData: any) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
  
  const { error } = await supabase.from('goals').insert({
    title: inputData.title,
    description: inputData.target || null,
    deadline: inputData.deadline ? new Date(inputData.deadline).toISOString() : null,
    user_id: user.id
  })
  
  if (error) throw new Error(error.message)
  revalidatePath('/goals')
  revalidatePath('/')
}

export async function updateGoal(id: string, inputData: any) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
  
  const { error } = await supabase.from('goals').update({
    title: inputData.title,
    description: inputData.target || null,
    deadline: inputData.deadline ? new Date(inputData.deadline).toISOString() : null,
  }).eq('id', id)
  
  if (error) throw new Error(error.message)
  revalidatePath('/goals')
  revalidatePath('/')
}

export async function deleteGoal(id: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
  
  const { error } = await supabase.from('goals').delete().eq('id', id)
  if (error) throw new Error(error.message)
  revalidatePath('/goals')
  revalidatePath('/')
}

export async function createMilestone(goalId: string, title: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
  
  const { error } = await supabase.from('milestones').insert({
    goal_id: goalId,
    title,
    user_id: user.id
  })
  
  if (error) throw new Error(error.message)
  revalidatePath('/goals')
}

export async function toggleMilestone(id: string, completed: boolean) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
  
  const { data: m, error: mError } = await supabase.from('milestones').update({ completed }).eq('id', id).select('goal_id').single()
  
  if (mError) throw new Error(mError.message)
  
  if (m) {
    const { data: allMilestones } = await supabase.from('milestones').select('*').eq('goal_id', m.goal_id)
    if (allMilestones && allMilestones.length > 0) {
      const completedCount = allMilestones.filter((x: any) => x.completed).length
      const progress = Math.round((completedCount / allMilestones.length) * 100)
      await supabase.from('goals').update({ progress }).eq('id', m.goal_id)
    }
  }
  
  revalidatePath('/goals')
}

export async function deleteMilestone(id: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
  
  const { data: m, error: selectError } = await supabase.from('milestones').select('goal_id').eq('id', id).single()
  if (selectError) throw new Error(selectError.message)
  
  if (m) {
    const { error: delError } = await supabase.from('milestones').delete().eq('id', id)
    if (delError) throw new Error(delError.message)
    
    const { data: allMilestones } = await supabase.from('milestones').select('*').eq('goal_id', m.goal_id)
    const progress = (allMilestones && allMilestones.length > 0)
      ? Math.round((allMilestones.filter((x: any) => x.completed).length / allMilestones.length) * 100)
      : 0
    await supabase.from('goals').update({ progress }).eq('id', m.goal_id)
  }
  
  revalidatePath('/goals')
}