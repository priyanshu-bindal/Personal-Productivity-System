'use client'

import { Suspense } from 'react'
import { useSearchParams } from 'next/navigation'
import { AuthExperience } from '@/components/auth/AuthExperience'
import { TrafficLoader } from '@/components/ui/traffic-loader'

function SignInContent() {
  const searchParams = useSearchParams()
  const urlError = searchParams.get('error')

  return <AuthExperience initialMode="signin" initialError={urlError} />
}

export default function SignIn() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center bg-[#05070D]">
          <TrafficLoader size="md" />
        </div>
      }
    >
      <SignInContent />
    </Suspense>
  )
}
