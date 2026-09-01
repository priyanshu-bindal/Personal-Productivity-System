'use server'

import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'

import { getCurrentUser } from '@/lib/auth'

const DAY_NAMES = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']

export async function autoGenerateSessions(supabase: any, userId: string) {
  try {
    const { data: skills, error } = await supabase
      .from('skills')
      .select('*')
      .eq('user_id', userId)

    if (error || !skills || skills.length === 0) return

    const today = new Date()
    const sessionsToInsert: any[] = []

    // Generate sessions for past 7 days up to next 14 days
    for (let i = -7; i <= 14; i++) {
      const d = new Date()
      d.setDate(today.getDate() + i)
      const dayName = DAY_NAMES[d.getDay()]
      const dateStr = d.toISOString().split('T')[0]

      for (const skill of skills) {
        const prefDays = skill.preferred_days && Array.isArray(skill.preferred_days) && skill.preferred_days.length > 0
          ? skill.preferred_days
          : ['Monday', 'Wednesday', 'Friday']

        if (prefDays.includes(dayName)) {
          sessionsToInsert.push({
            user_id: userId,
            skill_id: skill.id,
            scheduled_date: dateStr,
            planned_duration: skill.session_duration || 60,
            duration_minutes: skill.session_duration || 60,
            status: 'planned'
          })
        }
      }
    }

    if (sessionsToInsert.length > 0) {
      await supabase
        .from('learning_sessions')
        .upsert(sessionsToInsert, { onConflict: 'user_id,skill_id,scheduled_date', ignoreDuplicates: true })
    }
  } catch (err) {
    console.warn('autoGenerateSessions catch:', err)
  }
}

// --- SKILLS ---
export async function getSimpleSkills() {
  const user = await getCurrentUser()
  if (!user) return []
  const supabase = await createClient()

  const { data, error } = await supabase
    .from('skills')
    .select('id, name')
    .eq('user_id', user.id)
    .order('name', { ascending: true })

  if (error) {
    console.error('getSimpleSkills error:', error)
    return []
  }

  return data || []
}

export async function getSkills() {
  const user = await getCurrentUser()
  if (!user) return []
  const supabase = await createClient()

  // Run in background so it doesn't block page navigation
  autoGenerateSessions(supabase, user.id).catch(e => console.warn('autoGen bg error:', e))

  const { data: skills, error } = await supabase
    .from('skills')
    .select('*, topics:skill_topics(*), learningSessions:learning_sessions(*)')
    .order('created_at', { ascending: false })

  if (error) {
    console.error('getSkills error:', error)
    return []
  }

  const todayStr = new Date().toISOString().split('T')[0]

  return (skills || []).map(skill => {
    const sessions: any[] = skill.learningSessions || []
    
    // Sort sessions by scheduled_date
    const pastAndTodaySessions = sessions.filter(s => s.scheduled_date <= todayStr)
    const completedSessions = sessions.filter(s => s.status === 'completed')
    
    // Today's session
    const todaySession = sessions.find(s => s.scheduled_date === todayStr)

    // Next scheduled session (in future)
    const futureSessions = sessions
      .filter(s => s.scheduled_date > todayStr && s.status === 'planned')
      .sort((a, b) => a.scheduled_date.localeCompare(b.scheduled_date))
    const nextSessionDate = futureSessions[0]?.scheduled_date || null

    // Weekly & Monthly calculations
    const now = new Date()
    const dayOfWeek = now.getDay() || 7 // 1 (Mon) - 7 (Sun)
    const monday = new Date(now)
    monday.setDate(now.getDate() - dayOfWeek + 1)
    const startOfWeekStr = monday.toISOString().split('T')[0]
    const sunday = new Date(monday)
    sunday.setDate(monday.getDate() + 6)
    const endOfWeekStr = sunday.toISOString().split('T')[0]

    const firstOfMonthStr = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split('T')[0]

    // Weekly Completed Count (this week)
    const thisWeekSessions = sessions.filter(s => s.scheduled_date >= startOfWeekStr && s.scheduled_date <= endOfWeekStr)
    const weeklyCompleted = thisWeekSessions.filter(s => s.status === 'completed').length

    const weeklyTarget = skill.weekly_target || (skill.preferred_days?.length) || 3

    // Overall Consistency: (completed planned sessions / total planned sessions up to today) * 100
    const totalPlannedUpToToday = pastAndTodaySessions.length
    const totalCompletedUpToToday = pastAndTodaySessions.filter(s => s.status === 'completed').length
    const consistencyPct = totalPlannedUpToToday > 0 
      ? Math.round((totalCompletedUpToToday / totalPlannedUpToToday) * 100) 
      : 100

    // Month Consistency
    const monthPastSessions = sessions.filter(s => s.scheduled_date >= firstOfMonthStr && s.scheduled_date <= todayStr)
    const monthCompletedCount = monthPastSessions.filter(s => s.status === 'completed').length
    const monthConsistencyPct = monthPastSessions.length > 0
      ? Math.round((monthCompletedCount / monthPastSessions.length) * 100)
      : 100

    // Streak Calculation (consecutive completed planned sessions)
    let streak = 0
    const sortedPast = [...pastAndTodaySessions].sort((a, b) => b.scheduled_date.localeCompare(a.scheduled_date))
    for (const s of sortedPast) {
      if (s.status === 'completed') {
        streak++
      } else if (s.status === 'skipped' || (s.status === 'planned' && s.scheduled_date < todayStr)) {
        break
      }
    }

    // Total learning time in minutes
    const totalMinutes = completedSessions.reduce((acc, s) => acc + (s.actual_duration || s.planned_duration || 60), 0)

    // Last practiced
    const lastCompleted = [...completedSessions].sort((a, b) => b.scheduled_date.localeCompare(a.scheduled_date))[0]
    const lastPracticedDate = lastCompleted?.scheduled_date || null

    return {
      ...skill,
      progress: skill.progress || 0,
      weeklyTarget,
      sessionDuration: skill.session_duration || 60,
      preferredDays: skill.preferred_days || ['Monday', 'Wednesday', 'Friday'],
      todaySession: todaySession ? {
        ...todaySession,
        plannedDuration: todaySession.planned_duration || 60,
        actualDuration: todaySession.actual_duration
      } : null,
      weeklyCompleted,
      consistencyPct,
      monthConsistencyPct,
      streak,
      totalMinutes,
      learningHours: Math.round((totalMinutes / 60) * 10) / 10,
      lastPracticedDate,
      nextSessionDate,
      icon: 'BookOpen'
    }
  })
}

