import { 
  doc, 
  getDoc, 
  getDocs, 
  setDoc, 
  updateDoc, 
  addDoc, 
  collection, 
  query, 
  where, 
  orderBy, 
  onSnapshot, 
  runTransaction, 
  writeBatch, 
  serverTimestamp,
  increment,
  Timestamp,
  Unsubscribe
} from 'firebase/firestore'
import { db } from './config'

export interface ChatUser {
  uid: string
  shortUserId: string
  createdAt?: any
  updatedAt?: any
}

export interface Conversation {
  id: string
  participants: string[]
  participantKey: string
  participantProfiles?: Record<string, { shortUserId: string; displayName: string }>
  unreadCounts?: Record<string, number>
  lastMessage: string
  lastMessageAt: any
  lastSenderId: string
  createdAt: any
  otherUid: string
  otherUserShortId?: string
}

export interface Message {
  id: string
  senderId: string
  receiverId: string
  text: string
  status: 'sending' | 'sent' | 'seen'
  createdAt: any
  deliveredAt?: any
  seenAt?: any
}

const ALLOWED_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'

export interface UserProfile {
  uid: string
  shortUserId: string
  displayName?: string
}

/**
 * Generates a random 5-character uppercase alphanumeric ID avoiding ambiguous characters.
 */
export function generateRandomShortId(): string {
  let result = ''
  for (let i = 0; i < 5; i++) {
    const randomIndex = Math.floor(Math.random() * ALLOWED_CHARS.length)
    result += ALLOWED_CHARS.charAt(randomIndex)
  }
  return result
}

/**
 * Ensures the user has a permanent unique 5-character shortUserId.
 */
export async function ensureUserChatId(uid: string, displayName?: string): Promise<string> {
  if (!uid) throw new Error('User UID is required')

  const cleanName = displayName?.trim() || ''
  const userRef = doc(db, 'users', uid)
  const userSnap = await getDoc(userRef)

  if (userSnap.exists() && userSnap.data()?.shortUserId) {
    const existingShortId = userSnap.data().shortUserId
    if (cleanName && userSnap.data()?.displayName !== cleanName) {
      await setDoc(userRef, { displayName: cleanName, updatedAt: serverTimestamp() }, { merge: true })
      const lookupRef = doc(db, 'userIds', existingShortId)
      await setDoc(lookupRef, { displayName: cleanName }, { merge: true })
    }
    return existingShortId
  }

  // Generate unique Chat ID using Firestore transaction
  let attempts = 0
  while (attempts < 10) {
    attempts++
    const candidateId = generateRandomShortId()
    const userIdLookupRef = doc(db, 'userIds', candidateId)

    try {
      const assignedId = await runTransaction(db, async (transaction) => {
        const lookupSnap = await transaction.get(userIdLookupRef)
        if (lookupSnap.exists()) {
          throw new Error('COLLISION')
        }

        transaction.set(userRef, {
          shortUserId: candidateId,
          displayName: cleanName,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp()
        }, { merge: true })

        transaction.set(userIdLookupRef, {
          uid: uid,
          displayName: cleanName,
          createdAt: serverTimestamp()
        })

        return candidateId
      })

      return assignedId
    } catch (err: any) {
      if (err.message === 'COLLISION') {
        continue
      }
      console.error('Error during Chat ID generation transaction:', err)
      throw err
    }
  }

  throw new Error('Failed to generate unique Chat ID after maximum attempts')
}

/**
 * Finds a user's Firebase UID by their 5-character Chat ID.
 */
export async function lookupUserByChatId(shortUserId: string): Promise<string | null> {
  const sanitizedId = shortUserId.trim().toUpperCase()
  if (!sanitizedId || sanitizedId.length < 4) return null

  const lookupRef = doc(db, 'userIds', sanitizedId)
  const lookupSnap = await getDoc(lookupRef)

  if (lookupSnap.exists()) {
    return lookupSnap.data()?.uid || null
  }
  return null
}

/**
 * Gets short Chat ID for a given user UID.
 */
export async function getUserShortId(uid: string): Promise<string | null> {
  const userRef = doc(db, 'users', uid)
  const userSnap = await getDoc(userRef)
  if (userSnap.exists()) {
    return userSnap.data()?.shortUserId || null
  }
  return null
}

/**
 * Gets full UserProfile (shortUserId + displayName) for a given user UID.
 */
export async function getUserProfile(uid: string): Promise<UserProfile | null> {
  const userRef = doc(db, 'users', uid)
  const userSnap = await getDoc(userRef)
  if (userSnap.exists()) {
    const data = userSnap.data()
    return {
      uid,
      shortUserId: data?.shortUserId || '',
      displayName: data?.displayName || ''
    }
  }
  return null
}

/**
 * Deterministically creates or retrieves a 1-to-1 conversation between two users.
 */
