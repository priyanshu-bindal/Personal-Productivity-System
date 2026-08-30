'use client'

import { useState, useTransition } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { StickyNote, Tag, MoreVertical, Edit2, Trash2, Search } from "lucide-react"
import { deleteNote } from '@/lib/actions'
import { EditNoteModal } from './NoteModals'

export function NoteList({ notes, skills }: { notes: any[], skills: any[] }) {
  const [isPending, startTransition] = useTransition()
  const [editingNote, setEditingNote] = useState<any>(null)
  const [searchQuery, setSearchQuery] = useState('')

  const handleDelete = (id: string) => {
    if (confirm("Are you sure you want to delete this note?")) {
      startTransition(() => {
        deleteNote(id)
      })
    }
  }

  const filteredNotes = notes.filter(n => {
    const query = searchQuery.toLowerCase()
    return n.title.toLowerCase().includes(query) || 
           n.content.toLowerCase().includes(query) || 
           (n.tags && n.tags.toLowerCase().includes(query)) ||
           (n.skill && n.skill.name.toLowerCase().includes(query))
  })

  return (
    <>
      <div className="relative mb-6">
        <Search className="absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="Search notes by title, content, tags, or skill..."
          className="pl-9"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
        />
      </div>

      {filteredNotes.length === 0 ? (
        <div className="col-span-full py-12 text-center border-2 border-dashed rounded-xl">
          <StickyNote className="h-10 w-10 text-muted-foreground mx-auto mb-4" />
          <h3 className="text-lg font-medium mb-2">No notes found</h3>
          <p className="text-muted-foreground">
            {searchQuery ? "Try a different search term." : "Start documenting your learning journey."}
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredNotes.map((note) => (
            <Card key={note.id} className="group hover:border-primary/50 transition-all hover:shadow-md flex flex-col">
              <CardHeader className="pb-3 relative">
                <div className="flex items-start justify-between">
                  <div className="flex flex-col gap-2 mb-2 pr-8">
                    <div className="flex items-center gap-2">
                      <StickyNote className="h-4 w-4 text-emerald-500 shrink-0" />
                      {note.skill && (
                        <span className="text-xs font-medium text-emerald-600 bg-emerald-500/10 px-2 py-0.5 rounded truncate">
                          {note.skill.name}
                        </span>
                      )}
                    </div>
                    <CardTitle className="text-xl line-clamp-1">{note.title}</CardTitle>
                  </div>
                  <DropdownMenu>
                    <DropdownMenuTrigger className="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground absolute top-4 right-4 h-8 w-8 opacity-0 group-hover:opacity-100 transition-opacity">
                      <MoreVertical className="h-4 w-4" />
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuItem onClick={() => setEditingNote(note)}>
                        <Edit2 className="h-4 w-4 mr-2" /> Edit Note
                      </DropdownMenuItem>
                      <DropdownMenuItem className="text-destructive" onClick={() => handleDelete(note.id)}>
                        <Trash2 className="h-4 w-4 mr-2" /> Delete Note
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </div>
              </CardHeader>
              <CardContent className="flex-1 flex flex-col">
                <p className="text-muted-foreground text-sm line-clamp-4 flex-1 whitespace-pre-wrap">
                  {note.content}
                </p>
                
                {note.tags && (
                  <div className="flex items-center gap-2 mt-4 pt-4 border-t">
                    <Tag className="h-3 w-3 text-muted-foreground shrink-0" />
                    <div className="flex flex-wrap gap-1">
                      {note.tags.split(',').map((tag: string, i: number) => {
                        const trimmed = tag.trim()
                        if (!trimmed) return null
                        return (
                          <Badge key={i} variant="secondary" className="text-[10px] px-1.5 py-0">
                            {trimmed}
                          </Badge>
                        )
                      })}
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <EditNoteModal 
        note={editingNote} 
        isOpen={!!editingNote} 
        onClose={() => setEditingNote(null)} 
        skills={skills}
      />
    </>
  )
}
