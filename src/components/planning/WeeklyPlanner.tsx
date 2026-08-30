'use client'

import React, { useState, useEffect } from 'react'
import { DragDropContext, Droppable, Draggable } from '@hello-pangea/dnd'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { updateWeeklyPlans } from '@/lib/actions'
import { Save, GripVertical, Clock, CheckCircle2 } from 'lucide-react'
import * as Icons from 'lucide-react'

const DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']

export function WeeklyPlanner({ skills, initialPlans }: { skills: any[], initialPlans: any[] }) {
  const [columns, setColumns] = useState<Record<string, any[]>>({ unassigned: [] })
  const [isSaving, setIsSaving] = useState(false)
  const [isMounted, setIsMounted] = useState(false)
  const [isSaved, setIsSaved] = useState(false)

  useEffect(() => {
    setIsMounted(true)
    
    // Create unassigned skills
    const newCols: Record<string, any[]> = {
      unassigned: skills.map(s => ({ 
        uniqueId: `unassigned-${s.id}`,
        skillId: s.id,
        name: s.name,
        icon: s.icon,
        duration: 60 // Default duration
      }))
    }
    
    DAYS.forEach(day => {
      newCols[day] = []
    })

    // Populate from db
    initialPlans.forEach((plan, index) => {
      const skill = skills.find(s => s.id === plan.skillId)
      if (skill) {
        newCols[plan.dayOfWeek].push({
          uniqueId: `plan-${plan.id}-${index}`,
          skillId: skill.id,
          name: skill.name,
          icon: skill.icon,
          duration: plan.duration
        })
      }
    })

    setColumns(newCols)
  }, [skills, initialPlans])

  const onDragEnd = (result: any) => {
    const { source, destination } = result

    if (!destination) return

    const sourceId = source.droppableId
    const destId = destination.droppableId

    if (sourceId === destId) {
      // Reorder in same column
      const items = Array.from(columns[sourceId])
      const [reorderedItem] = items.splice(source.index, 1)
      items.splice(destination.index, 0, reorderedItem)

      setColumns({ ...columns, [sourceId]: items })
    } else {
      // Move between columns
      const sourceItems = Array.from(columns[sourceId])
      const destItems = Array.from(columns[destId])
      
      const [movedItem] = sourceItems.splice(source.index, 1)
      
      if (sourceId === 'unassigned') {
        // Clone from unassigned
        const newItem = { ...movedItem, uniqueId: `plan-${Math.random()}` }
        destItems.splice(destination.index, 0, newItem)
        sourceItems.splice(source.index, 0, movedItem) // Put original back
      } else {
        if (destId !== 'unassigned') {
          // Move day to day
          destItems.splice(destination.index, 0, movedItem)
        }
        // If dest is unassigned, it just gets deleted (removed from sourceItems)
      }

      setColumns({
        ...columns,
        [sourceId]: sourceItems,
        [destId]: destItems
      })
    }
    setIsSaved(false)
  }

  const handleSave = async () => {
    setIsSaving(true)
    const plansToSave: any[] = []
    
    DAYS.forEach(day => {
      columns[day].forEach(item => {
        plansToSave.push({
          dayOfWeek: day,
          skillId: item.skillId,
          duration: item.duration
        })
      })
    })

    try {
      await updateWeeklyPlans(plansToSave)
      setIsSaved(true)
      setTimeout(() => setIsSaved(false), 3000)
    } catch (err) {
      alert("Failed to save weekly plan.")
    } finally {
      setIsSaving(false)
    }
  }

  if (!isMounted) return null

  const getIcon = (name: string) => {
    // @ts-ignore
    const IconComponent = Icons[name] || Icons.Book
    return <IconComponent className="h-4 w-4" />
  }

  const renderDraggableCard = (item: any, index: number, isUnassigned = false) => (
    <Draggable key={item.uniqueId} draggableId={item.uniqueId} index={index}>
      {(provided, snapshot) => (
        <div
          ref={provided.innerRef}
          {...provided.draggableProps}
          {...provided.dragHandleProps}
          className={`mb-2 ${snapshot.isDragging ? 'opacity-70' : ''}`}
        >
          <Card className={`shadow-sm border border-border/50 ${isUnassigned ? 'bg-muted/50' : 'bg-card'}`}>
            <CardContent className="p-3 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <GripVertical className="h-4 w-4 text-muted-foreground cursor-grab active:cursor-grabbing" />
                <div className="w-6 h-6 rounded bg-primary/10 text-primary flex items-center justify-center">
                  {getIcon(item.icon)}
                </div>
                <span className="font-medium text-sm">{item.name}</span>
              </div>
              {!isUnassigned && (
                <div className="text-xs text-muted-foreground flex items-center gap-1 bg-muted px-2 py-1 rounded-md">
                  <Clock className="h-3 w-3" /> {item.duration}m
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      )}
    </Draggable>
  )

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-semibold tracking-tight">Weekly Routine</h2>
        <Button onClick={handleSave} disabled={isSaving} className="gap-2">
          {isSaved ? <CheckCircle2 className="h-4 w-4" /> : <Save className="h-4 w-4" />}
          {isSaving ? 'Saving...' : isSaved ? 'Saved!' : 'Save Plan'}
        </Button>
      </div>

      <DragDropContext onDragEnd={onDragEnd}>
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
          
          {/* Unassigned Skills (Library) */}
          <div className="lg:col-span-1">
            <div className="bg-muted/30 rounded-xl p-4 border h-[calc(100vh-250px)] overflow-y-auto">
              <h3 className="font-medium mb-4 text-muted-foreground uppercase text-xs tracking-wider">Your Skills (Drag to days)</h3>
              <Droppable droppableId="unassigned" isDropDisabled={true}>
                {(provided) => (
                  <div ref={provided.innerRef} {...provided.droppableProps} className="min-h-[100px]">
                    {columns.unassigned?.map((item, index) => renderDraggableCard(item, index, true))}
                    {provided.placeholder}
                  </div>
                )}
              </Droppable>
            </div>
          </div>

          {/* Days Grid */}
          <div className="lg:col-span-3">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
              {DAYS.map(day => {
                const totalMinutes = columns[day]?.reduce((acc, curr) => acc + curr.duration, 0) || 0
                const isOverloaded = totalMinutes > 180
                
                return (
                  <div key={day} className={`rounded-xl p-4 border h-[400px] flex flex-col ${isOverloaded ? 'border-amber-500/50 bg-amber-500/5' : 'bg-card'}`}>
                    <div className="flex items-center justify-between mb-4">
                      <h3 className="font-semibold">{day}</h3>
                      <span className={`text-xs px-2 py-1 rounded-full font-medium ${isOverloaded ? 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400' : 'bg-muted text-muted-foreground'}`}>
                        {Math.round(totalMinutes / 60 * 10)/10}h
                      </span>
                    </div>
                    
                    <Droppable droppableId={day}>
                      {(provided, snapshot) => (
                        <div 
                          ref={provided.innerRef} 
                          {...provided.droppableProps}
                          className={`flex-1 rounded-lg transition-colors p-2 -mx-2 ${snapshot.isDraggingOver ? 'bg-primary/5' : ''}`}
                        >
                          {columns[day]?.map((item, index) => renderDraggableCard(item, index))}
                          {provided.placeholder}
                          {columns[day]?.length === 0 && !snapshot.isDraggingOver && (
                            <div className="h-full flex items-center justify-center text-sm text-muted-foreground border-2 border-dashed rounded-lg border-muted/50">
                              Drop skills here
                            </div>
                          )}
                        </div>
                      )}
                    </Droppable>
                  </div>
                )
              })}
            </div>
          </div>

        </div>
      </DragDropContext>
    </div>
  )
}
