import React from "react"
import { cn } from "@/lib/utils"

interface TrafficLoaderProps {
  size?: "sm" | "md" | "lg"
  className?: string
}

export function TrafficLoader({ size = "md", className }: TrafficLoaderProps) {
  const loaderClass = size === "sm" ? "traffic-loader-sm" : "traffic-loader"

  return (
    <div
      role="status"
      aria-label="Loading"
      className={cn(loaderClass, className)}
    />
  )
}
