'use client'

import { useState, useTransition } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { StickyNote, Tag, MoreVertical, Edit2, Trash2, Search } from "lucide-react"
import { deleteNote } from '@/lib/actions'
import { EditNoteModal } from './NoteModals'

function getTagsArray(tags: any): string[] {
  if (!tags) return []
  if (Array.isArray(tags)) return tags.map(t => String(t).trim()).filter(Boolean)
  if (typeof tags === 'string') return tags.split(',').map(t => t.trim()).filter(Boolean)
  return []
}

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
    const tagsArr = getTagsArray(n.tags)
    const matchesTag = tagsArr.some(t => t.toLowerCase().includes(query))
    
    return n.title.toLowerCase().includes(query) || 
           n.content.toLowerCase().includes(query) || 
           matchesTag ||
           (n.skill && n.skill.name.toLowerCase().includes(query))
  })

  return (
    <div className="min-w-0 w-full">
      <div className="relative mb-6 min-w-0">
        <Search className="absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="Search notes by title, content, tags, or skill..."
          className="pl-9 text-xs sm:text-sm"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
        />
      </div>

      {filteredNotes.length === 0 ? (
        <div className="col-span-full py-12 text-center border-2 border-dashed rounded-xl p-4 min-w-0">
          <StickyNote className="h-8 w-8 sm:h-10 sm:w-10 text-muted-foreground mx-auto mb-3" />
          <h3 className="text-base sm:text-lg font-medium mb-1">No notes found</h3>
          <p className="text-xs sm:text-sm text-muted-foreground">
            {searchQuery ? "Try a different search term." : "Start documenting your learning journey."}
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6 min-w-0">
          {filteredNotes.map((note) => {
            const tagsList = getTagsArray(note.tags)

            return (
              <Card key={note.id} className="group hover:border-primary/50 transition-all hover:shadow-md flex flex-col min-w-0">
                <CardHeader className="p-4 pb-3 relative min-w-0">
                  <div className="flex items-start justify-between min-w-0">
                    <div className="flex flex-col gap-1.5 mb-1 pr-8 min-w-0">
                      <div className="flex items-center gap-1.5 min-w-0">
                        <StickyNote className="h-4 w-4 text-emerald-500 shrink-0" />
                        {note.skill && (
                          <span className="text-[11px] font-medium text-emerald-600 bg-emerald-500/10 px-2 py-0.5 rounded truncate">
                            {note.skill.name}
                          </span>
                        )}
                      </div>
                      <CardTitle className="text-base sm:text-lg line-clamp-1 truncate">{note.title}</CardTitle>
                    </div>
                    <DropdownMenu>
                      <DropdownMenuTrigger className="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring hover:bg-accent hover:text-accent-foreground absolute top-3 right-3 h-8 w-8 opacity-100 md:opacity-0 md:group-hover:opacity-100">
                        <MoreVertical className="h-4 w-4" />
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem onClick={() => setEditingNote(note)}>
                          <Edit2 className="h-4 w-4 mr-2" /> Edit Note
                        </DropdownMenuItem>
                        <DropdownMenuItem className="text-destructive focus:bg-destructive/10" onClick={() => handleDelete(note.id)}>
                          <Trash2 className="h-4 w-4 mr-2" /> Delete Note
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </div>
                </CardHeader>
                <CardContent className="p-4 pt-0 flex-1 flex flex-col min-w-0">
                  <p className="text-muted-foreground text-xs sm:text-sm line-clamp-4 flex-1 whitespace-pre-wrap break-words">
                    {note.content}
                  </p>
                  
                  {tagsList.length > 0 && (
                    <div className="flex items-center gap-2 mt-3 pt-3 border-t min-w-0">
                      <Tag className="h-3 w-3 text-muted-foreground shrink-0" />
                      <div className="flex flex-wrap gap-1 min-w-0">
                        {tagsList.map((tag, i) => (
                          <Badge key={i} variant="secondary" className="text-[10px] px-1.5 py-0">
                            {tag}
                          </Badge>
                        ))}
                      </div>
                    </div>
                  )}
                </CardContent>
              </Card>
            )
          })}
        </div>
      )}

      <EditNoteModal 
        note={editingNote} 
        isOpen={!!editingNote} 
        onClose={() => setEditingNote(null)} 
        skills={skills}
      />
    </div>
  )
}