export async function updateSkillProgress(id: string, progress: number) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")

  const clamped = Math.max(0, Math.min(100, Math.round(progress)))
  const { error } = await supabase.from('skills').update({ progress: clamped }).eq('id', id)

  if (error) throw new Error(error.message)

  revalidatePath('/skills')
  revalidatePath('/')
  revalidatePath('/progress')
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
    sessionDuration: data.session_duration || 60,
    preferredDays: data.preferred_days || ['Monday', 'Wednesday', 'Friday'],
    icon: 'BookOpen'
  }
}

export async function createSkill(data: any) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
  
  const preferredDays = data.preferredDays || ['Monday', 'Wednesday', 'Friday']
  const sessionDuration = data.sessionDuration ? parseInt(data.sessionDuration) : 60
  const weeklyTarget = data.weeklyTarget ? parseInt(data.weeklyTarget) : preferredDays.length

  const insertData: any = {
    name: data.name,
    category: data.category || 'Programming',
    description: data.description || null,
    level: data.level || 'Beginner',
    progress: 0,
    target: data.target || null,
    weekly_target: weeklyTarget,
    session_duration: sessionDuration,
    preferred_days: preferredDays,
    status: 'active',
    user_id: user.id
  }

  let { data: created, error } = await supabase.from('skills').insert(insertData).select().single()
  
  // Fallback if migration 002 isn't applied in Supabase yet
  if (error && (error.code === 'PGRST204' || error.message.includes('preferred_days') || error.message.includes('session_duration') || error.message.includes('status'))) {
    delete insertData.session_duration
    delete insertData.preferred_days
    delete insertData.status
    const fallbackRes = await supabase.from('skills').insert(insertData).select().single()
    created = fallbackRes.data
    error = fallbackRes.error
  }
  
  if (error) {
    console.error('createSkill error:', error)
    throw new Error(error.message)
  }
  
  // Fire-and-forget session generation — don't block the response
  autoGenerateSessions(supabase, user.id).catch(() => {})

  revalidatePath('/skills')
  revalidatePath('/')

  return { id: created?.id, name: data.name }
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
  if (data.sessionDuration !== undefined) updateData.session_duration = parseInt(data.sessionDuration)
  if (data.preferredDays !== undefined) updateData.preferred_days = data.preferredDays
  if (data.status !== undefined) updateData.status = data.status
  
  let { error } = await supabase.from('skills').update(updateData).eq('id', id)
  
  // Fallback if migration 002 isn't applied in Supabase yet
  if (error && (error.code === 'PGRST204' || error.message.includes('preferred_days') || error.message.includes('session_duration') || error.message.includes('status'))) {
    delete updateData.session_duration
    delete updateData.preferred_days
    delete updateData.status
    const fallbackRes = await supabase.from('skills').update(updateData).eq('id', id)
    error = fallbackRes.error
  }

  if (error) {
    console.error('updateSkill error:', error)
    throw new Error(error.message)
  }

  try {
    await autoGenerateSessions(supabase, user.id)
  } catch (e) {
    console.warn('autoGenerateSessions warning:', e)
  }
  
  revalidatePath('/skills')
  revalidatePath(`/skills/${id}`)
  revalidatePath('/')
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

