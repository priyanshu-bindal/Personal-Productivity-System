'use client'

import { useState } from "react"
import { useRouter } from "next/navigation"
import Link from "next/link"
import { AlertCircle, Loader2 } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card"
import { signup } from "../actions"

interface FieldErrors {
  fullName?: string
  email?: string
  password?: string
}

export default function SignUp() {
  const router = useRouter()
  const [fullName, setFullName] = useState("")
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")

  const [fieldErrors, setFieldErrors] = useState<FieldErrors>({})
  const [formError, setFormError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)

  const validateEmail = (val: string) => {
    if (!val.trim()) {
      return "Please enter your email address."
    }
    // Strict email regex requiring user@domain.tld format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(val.trim())) {
      return "Please enter a valid email address."
    }
    return undefined
  }

  const validatePassword = (val: string) => {
    if (!val) {
      return "Please enter a password."
    }
    if (val.length < 6) {
      return "Password must be at least 6 characters."
    }
    return undefined
  }

  const validateFullName = (val: string) => {
    if (!val.trim()) {
      return "Please enter your name."
    }
    return undefined
  }

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    if (isLoading) return

    setFormError(null)

    // Validate fields before submitting
    const errors: FieldErrors = {}
    const nameErr = validateFullName(fullName)
    const emailErr = validateEmail(email)
    const passErr = validatePassword(password)

    if (nameErr) errors.fullName = nameErr
    if (emailErr) errors.email = emailErr
    if (passErr) errors.password = passErr

    if (Object.keys(errors).length > 0) {
      setFieldErrors(errors)
      return;
    }

    setFieldErrors({})
    setIsLoading(true)

    try {
      const formData = new FormData()
      formData.append("full_name", fullName.trim())
      formData.append("email", email.trim())
      formData.append("password", password)

      const result = await signup(formData)

      if (result?.error) {
        setFormError(result.error)
        // If email already exists, highlight email field
        if (result.error.toLowerCase().includes("already exists") || result.error.toLowerCase().includes("sign in")) {
          setFieldErrors((prev) => ({
            ...prev,
            email: result.error,
          }))
        }
        setIsLoading(false)
      } else if (result?.success) {
        // Direct auto-login success: redirect directly to Dashboard/Today page
        window.location.href = "/"
      }
    } catch (err: any) {
      setFormError(err?.message || "An unexpected error occurred. Please try again.")
      setIsLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-muted/40 p-4 relative overflow-hidden">
      <div className="absolute inset-0 bg-grid-white/[0.02] bg-[size:32px_32px]" />
      <Card className="w-full max-w-md relative z-10 shadow-2xl border-primary/10">
        <CardHeader className="space-y-1 text-center pb-6">
          <CardTitle className="text-3xl font-bold tracking-tight">FocusFlow</CardTitle>
          <CardDescription className="text-base">
            Create a new account
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} noValidate className="space-y-4">
            {/* Full Name Field */}
            <div className="space-y-1.5">
              <Label htmlFor="full_name">Full Name</Label>
              <Input
                id="full_name"
                name="full_name"
                value={fullName}
                onChange={(e) => {
                  setFullName(e.target.value)
                  if (fieldErrors.fullName) {
                    setFieldErrors((prev) => ({ ...prev, fullName: undefined }))
                  }
                }}
                placeholder="Enter your full name"
                className={`h-12 ${fieldErrors.fullName ? "border-destructive focus-visible:ring-destructive" : ""}`}
                disabled={isLoading}
              />
              {fieldErrors.fullName && (
                <p className="text-xs text-destructive font-medium mt-1 flex items-center gap-1.5 animate-in fade-in slide-in-from-top-1">
                  <AlertCircle className="h-3.5 w-3.5 shrink-0" />
                  <span>{fieldErrors.fullName}</span>
                </p>
              )}
            </div>

            {/* Email Field */}
            <div className="space-y-1.5">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                name="email"
                type="email"
                value={email}
                onChange={(e) => {
                  setEmail(e.target.value)
                  if (fieldErrors.email) {
                    setFieldErrors((prev) => ({ ...prev, email: undefined }))
                  }
                }}
                placeholder="you@domain.com"
                className={`h-12 ${fieldErrors.email ? "border-destructive focus-visible:ring-destructive" : ""}`}
                disabled={isLoading}
              />
              {fieldErrors.email && (
                <p className="text-xs text-destructive font-medium mt-1 flex items-center gap-1.5 animate-in fade-in slide-in-from-top-1">
                  <AlertCircle className="h-3.5 w-3.5 shrink-0" />
                  <span>{fieldErrors.email}</span>
                </p>
              )}
            </div>

            {/* Password Field */}
            <div className="space-y-1.5">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                name="password"
                type="password"
                value={password}
                onChange={(e) => {
                  setPassword(e.target.value)
                  if (fieldErrors.password) {
                    setFieldErrors((prev) => ({ ...prev, password: undefined }))
                  }
                }}
                placeholder="••••••••"
                className={`h-12 ${fieldErrors.password ? "border-destructive focus-visible:ring-destructive" : ""}`}
                disabled={isLoading}
              />
              {fieldErrors.password && (
                <p className="text-xs text-destructive font-medium mt-1 flex items-center gap-1.5 animate-in fade-in slide-in-from-top-1">
                  <AlertCircle className="h-3.5 w-3.5 shrink-0" />
                  <span>{fieldErrors.password}</span>
                </p>
              )}
            </div>

            {/* Form Error Banner */}
            {formError && !fieldErrors.email?.includes("already exists") && (
              <div className="text-sm text-destructive font-medium p-3 bg-destructive/10 border border-destructive/20 rounded-md flex items-center gap-2 animate-in fade-in slide-in-from-top-1">
                <AlertCircle className="h-4 w-4 shrink-0" />
                <span>{formError}</span>
              </div>
            )}

            {/* Submit Button */}
            <Button type="submit" className="w-full h-12 text-md font-medium mt-2" disabled={isLoading}>
              {isLoading ? (
                <span className="flex items-center gap-2">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Creating Account...
                </span>
              ) : (
                "Create Account"
              )}
            </Button>
          </form>
        </CardContent>
        <CardFooter className="flex flex-col gap-4 border-t p-6">
          <p className="text-sm text-center text-muted-foreground">
            Already have an account?{" "}
            <Link href="/auth/signin" className="text-primary font-medium hover:underline">
              Sign in
            </Link>
          </p>
        </CardFooter>
      </Card>
    </div>
  )
}