export async function getOrCreateConversation(currentUid: string, targetUid: string): Promise<string> {
  if (currentUid === targetUid) {
    throw new Error('Cannot message yourself')
  }

  const sortedUids = [currentUid, targetUid].sort()
  const conversationId = `${sortedUids[0]}_${sortedUids[1]}`
  const convRef = doc(db, 'conversations', conversationId)

  // Fetch profiles for both participants to embed in the conversation doc
  const [currentProf, targetProf] = await Promise.all([
    getUserProfile(currentUid).catch(() => null),
    getUserProfile(targetUid).catch(() => null)
  ])

  const profiles: Record<string, { shortUserId: string; displayName: string }> = {}
  if (currentProf) profiles[currentUid] = { shortUserId: currentProf.shortUserId, displayName: currentProf.displayName || '' }
  if (targetProf) profiles[targetUid] = { shortUserId: targetProf.shortUserId, displayName: targetProf.displayName || '' }

  try {
    const convSnap = await getDoc(convRef)
    if (!convSnap.exists()) {
      await setDoc(convRef, {
        participants: sortedUids,
        participantKey: conversationId,
        participantProfiles: profiles,
        lastMessage: '',
        lastMessageAt: serverTimestamp(),
        lastSenderId: '',
        createdAt: serverTimestamp()
      })
    } else if (Object.keys(profiles).length > 0) {
      await setDoc(convRef, { participantProfiles: profiles }, { merge: true })
    }
  } catch (err: any) {
    await setDoc(convRef, {
      participants: sortedUids,
      participantKey: conversationId,
      participantProfiles: profiles,
      lastMessage: '',
      lastMessageAt: serverTimestamp(),
      lastSenderId: '',
      createdAt: serverTimestamp()
    }, { merge: true })
  }

  return conversationId
}

/**
 * Sends a direct message in a conversation.
 */
export async function sendMessage(
  conversationId: string, 
  senderId: string, 
  receiverId: string, 
  text: string
): Promise<string> {
  const cleanText = text.trim()
  if (!cleanText) throw new Error('Message text cannot be empty')

  const messagesColRef = collection(db, 'conversations', conversationId, 'messages')
  
  const docRef = await addDoc(messagesColRef, {
    senderId,
    receiverId,
    text: cleanText,
    status: 'sent',
    createdAt: serverTimestamp(),
    deliveredAt: serverTimestamp(),
    seenAt: null
  })

  // Update last message preview and increment recipient's unread count atomically
  const convRef = doc(db, 'conversations', conversationId)
  await updateDoc(convRef, {
    lastMessage: cleanText,
    lastMessageAt: serverTimestamp(),
    lastSenderId: senderId,
    [`unreadCounts.${receiverId}`]: increment(1)
  })

  return docRef.id
}

/**
 * Marks incoming unread messages in a conversation as seen and resets recipient's unread count to 0.
 */
export async function markMessagesAsSeen(conversationId: string, currentUid: string): Promise<void> {
  if (!conversationId || !currentUid) return

  // Reset unread count for current user on conversation document
  const convRef = doc(db, 'conversations', conversationId)
  await updateDoc(convRef, {
    [`unreadCounts.${currentUid}`]: 0
  }).catch(() => {})

  try {
    const messagesColRef = collection(db, 'conversations', conversationId, 'messages')
    const q = query(
      messagesColRef,
      where('receiverId', '==', currentUid),
      where('status', '==', 'sent')
    )

    const querySnapshot = await getDocs(q)
    if (querySnapshot.empty) return

    const batch = writeBatch(db)
    querySnapshot.docs.forEach((messageDoc: any) => {
      batch.update(messageDoc.ref, {
        status: 'seen',
        seenAt: serverTimestamp()
      })
    })

    await batch.commit()
  } catch (err) {
    console.error('Error marking messages as seen:', err)
  }
}

/**
 * Real-time listener for user's conversations list.
 */
export function subscribeToConversations(
  currentUid: string, 
  onUpdate: (conversations: Conversation[]) => void
): Unsubscribe {
  const convsColRef = collection(db, 'conversations')
  const q = query(
    convsColRef,
    where('participants', 'array-contains', currentUid)
  )

  return onSnapshot(q, async (snapshot) => {
    const rawConvs: Conversation[] = []
    
    for (const docSnap of snapshot.docs) {
      const data = docSnap.data()
      const otherUid = (data.participants as string[]).find(uid => uid !== currentUid) || currentUid
      const profiles = data.participantProfiles || {}
      const targetProfile = profiles[otherUid]
      
      rawConvs.push({
        id: docSnap.id,
        participants: data.participants,
        participantKey: data.participantKey,
        participantProfiles: profiles,
        unreadCounts: data.unreadCounts || {},
        lastMessage: data.lastMessage || '',
        lastMessageAt: data.lastMessageAt,
        lastSenderId: data.lastSenderId || '',
        createdAt: data.createdAt,
        otherUid: otherUid,
        otherUserShortId: targetProfile?.shortUserId || ''
      })
    }

    // Sort client-side by lastMessageAt descending to avoid needing a Firestore composite index
    rawConvs.sort((a, b) => {
      const getMillis = (t: any) => {
        if (!t) return 0
        if (typeof t.toMillis === 'function') return t.toMillis()
        if (t.seconds) return t.seconds * 1000
        return 0
      }
      return getMillis(b.lastMessageAt) - getMillis(a.lastMessageAt)
    })

    onUpdate(rawConvs)
  }, (err) => {
    console.error('Error listening to conversations:', err)
  })
}

/**
 * Real-time listener for messages within a specific conversation.
 */
export function subscribeToMessages(
  conversationId: string, 
  onUpdate: (messages: Message[]) => void
): Unsubscribe {
  const messagesColRef = collection(db, 'conversations', conversationId, 'messages')
  const q = query(messagesColRef, orderBy('createdAt', 'asc'))

  return onSnapshot(q, (snapshot) => {
    const messages: Message[] = snapshot.docs.map(docSnap => {
      const data = docSnap.data()
      return {
        id: docSnap.id,
        senderId: data.senderId,
        receiverId: data.receiverId,
        text: data.text,
        status: data.status || 'sent',
        createdAt: data.createdAt,
        deliveredAt: data.deliveredAt,
        seenAt: data.seenAt
      }
    })
    onUpdate(messages)
  }, (err) => {
    console.error(`Error listening to messages for conversation ${conversationId}:`, err)
  })
}
