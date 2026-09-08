import { signInWithEmailAndPassword, createUserWithEmailAndPassword, Auth } from 'firebase/auth'
import { auth } from './config'

/**
 * Ensures the user is authenticated with Firebase Auth using their Supabase UID.
 * Creates a deterministic email & password bridge for the Supabase user if not already present.
 */
export async function ensureFirebaseAuth(supabaseUid: string, email?: string): Promise<string> {
  if (!supabaseUid) {
    throw new Error('Supabase UID is required for Firebase auth bridge')
  }

  // Check if user is already signed into Firebase Auth with matching UID
  if (auth.currentUser && auth.currentUser.uid === supabaseUid) {
    return auth.currentUser.uid
  }

  const bridgeEmail = `${supabaseUid.toLowerCase()}@focusflow.internal`
  // Deterministic secret password derived from Supabase UID + static salt
  const bridgePassword = `FF_Bridge_${supabaseUid}_2026!`

  try {
    const userCredential = await signInWithEmailAndPassword(auth, bridgeEmail, bridgePassword)
    return userCredential.user.uid
  } catch (error: any) {
    // If user account doesn't exist in Firebase Auth yet, create it
    if (error.code === 'auth/user-not-found' || error.code === 'auth/invalid-credential') {
      try {
        const userCredential = await createUserWithEmailAndPassword(auth, bridgeEmail, bridgePassword)
        return userCredential.user.uid
      } catch (createError: any) {
        console.error('Failed to create Firebase auth bridge account:', createError)
        // If creation fails due to email already in use or similar, attempt sign in again
        try {
          const userCredential = await signInWithEmailAndPassword(auth, bridgeEmail, bridgePassword)
          return userCredential.user.uid
        } catch (retryError) {
          console.error('Retry sign in failed:', retryError)
          throw retryError
        }
      }
    } else {
      console.error('Firebase Auth bridge error:', error)
      throw error
    }
  }
}
