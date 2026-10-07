import { DocumentReference, FieldValue, QueryDocumentSnapshot } from 'firebase-admin/firestore'
import { MulticastMessage } from 'firebase-admin/messaging'
import { getAdminFirestore, getAdminMessaging } from './admin'

export interface AnnouncementPayload {
  title: string
  message: string
  route?: string        // optional deep link e.g. '/today'
  sentBy: string        // admin Supabase UID (for logging only, never exposed to device)
}

export interface AnnouncementResult {
  announcementId: string
  recipientUsers: number
  deviceCount: number
  uniqueTokens: number
  totalDevices: number
  successCount: number
  failureCount: number
  staleCount: number
}

const STALE_ERROR_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/mismatched-credential',
  'messaging/invalid-argument'
])

/**
 * Scans ALL Firestore device documents and broadcasts an FCM announcement
 * to all devices where notifications and announcements are enabled.
 *
 * Checks:
 * 1. Valid non-empty fcmToken string.
 * 2. notificationEnabled !== false (device active).
 * 3. announcementsEnabled !== false (user opted-in to announcements).
 * 4. Deduplicates identical FCM tokens so each physical device receives it once.
 */
export async function sendAnnouncementToAllDevices(
  payload: AnnouncementPayload
): Promise<AnnouncementResult> {
  const db = getAdminFirestore()
  const messaging = getAdminMessaging()

  const announcementId = `announcement_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`

  if (!db || !messaging) {
    console.error('[ANNOUNCEMENT] Firebase Admin not initialized')
    throw new Error('Firebase Admin is not initialized')
  }

  console.log(`[ANNOUNCEMENT] Admin authorized: ${payload.sentBy}`)
  console.log(`[ANNOUNCEMENT] Starting broadcast — id: ${announcementId}`)
  console.log(`[ANNOUNCEMENT] Title: "${payload.title}"`)

  // ─── 1. Collect all valid device tokens from Firestore ────────────────────
  const tokenMap = new Map<string, DocumentReference>() // token → docRef (for stale cleanup)
  const eligibleUsersSet = new Set<string>()
  let totalDeviceDocs = 0
  let devicesWithToken = 0
  let notificationEnabledCount = 0
  let announcementsEnabledCount = 0
  let eligibleDevices = 0

  const processDeviceDoc = (doc: QueryDocumentSnapshot) => {
    totalDeviceDocs++
    const data = doc.data()
    const token: string = typeof data?.fcmToken === 'string' ? data.fcmToken.trim() : ''
    if (!token) return
    devicesWithToken++

    // Device level check: false means user signed out or explicitly disabled
    if (data?.notificationEnabled === false) return
    notificationEnabledCount++

    // Announcements opt-in check: explicit false means user muted announcements
    // Missing/undefined means default enabled
    if (data?.announcementsEnabled === false) return
    announcementsEnabledCount++

    eligibleDevices++
    const userId = data?.supabaseUserId || doc.ref.parent.parent?.id || 'unknown'
    eligibleUsersSet.add(userId)

    if (tokenMap.has(token)) return // deduplicate
    tokenMap.set(token, doc.ref)
  }

  try {
    // Primary scan: collectionGroup('devices')
    try {
      const devicesSnap = await db.collectionGroup('devices').get()
      devicesSnap.forEach(processDeviceDoc)
    } catch (cgErr: any) {
      console.warn('[ANNOUNCEMENT] collectionGroup query error, falling back to direct user scan:', cgErr?.message)
    }

    // Direct user-by-user fallback scan if collectionGroup returned 0 tokens
    if (tokenMap.size === 0) {
      console.log('[ANNOUNCEMENT] Performing direct user scan for device tokens...')
      const usersSnap = await db.collection('users').get()
      for (const userDoc of usersSnap.docs) {
        const devSnap = await userDoc.ref.collection('devices').get()
        devSnap.forEach(processDeviceDoc)
      }
    }
  } catch (err: any) {
    console.error('[ANNOUNCEMENT] Error scanning device documents:', err?.message)
    throw new Error(`Failed to fetch device tokens: ${err?.message}`)
  }

  const tokens = Array.from(tokenMap.keys())
  const recipientUsers = eligibleUsersSet.size
  const uniqueTokens = tokens.length

  console.log(`[ANNOUNCEMENT] Total device documents: ${totalDeviceDocs}`)
  console.log(`[ANNOUNCEMENT] Devices with token: ${devicesWithToken}`)
  console.log(`[ANNOUNCEMENT] Notification enabled: ${notificationEnabledCount}`)
  console.log(`[ANNOUNCEMENT] Announcements enabled: ${announcementsEnabledCount}`)
  console.log(`[ANNOUNCEMENT] Eligible devices: ${eligibleDevices}`)
  console.log(`[ANNOUNCEMENT] Unique tokens: ${uniqueTokens}`)
  console.log(`[ANNOUNCEMENT] Eligible users: ${recipientUsers}`)

  if (uniqueTokens === 0) {
    console.log('[ANNOUNCEMENT] No eligible tokens found. Broadcast complete.')
    return {
      announcementId,
      recipientUsers: 0,
      deviceCount: 0,
      uniqueTokens: 0,
      totalDevices: 0,
      successCount: 0,
      failureCount: 0,
      staleCount: 0
    }
  }

  // ─── 2. Build the FCM message ──────────────────────────────────────────────
  // Send in batches of 500 (FCM sendEachForMulticast limit)
  const BATCH_SIZE = 500
  let successCount = 0
  let failureCount = 0
  let staleCount = 0

  const dataPayload: Record<string, string> = {
    type: 'announcement',
    announcementId,
    title: payload.title,
    body: payload.message,
  }
  if (payload.route) {
    dataPayload.route = payload.route
  }

  for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
    const batchTokens = tokens.slice(i, i + BATCH_SIZE)
    const batchNum = Math.floor(i / BATCH_SIZE) + 1
    console.log(`[ANNOUNCEMENT] Sending batch ${batchNum} — ${batchTokens.length} tokens`)

    const message: MulticastMessage = {
      tokens: batchTokens,
      notification: {
        title: payload.title,
        body: payload.message
      },
      data: dataPayload,
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
    }

    try {
      const batchResponse = await messaging.sendEachForMulticast(message)
      console.log(`[ANNOUNCEMENT] Batch ${batchNum}: success=${batchResponse.successCount}, failure=${batchResponse.failureCount}`)

      successCount += batchResponse.successCount
      failureCount += batchResponse.failureCount

      // Clean up stale tokens & log exact error
      for (let j = 0; j < batchResponse.responses.length; j++) {
        const resp = batchResponse.responses[j]!
        const token = batchTokens[j]!
        if (!resp.success && resp.error) {
          const errorCode = resp.error.code
          console.warn(`[ANNOUNCEMENT] FCM send failed for token (...${token.slice(-10)}): code=${errorCode}, message=${resp.error.message}`)
          if (STALE_ERROR_CODES.has(errorCode) || errorCode === 'messaging/invalid-argument') {
            staleCount++
            const docRef = tokenMap.get(token)
            if (docRef) {
              try {
                await docRef.set(
                  {
                    notificationEnabled: false,
                    staleAt: FieldValue.serverTimestamp(),
                    staleReason: errorCode
                  },
                  { merge: true }
                )
              } catch (cleanupErr: any) {
                console.warn('[ANNOUNCEMENT] Failed to mark stale token:', cleanupErr?.message)
              }
            }
          }
        }
      }
    } catch (batchErr: any) {
      console.error(`[ANNOUNCEMENT] Batch ${batchNum} send error:`, batchErr?.message)
      failureCount += batchTokens.length
    }
  }

  console.log(`[ANNOUNCEMENT] Complete — total=${tokens.length}, success=${successCount}, failure=${failureCount}, stale=${staleCount}`)

  // ─── 3. Store Announcement Record in Firestore ─────────────────────────────
  try {
    await db.collection('announcements').doc(announcementId).set({
      announcementId,
      title: payload.title,
      message: payload.message,
      route: payload.route || null,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: payload.sentBy,
      recipientCount: tokens.length,
      successCount,
      failureCount,
      staleCount,
    })
  } catch (recErr: any) {
    console.warn('[ANNOUNCEMENT] Failed to write announcement log to Firestore:', recErr?.message)
  }

  return {
    announcementId,
    recipientUsers,
    deviceCount: eligibleDevices,
    uniqueTokens,
    totalDevices: tokens.length,
    successCount,
    failureCount,
    staleCount
  }
}

