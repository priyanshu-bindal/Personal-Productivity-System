import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for Firebase initialization and reproducing the
/// exact Supabase-to-Firebase Auth Bridge from planner/src/lib/firebase/authBridge.ts.
class FirebaseService {
  static bool _isInitialized = false;

  /// Initializes Firebase SDK with authentic configuration.
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp();
        } catch (_) {
          // Fallback with exact options from google-services.json
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: "AIzaSyAXbWUxowCJvCft1qksiOvn54U1k7QlXAM",
              appId: "1:977799295446:android:e7948331b88454b44e3477",
              messagingSenderId: "977799295446",
              projectId: "focusflow-25da3",
              authDomain: "focusflow-25da3.firebaseapp.com",
              storageBucket: "focusflow-25da3.firebasestorage.app",
            ),
          );
        }
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Firebase initialization notice: $e');
    }
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Ensures user is authenticated with Firebase Auth corresponding to Supabase UID.
  /// Strictly reproduces planner/src/lib/firebase/authBridge.ts:
  /// - bridgeEmail = '${supabaseUid.toLowerCase()}@focusflow.internal'
  /// - bridgePassword = 'FF_Bridge_${supabaseUid}_2026!'
  static Future<String?> ensureFirebaseAuth(String supabaseUid, [String? email]) async {
    if (supabaseUid.isEmpty) return null;
    await initialize();

    final bridgeEmail = '${supabaseUid.toLowerCase()}@focusflow.internal';
    final bridgePassword = 'FF_Bridge_${supabaseUid}_2026!';

    // Check if user is already signed in with matching bridge email
    final currentUser = auth.currentUser;
    if (currentUser != null && currentUser.email?.toLowerCase() == bridgeEmail) {
      return currentUser.uid;
    }

    try {
      final userCredential = await auth.signInWithEmailAndPassword(
        email: bridgeEmail,
        password: bridgePassword,
      );
      return userCredential.user?.uid;
    } on FirebaseAuthException catch (error) {
      // If user account doesn't exist in Firebase Auth yet, create it
      if (error.code == 'user-not-found' ||
          error.code == 'invalid-credential' ||
          error.code == 'invalid-login-credentials' ||
          error.code == 'channel-error') {
        try {
          final userCredential = await auth.createUserWithEmailAndPassword(
            email: bridgeEmail,
            password: bridgePassword,
          );
          return userCredential.user?.uid;
        } on FirebaseAuthException catch (createError) {
          debugPrint('Failed to create Firebase auth bridge account: $createError');
          // If creation fails due to email already in use or similar, attempt sign in again
          try {
            final userCredential = await auth.signInWithEmailAndPassword(
              email: bridgeEmail,
              password: bridgePassword,
            );
            return userCredential.user?.uid;
          } catch (retryError) {
            debugPrint('Retry sign in failed: $retryError');
            return null;
          }
        } catch (createError) {
          debugPrint('Failed to create Firebase auth bridge account: $createError');
          return null;
        }
      } else {
        debugPrint('Firebase Auth bridge error: $error');
        return null;
      }
    } catch (e) {
      debugPrint('Unexpected error in Firebase auth bridge: $e');
      return null;
    }
  }
}