// --- TODAY SESSIONS ---
export async function getTodaySessions() {
  const user = await getCurrentUser()
  if (!user) return []
  const supabase = await createClient()

  // Run in background so it doesn't block page navigation
  autoGenerateSessions(supabase, user.id).catch(e => console.warn('autoGen bg error:', e))

  const todayStr = new Date().toISOString().split('T')[0]

  const { data } = await supabase
    .from('learning_sessions')
    .select('*, skill:skills(*)')
    .eq('user_id', user.id)
    .eq('scheduled_date', todayStr)

  return (data || []).map(s => ({
    ...s,
    plannedDuration: s.planned_duration || s.skill?.session_duration || 60,
    actualDuration: s.actual_duration,
    scheduledDate: s.scheduled_date,
    completedAt: s.completed_at
  }))
}

export async function completeLearningSession(sessionId: string, actualDuration?: number, notes?: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")

  // Single update query — no need for a separate SELECT first
  const { data: updated, error } = await supabase
    .from('learning_sessions')
    .update({
      status: 'completed',
      completed_at: new Date().toISOString(),
      actual_duration: actualDuration || 60,
      notes: notes || null
    })
    .eq('id', sessionId)
    .select('*, skill:skills(name)')
    .single()

  if (error) throw new Error(error.message)

  revalidatePath('/')
  revalidatePath('/skills')

  return { skillName: updated?.skill?.name || 'Session', duration: updated?.actual_duration || 60 }
}

export async function skipLearningSession(sessionId: string) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")

  const { data: updated, error } = await supabase
    .from('learning_sessions')
    .update({ status: 'skipped' })
    .eq('id', sessionId)
    .select('*, skill:skills(name)')
    .single()

  if (error) throw new Error(error.message)

  revalidatePath('/')
  revalidatePath('/skills')

  return { skillName: updated?.skill?.name || 'Session' }
}

export async function getCalendarSessions(startDateStr: string, endDateStr: string) {
  const user = await getCurrentUser()
  if (!user) return []
  const supabase = await createClient()

  // Run in background so it doesn't block page navigation
  autoGenerateSessions(supabase, user.id).catch(e => console.warn('autoGen bg error:', e))

  const { data, error } = await supabase
    .from('learning_sessions')
    .select('*, skill:skills(id, name, category, level, session_duration)')
    .eq('user_id', user.id)
    .gte('scheduled_date', startDateStr)
    .lte('scheduled_date', endDateStr)
    .order('scheduled_date', { ascending: true })

  if (error) {
    console.error('getCalendarSessions error:', error)
    return []
  }

  return (data || []).map((s: any) => ({
    id: s.id,
    skillId: s.skill_id,
    skillName: s.skill?.name || 'Skill Practice',
    category: s.skill?.category || 'General',
    level: s.skill?.level || 'Beginner',
    scheduledDate: s.scheduled_date,
    plannedDuration: s.planned_duration || s.skill?.session_duration || 60,
    actualDuration: s.actual_duration,
    status: s.status || 'planned',
    notes: s.notes
  }))
}

export async function rescheduleLearningSession(sessionId: string, newDateStr: string) {
  const user = await getCurrentUser()
  if (!user) throw new Error("Unauthorized")
  const supabase = await createClient()

  const { error } = await supabase
    .from('learning_sessions')
    .update({ scheduled_date: newDateStr })
    .eq('id', sessionId)
    .eq('user_id', user.id)

  if (error) throw new Error(error.message)

  revalidatePath('/calendar')
  revalidatePath('/')
  revalidatePath('/skills')
  revalidatePath('/progress')
}

export async function getSkillHistory(skillId: string) {
  const user = await getCurrentUser()
  if (!user) return []
  const supabase = await createClient()

  const { data } = await supabase
    .from('learning_sessions')
    .select('*')
    .eq('user_id', user.id)
    .eq('skill_id', skillId)
    .in('status', ['completed', 'skipped'])
    .order('scheduled_date', { ascending: false })

  return data || []
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
    
  const todayStr = new Date().toISOString().split('T')[0]
  const nowIso = new Date().toISOString()

  const { error } = await supabase.from('learning_sessions').upsert({
    user_id: user.id,
    skill_id: skillId,
    scheduled_date: todayStr,
    planned_duration: inputData.duration || 60,
    actual_duration: inputData.duration || 60,
    duration_minutes: inputData.duration || 60,
    status: 'completed',
    completed_at: nowIso,
    notes: inputData.notes || null
  }, { onConflict: 'user_id,skill_id,scheduled_date' })
  
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
  
  const { data } = await supabase.from('weekly_plans').select('*').eq('user_id', user.id)
  return (data || []).map(p => ({
    ...p,
    dayOfWeek: p.week_start
  }))
}

export async function updateWeeklyPlans(plans: { dayOfWeek: string, skillId: string, duration: number }[]) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error("Unauthorized")
  
  await supabase.from('weekly_plans').delete().eq('user_id', user.id)
  
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
    .eq('user_id', user.id)
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
    .eq('user_id', user.id)
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