/**
 * Retrieves the recent announcements list for the admin UI.
 */
export async function getRecentAnnouncements(limitCount: number = 10) {
  const db = getAdminFirestore()
  if (!db) return []

  try {
    const snap = await db
      .collection('announcements')
      .orderBy('createdAt', 'desc')
      .limit(limitCount)
      .get()

    return snap.docs.map((doc: QueryDocumentSnapshot) => {
      const data = doc.data()
      return {
        id: doc.id,
        announcementId: data.announcementId || doc.id,
        title: data.title || '',
        message: data.message || '',
        route: data.route || null,
        createdAt: data.createdAt?.toDate ? data.createdAt.toDate().toISOString() : null,
        recipientCount: data.recipientCount || 0,
        successCount: data.successCount || 0,
        failureCount: data.failureCount || 0,
      }
    })
  } catch (err: any) {
    console.warn('[ANNOUNCEMENT] Failed to fetch recent announcements:', err?.message)
    return []
  }
}

export interface AnnouncementDiagnostics {
  totalDeviceDocs: number
  documentsWithToken: number
  notificationEligible: number
  announcementEligible: number
  uniqueFirebaseUsers: number
  uniqueTokens: number
  userBreakdown: Array<{
    userDocId: string
    deviceCount: number
  }>
}

