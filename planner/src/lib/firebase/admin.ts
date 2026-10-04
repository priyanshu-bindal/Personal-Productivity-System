import { initializeApp, getApps, cert, applicationDefault, App } from 'firebase-admin/app'
import { getFirestore, Firestore } from 'firebase-admin/firestore'
import { getMessaging, Messaging } from 'firebase-admin/messaging'

/**
 * Server-only Firebase Admin SDK Singleton.
 *
 * Ensures:
 * 1. Firebase Admin initializes exactly once across hot reloads.
 * 2. Credentials are kept strictly on the server (never exposed to client).
 * 3. Gracefully reports configuration status without crashing the process.
 */

let isConfigured = false

export function getFirebaseAdminApp(): App | null {
  const existingApps = getApps()
  if (existingApps.length > 0) {
    return existingApps[0]!
  }

  const projectId =
    process.env.FIREBASE_PROJECT_ID ||
    process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ||
    'focusflow-25da3'

  // 0. Check for service-account.json file locally
  try {
    const fs = require('fs')
    const path = require('path')
    const possiblePaths = [
      path.join(process.cwd(), 'service-account.json'),
      path.join(process.cwd(), '..', 'service-account.json'),
    ]
    for (const p of possiblePaths) {
      if (fs.existsSync(/*turbopackIgnore: true*/ p)) {
        const fileContent = fs.readFileSync(/*turbopackIgnore: true*/ p, 'utf8')
        const serviceAccount = JSON.parse(fileContent)
        const app = initializeApp({
          credential: cert(serviceAccount),
          projectId: serviceAccount.project_id || projectId,
        })
        isConfigured = true
        return app
      }
    }
  } catch (e: any) {
    // continue
  }

  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL
  let privateKey = process.env.FIREBASE_PRIVATE_KEY

  // 1. Check for complete service account JSON string
  if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
    try {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY)
      const app = initializeApp({
        credential: cert(serviceAccount),
        projectId: serviceAccount.project_id || projectId,
      })
      isConfigured = true
      return app
    } catch (e: any) {
      console.error('[FCM] Failed to parse FIREBASE_SERVICE_ACCOUNT_KEY:', e?.message)
    }
  }

  // 2. Check for individual client email + private key
  if (clientEmail && privateKey) {
    // Unescape newlines if passed in as \n in env string
    if (privateKey.includes('\\n')) {
      privateKey = privateKey.replace(/\\n/g, '\n')
    }

    try {
      const app = initializeApp({
        credential: cert({
          projectId,
          clientEmail,
          privateKey,
        }),
        projectId,
      })
      isConfigured = true
      return app
    } catch (e: any) {
      console.error('[FCM] Failed to initialize Firebase Admin with credentials:', e?.message)
    }
  }

  // 3. Check for standard Google Application Default Credentials
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    try {
      const app = initializeApp({
        credential: applicationDefault(),
        projectId,
      })
      isConfigured = true
      return app
    } catch (e: any) {
      console.error('[FCM] Failed to initialize with Application Default Credentials:', e?.message)
    }
  }

  // 4. Fallback: Initialize with project ID only (no service account credential)
  try {
    const app = initializeApp({ projectId })
    console.warn(
      '[FCM] Initialized Firebase Admin without explicit service account credentials. ' +
        'Please set FIREBASE_CLIENT_EMAIL and FIREBASE_PRIVATE_KEY in .env to enable remote FCM delivery.'
    )
    return app
  } catch (e: any) {
    console.error('[FCM] Unable to initialize Firebase Admin app:', e?.message)
    return null
  }
}

export function getAdminFirestore(): Firestore | null {
  const app = getFirebaseAdminApp()
  if (!app) return null
  try {
    return getFirestore(app)
  } catch (e: any) {
    console.error('[FCM] Error accessing Admin Firestore:', e?.message)
    return null
  }
}

export function getAdminMessaging(): Messaging | null {
  const app = getFirebaseAdminApp()
  if (!app) return null
  try {
    return getMessaging(app)
  } catch (e: any) {
    console.error('[FCM] Error accessing Admin Messaging:', e?.message)
    return null
  }
}

export function isFirebaseAdminConfigured(): boolean {
  return isConfigured || Boolean(
    process.env.FIREBASE_SERVICE_ACCOUNT_KEY ||
    (process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) ||
    process.env.GOOGLE_APPLICATION_CREDENTIALS
  )
}
