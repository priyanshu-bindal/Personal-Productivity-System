'use client'

import { useState } from "react"
import { Card, CardContent } from "@/components/ui/card"
import { Calendar } from "@/components/ui/calendar"
import { format } from "date-fns"

export default function CalendarClient() {
  const [date, setDate] = useState<Date | undefined>(new Date())

  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
      <div className="lg:col-span-4">
        <Card className="shadow-sm">
          <CardContent className="p-3">
            <Calendar
              mode="single"
              selected={date}
              onSelect={setDate}
              className="rounded-md mx-auto"
            />
          </CardContent>
        </Card>
      </div>
      
      <div className="lg:col-span-8">
        <Card className="min-h-[400px] shadow-sm">
          <CardContent className="p-6">
            <h2 className="text-xl font-semibold mb-6 pb-2 border-b">
              {date ? format(date, 'EEEE, MMMM do, yyyy') : 'Select a date'}
            </h2>
            
            <div className="space-y-4">
              <div className="py-12 text-center text-muted-foreground">
                <p>No tasks scheduled for this date.</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
