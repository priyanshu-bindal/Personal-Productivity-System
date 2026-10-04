import { NextRequest, NextResponse } from 'next/server'
import { sendPushNotificationForChatMessage } from '@/lib/firebase/fcmSender'

export const dynamic = 'force-dynamic'

export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    const { conversationId, senderId, receiverId, text, senderName, senderShortId } = body

    if (!conversationId || !senderId || !receiverId || !text) {
      return NextResponse.json(
        {
          success: false,
          error: 'Missing required parameters: conversationId, senderId, receiverId, and text are required.'
        },
        { status: 400 }
      )
    }

    const result = await sendPushNotificationForChatMessage({
      conversationId: String(conversationId),
      senderId: String(senderId),
      receiverId: String(receiverId),
      text: String(text),
      senderName: senderName ? String(senderName) : undefined,
      senderShortId: senderShortId ? String(senderShortId) : undefined
    })

    return NextResponse.json({
      success: true,
      delivered: result.successCount,
      failed: result.failureCount,
      staleCleaned: result.staleCount,
      totalDevices: result.tokenCount,
      errors: result.errors
    })
  } catch (err: any) {
    console.error('[FCM] API unhandled error in /api/notify/chat-message:', err?.message)
    // Always return a graceful 200 with success: false so the client chat flow does not break
    return NextResponse.json(
      {
        success: false,
        error: err?.message || 'Internal notification processing error'
      },
      { status: 200 }
    )
  }
}
