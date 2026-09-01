'use client'

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card"
import { signup } from "../actions"
import Link from "next/link"
import { Mail, ArrowLeft, ExternalLink } from "lucide-react"

export default function SignUp() {
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [submittedEmail, setSubmittedEmail] = useState<string | null>(null)

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setIsLoading(true)
    setError(null)
    
    try {
      const formData = new FormData(e.currentTarget)
      const email = formData.get('email') as string
      const result = await signup(formData)
      if (result?.error) {
        setError(result.error)
      } else if (result?.success) {
        setSubmittedEmail(email)
      }
    } catch (err: any) {
      setError(err?.message || "An unexpected error occurred.")
    } finally {
      setIsLoading(false)
    }
  }

  // Dedicated "Check your email" screen after signup
  if (submittedEmail) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-muted/40 p-4 relative overflow-hidden">
        <div className="absolute inset-0 bg-grid-white/[0.02] bg-[size:32px_32px]" />
        <Card className="w-full max-w-md relative z-10 shadow-2xl border-primary/10 animate-in fade-in zoom-in-95 duration-300">
          <CardHeader className="space-y-3 text-center pb-4">
            <div className="mx-auto w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center text-primary">
              <Mail className="h-8 w-8" />
            </div>
            <CardTitle className="text-2xl font-bold tracking-tight">Check your email</CardTitle>
            <CardDescription className="text-sm">
              We&apos;ve sent a verification link to your email address.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4 text-center">
            <div className="p-3.5 bg-card border rounded-xl font-medium text-sm text-foreground break-all">
              {submittedEmail}
            </div>
            <p className="text-xs text-muted-foreground leading-relaxed">
              Verify your email to continue to FocusFlow. Once verified, you will be automatically redirected to your dashboard.
            </p>
          </CardContent>
          <CardFooter className="flex flex-col gap-2 border-t p-6">
            <a 
              href={`mailto:${submittedEmail}`}
              target="_blank"
              rel="noreferrer"
              className="w-full"
            >
              <Button className="w-full h-11 text-sm font-medium gap-2">
                Open Email App <ExternalLink className="h-4 w-4" />
              </Button>
            </a>
            <Link href="/auth/signin" className="w-full">
              <Button variant="ghost" className="w-full h-11 text-sm font-medium gap-2">
                <ArrowLeft className="h-4 w-4" /> Back to Sign In
              </Button>
            </Link>
          </CardFooter>
        </Card>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-muted/40 p-4 relative overflow-hidden">
      <div className="absolute inset-0 bg-grid-white/[0.02] bg-[size:32px_32px]" />
      <Card className="w-full max-w-md relative z-10 shadow-2xl border-primary/10">
        <CardHeader className="space-y-1 text-center pb-8">
          <CardTitle className="text-3xl font-bold tracking-tight">FocusFlow</CardTitle>
          <CardDescription className="text-base">
            Create a new account
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="full_name">Full Name</Label>
              <Input 
                id="full_name" 
                name="full_name"
                placeholder="Enter your full name" 
                required
                className="h-12"
              />
            </div>
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
              <Label htmlFor="password">Password</Label>
              <Input 
                id="password" 
                name="password"
                type="password" 
                placeholder="••••••••"
                required
                minLength={6}
                className="h-12"
              />
            </div>
            
            {error && (
              <div className="text-sm text-destructive font-medium p-3 bg-destructive/10 rounded-md">
                {error}
              </div>
            )}

            <Button type="submit" className="w-full h-12 text-md font-medium mt-2" disabled={isLoading}>
              {isLoading ? "Signing up..." : "Sign Up"}
            </Button>
          </form>
        </CardContent>
        <CardFooter className="flex flex-col gap-4 border-t p-6">
          <p className="text-sm text-center text-muted-foreground">
            Already have an account? <Link href="/auth/signin" className="text-primary hover:underline">Sign in</Link>
          </p>
        </CardFooter>
      </Card>
    </div>
  )
}
