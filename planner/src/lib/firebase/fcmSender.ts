import { DocumentReference, FieldValue, QueryDocumentSnapshot } from 'firebase-admin/firestore'
import { Message } from 'firebase-admin/messaging'
import { getAdminFirestore, getAdminMessaging } from './admin'

export interface ChatPushPayload {
  conversationId: string
  senderId: string
  receiverId: string
  text: string
  senderName?: string
  senderShortId?: string
}

export interface FcmSendResult {
  success: boolean
  tokenCount: number
  successCount: number
  failureCount: number
  staleCount: number
  errors?: string[]
}

const STALE_ERROR_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/mismatched-credential'
])

/**
 * Sends a push notification to all active devices of the recipient user.
 */
export async function sendPushNotificationForChatMessage(
  payload: ChatPushPayload
): Promise<FcmSendResult> {
  const { conversationId, senderId, receiverId, text, senderName, senderShortId } = payload

  console.log(`[FCM] Recipient: ${receiverId}`)

  const db = getAdminFirestore()
  const messaging = getAdminMessaging()

  if (!db || !messaging) {
    console.warn('[FCM] FCM error: Firebase Admin is not initialized or configured.')
    return {
      success: false,
      tokenCount: 0,
      successCount: 0,
      failureCount: 0,
      staleCount: 0,
      errors: ['Firebase Admin is not initialized']
    }
  }

  // 1. Fetch active device tokens for the recipient user
  const deviceSnapshots: Array<{ docRef: DocumentReference; token: string; deviceId: string }> = []

  try {
    // Attempt A: Direct subcollection query users/{receiverId}/devices
    const directSnap = await db
      .collection('users')
      .doc(receiverId)
      .collection('devices')
      .get()

    directSnap.forEach((doc: QueryDocumentSnapshot) => {
      const data = doc.data()
      if (data?.notificationEnabled !== false && typeof data?.fcmToken === 'string' && data.fcmToken.trim().length > 0) {
        deviceSnapshots.push({
          docRef: doc.ref,
          token: data.fcmToken.trim(),
          deviceId: doc.id
        })
      }
    })

    // Attempt B: If no tokens found, search by supabaseUserId in case receiverId is Supabase UUID
    if (deviceSnapshots.length === 0) {
      const fallbackSnap = await db
        .collectionGroup('devices')
        .where('supabaseUserId', '==', receiverId)
        .get()

      fallbackSnap.forEach((doc: QueryDocumentSnapshot) => {
        const data = doc.data()
        if (data?.notificationEnabled !== false && typeof data?.fcmToken === 'string' && data.fcmToken.trim().length > 0) {
          // Avoid duplicates
          if (!deviceSnapshots.some((d) => d.token === data.fcmToken.trim())) {
            deviceSnapshots.push({
              docRef: doc.ref,
              token: data.fcmToken.trim(),
              deviceId: doc.id
            })
          }
        }
      })
    }
  } catch (err: any) {
    console.error(`[FCM] FCM error while retrieving tokens for recipient ${receiverId}:`, err?.message)
    return {
      success: false,
      tokenCount: 0,
      successCount: 0,
      failureCount: 0,
      staleCount: 0,
      errors: [err?.message || 'Failed to query device tokens']
    }
  }

  console.log(`[FCM] Token count: ${deviceSnapshots.length}`)

  if (deviceSnapshots.length === 0) {
    return {
      success: true,
      tokenCount: 0,
      successCount: 0,
      failureCount: 0,
      staleCount: 0
    }
  }

  // 2. Prepare message notification title and body
  const title = senderName && senderName.trim().length > 0
    ? senderName.trim()
    : senderShortId
    ? `#${senderShortId}`
    : 'FocusFlow Message'

  const body = text.length > 100 ? `${text.substring(0, 97)}...` : text

  // 3. Construct individual message payloads for sendEach
  const messagesToSend: Message[] = deviceSnapshots.map(({ token }) => ({
    token,
    notification: {
      title,
      body
    },
    data: {
      type: 'chat_message',
      conversationId,
      senderId: senderShortId || senderId,
      senderUid: senderId,
      senderName: senderName || '',
      text,
      click_action: 'FLUTTER_NOTIFICATION_CLICK'
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'focusflow_messages',
        sound: 'default',
        priority: 'high',
        defaultSound: true,
        defaultVibrateTimings: true,
        clickAction: 'FLUTTER_NOTIFICATION_CLICK'
      }
    }
  }))

  console.log(`[FCM] Sending notification: to ${deviceSnapshots.length} device(s) - Title: "${title}"`)

  try {
    const batchResponse = await messaging.sendEach(messagesToSend)
    console.log(
      `[FCM] FCM response: success=${batchResponse.successCount}, failure=${batchResponse.failureCount}`
    )

    let staleCount = 0
    const errors: string[] = []

    // 4. Identify failed tokens and handle stale tokens cleanly
    for (let i = 0; i < batchResponse.responses.length; i++) {
      const resp = batchResponse.responses[i]!
      const device = deviceSnapshots[i]!

      if (!resp.success && resp.error) {
        const errorCode = resp.error.code
        errors.push(`${device.deviceId}: ${errorCode} - ${resp.error.message}`)
        console.warn(`[FCM] FCM error on device ${device.deviceId}: ${errorCode}`)

        if (STALE_ERROR_CODES.has(errorCode)) {
          staleCount++
          console.log(`[FCM] Deactivating stale token for device ${device.deviceId}`)
          try {
            await device.docRef.set(
              {
                notificationEnabled: false,
                staleAt: FieldValue.serverTimestamp(),
                staleReason: errorCode
              },
              { merge: true }
            )
          } catch (deactivateErr: any) {
            console.error(`[FCM] Error deactivating stale device ${device.deviceId}:`, deactivateErr?.message)
          }
        }
      }
    }

    return {
      success: batchResponse.successCount > 0 || deviceSnapshots.length === 0,
      tokenCount: deviceSnapshots.length,
      successCount: batchResponse.successCount,
      failureCount: batchResponse.failureCount,
      staleCount,
      errors: errors.length > 0 ? errors : undefined
    }
  } catch (err: any) {
    console.error('[FCM] FCM error during sendEach execution:', err?.message)
    return {
      success: false,
      tokenCount: deviceSnapshots.length,
      successCount: 0,
      failureCount: deviceSnapshots.length,
      staleCount: 0,
      errors: [err?.message || 'Unknown send error']
    }
  }
}

/**
 * Direct test function to send an FCM message to a single explicit registration token.
 */
export async function sendDirectNotification(
  token: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<{ success: boolean; messageId?: string; error?: string }> {
  console.log(`[FCM] Direct test send to token: ${token.substring(0, 15)}...`)

  const messaging = getAdminMessaging()
  if (!messaging) {
    return { success: false, error: 'Firebase Admin messaging not initialized' }
  }

  try {
    const messageId = await messaging.send({
      token,
      notification: {
        title,
        body
      },
      data: {
        type: 'test_notification',
        ...data
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'focusflow_messages',
          sound: 'default',
          priority: 'high'
        }
      }
    })

    console.log(`[FCM] FCM response: direct test send success messageId=${messageId}`)
    return { success: true, messageId }
  } catch (err: any) {
    console.error('[FCM] FCM error on direct test send:', err?.code, err?.message)
    return { success: false, error: `${err?.code || 'UNKNOWN'}: ${err?.message}` }
  }
}
