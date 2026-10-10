'use client'

import React, { useEffect, useRef, useState } from 'react'
import { gsap } from 'gsap'

export interface TextTypeProps {
  text?: string | string[]
  texts?: string[]
  typingSpeed?: number
  deletingSpeed?: number
  pauseDuration?: number
  showCursor?: boolean
  cursorCharacter?: string
  cursorBlinkDuration?: number
  variableSpeedEnabled?: boolean
  variableSpeedMin?: number
  variableSpeedMax?: number
  className?: string
  cursorClassName?: string
  onComplete?: () => void
}

export default function TextType({
  text,
  texts,
  typingSpeed = 75,
  deletingSpeed = 50,
  pauseDuration = 1500,
  showCursor = true,
  cursorCharacter = '_',
  cursorBlinkDuration = 0.5,
  variableSpeedEnabled = false,
  variableSpeedMin = 60,
  variableSpeedMax = 120,
  className = '',
  cursorClassName = '',
  onComplete,
}: TextTypeProps) {
  // Normalize strings to type through
  const rawList = texts || (Array.isArray(text) ? text : text ? [text] : [])
  const list = rawList.length > 0 ? rawList : ['']

  const [displayedText, setDisplayedText] = useState('')
  const cursorRef = useRef<HTMLSpanElement>(null)
  const isMountedRef = useRef(true)

  // Blinking cursor with GSAP
  useEffect(() => {
    if (!showCursor || !cursorRef.current) return

    const tween = gsap.to(cursorRef.current, {
      opacity: 0,
      duration: cursorBlinkDuration,
      repeat: -1,
      yoyo: true,
      ease: 'power2.inOut',
    })

    return () => {
      tween.kill()
    }
  }, [showCursor, cursorBlinkDuration])

  // Typewriter logic
  useEffect(() => {
    isMountedRef.current = true
    let timeoutId: NodeJS.Timeout

    let listIndex = 0
    let charIndex = 0
    let isDeleting = false

    const getTypingDelay = () => {
      if (variableSpeedEnabled) {
        return (
          Math.floor(
            Math.random() * (variableSpeedMax - variableSpeedMin + 1)
          ) + variableSpeedMin
        )
      }
      return typingSpeed
    }

    const tick = () => {
      if (!isMountedRef.current) return

      const currentString = list[listIndex] || ''

      if (!isDeleting) {
        // Typing
        charIndex++
        setDisplayedText(currentString.slice(0, charIndex))

        if (charIndex >= currentString.length) {
          // Finished typing current string
          if (list.length === 1) {
            if (onComplete) onComplete()
            return // Single string: stay typed, don't delete
          }

          isDeleting = true
          timeoutId = setTimeout(tick, pauseDuration)
          return
        }

        timeoutId = setTimeout(tick, getTypingDelay())
      } else {
        // Deleting
        charIndex--
        setDisplayedText(currentString.slice(0, charIndex))

        if (charIndex <= 0) {
          isDeleting = false
          listIndex = (listIndex + 1) % list.length
          timeoutId = setTimeout(tick, getTypingDelay())
          return
        }

        timeoutId = setTimeout(tick, deletingSpeed)
      }
    }

    timeoutId = setTimeout(tick, getTypingDelay())

    return () => {
      isMountedRef.current = false
      clearTimeout(timeoutId)
    }
  }, [
    list,
    typingSpeed,
    deletingSpeed,
    pauseDuration,
    variableSpeedEnabled,
    variableSpeedMin,
    variableSpeedMax,
    onComplete,
  ])

  return (
    <span className={`inline ${className}`}>
      <span>{displayedText}</span>
      {showCursor && (
        <span
          ref={cursorRef}
          className={`inline-block ml-0.5 font-mono select-none ${cursorClassName}`}
        >
          {cursorCharacter}
        </span>
      )}
    </span>
  )
}
