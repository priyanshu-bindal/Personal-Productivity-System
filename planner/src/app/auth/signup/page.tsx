'use client'

import { Suspense } from 'react'
import { AuthExperience } from '@/components/auth/AuthExperience'
import { TrafficLoader } from '@/components/ui/traffic-loader'

export default function SignUp() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center bg-[#05070D]">
          <TrafficLoader size="md" />
        </div>
      }
    >
      <AuthExperience initialMode="signup" />
    </Suspense>
  )
}
