'use client'

import { Suspense } from 'react'
import { AuthExperience } from '@/components/auth/AuthExperience'
import { TrafficLoader } from '@/components/ui/traffic-loader'

export default function SignUp() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center bg-[#0A0A0B]">
          <TrafficLoader size="md" />
        </div>
      }
    >
      <AuthExperience initialMode="signup" />
    </Suspense>
  )
}
