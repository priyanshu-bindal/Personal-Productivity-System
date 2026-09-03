'use client'

import { useState, Suspense } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card"
import { login } from "../actions"
import Link from "next/link"
import { useSearchParams } from "next/navigation"
import { AlertCircle } from "lucide-react"

function SignInContent() {
  const searchParams = useSearchParams()
  const urlError = searchParams.get('error')
  const [error, setError] = useState<string | null>(urlError)
  const [isLoading, setIsLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setIsLoading(true)
    setError(null)
    
    try {
      const formData = new FormData(e.currentTarget)
      const result = await login(formData)
      if (result?.error) {
        setError(result.error)
      }
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-muted/40 p-4 relative overflow-hidden">
      <div className="absolute inset-0 bg-grid-white/[0.02] bg-[size:32px_32px]" />
      <Card className="w-full max-w-md relative z-10 shadow-2xl border-primary/10">
        <CardHeader className="space-y-1 text-center pb-8">
          <CardTitle className="text-3xl font-bold tracking-tight">FocusFlow</CardTitle>
          <CardDescription className="text-base">
            Sign in to your account
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input 
                id="email" 
                name="email"
                type="email" 
                placeholder="you@domain.com" 
                required
                className="h-12"
              />
            </div>
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label htmlFor="password">Password</Label>
              </div>
              <Input 
                id="password" 
                name="password"
                type="password" 
                placeholder="••••••••"
                required
                className="h-12"
              />
            </div>
            
            {error && (
              <div className="text-sm text-destructive font-medium p-3 bg-destructive/10 border border-destructive/20 rounded-md flex items-center gap-2">
                <AlertCircle className="h-4 w-4 shrink-0" />
                <span>{error}</span>
              </div>
            )}

            <Button type="submit" className="w-full h-12 text-md font-medium" disabled={isLoading}>
              {isLoading ? "Signing in..." : "Sign In"}
            </Button>
          </form>
        </CardContent>
        <CardFooter className="flex flex-col gap-4 border-t p-6">
          <p className="text-sm text-center text-muted-foreground">
            Don&apos;t have an account? <Link href="/auth/signup" className="text-primary hover:underline">Sign up</Link>
          </p>
        </CardFooter>
      </Card>
    </div>
  )
}

import { TrafficLoader } from "@/components/ui/traffic-loader"

export default function SignIn() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center bg-muted/40 p-4">
        <TrafficLoader size="md" />
      </div>
    }>
      <SignInContent />
    </Suspense>
  )
}