/**
 * Server-side non-destructive diagnostic query.
 * Discovers and inspects ALL registered devices in Firestore.
 */
export async function getAnnouncementDiagnostics(): Promise<AnnouncementDiagnostics> {
  const db = getAdminFirestore()
  if (!db) {
    throw new Error('Firebase Admin Firestore is not initialized')
  }

  let totalDeviceDocs = 0
  let documentsWithToken = 0
  let notificationEligible = 0
  let announcementEligible = 0
  const uniqueUsers = new Set<string>()
  const uniqueTokensSet = new Set<string>()
  const userDeviceCountMap = new Map<string, number>()

  const processDoc = (doc: QueryDocumentSnapshot) => {
    totalDeviceDocs++
    const data = doc.data()
    const token = typeof data?.fcmToken === 'string' ? data.fcmToken.trim() : ''
    const userDocId = doc.ref.parent.parent?.id || 'unknown'
    userDeviceCountMap.set(userDocId, (userDeviceCountMap.get(userDocId) || 0) + 1)

    if (token) {
      documentsWithToken++
      if (data?.notificationEnabled !== false) {
        notificationEligible++
        if (data?.announcementsEnabled !== false) {
          announcementEligible++
          uniqueUsers.add(userDocId)
          uniqueTokensSet.add(token)
        }
      }
    }
  }

  try {
    const snap = await db.collectionGroup('devices').get()
    snap.forEach(processDoc)
  } catch (err: any) {
    console.warn('[ANNOUNCEMENT DIAGNOSTIC] collectionGroup failed, using user scan fallback:', err?.message)
    const usersSnap = await db.collection('users').get()
    for (const u of usersSnap.docs) {
      const devSnap = await u.ref.collection('devices').get()
      devSnap.forEach(processDoc)
    }
  }

  console.log(`[ANNOUNCEMENT DIAGNOSTIC] Total device documents: ${totalDeviceDocs}`)
  console.log(`[ANNOUNCEMENT DIAGNOSTIC] Documents with token: ${documentsWithToken}`)
  console.log(`[ANNOUNCEMENT DIAGNOSTIC] Notification eligible: ${notificationEligible}`)
  console.log(`[ANNOUNCEMENT DIAGNOSTIC] Announcement eligible: ${announcementEligible}`)
  console.log(`[ANNOUNCEMENT DIAGNOSTIC] Unique Firebase users: ${uniqueUsers.size}`)
  console.log(`[ANNOUNCEMENT DIAGNOSTIC] Unique FCM tokens: ${uniqueTokensSet.size}`)

  return {
    totalDeviceDocs,
    documentsWithToken,
    notificationEligible,
    announcementEligible,
    uniqueFirebaseUsers: uniqueUsers.size,
    uniqueTokens: uniqueTokensSet.size,
    userBreakdown: Array.from(userDeviceCountMap.entries()).map(([userDocId, deviceCount]) => ({
      userDocId,
      deviceCount
    }))
  }
}

