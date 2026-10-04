import { NextRequest, NextResponse } from 'next/server'
import { sendDirectNotification } from '@/lib/firebase/fcmSender'

export const dynamic = 'force-dynamic'

export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    const { token, title, body: msgBody, data } = body

    if (!token) {
      return NextResponse.json(
        { success: false, error: 'Registration token is required' },
        { status: 400 }
      )
    }

    const result = await sendDirectNotification(
      token,
      title || 'FocusFlow Test',
      msgBody || 'Notifications are working correctly on this device.',
      data
    )

    return NextResponse.json(result)
  } catch (err: any) {
    return NextResponse.json(
      { success: false, error: err?.message || 'Failed to dispatch test notification' },
      { status: 500 }
    )
  }
}
