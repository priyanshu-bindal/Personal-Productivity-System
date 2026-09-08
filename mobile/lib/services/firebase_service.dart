import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        // google-services.json is placed in android/app/ and the plugin reads it automatically.
        // This fallback uses the Android-specific values from google-services.json.
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
      _isInitialized = true;
    } catch (e) {
      debugPrint('Firebase initialization notice: $e');
    }
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Ensures user is authenticated with Firebase Auth corresponding to Supabase UID
  static Future<String?> ensureFirebaseAuth(String supabaseUid) async {
    if (supabaseUid.isEmpty) return null;
    await initialize();

    final currentUser = auth.currentUser;
    if (currentUser != null && currentUser.uid == supabaseUid) {
      return currentUser.uid;
    }

    final bridgeEmail = '${supabaseUid.toLowerCase()}@focusflow.internal';
    final bridgePassword = 'FF_Bridge_${supabaseUid}_2026!';

    try {
      final creds = await auth.signInWithEmailAndPassword(
        email: bridgeEmail,
        password: bridgePassword,
      );
      return creds.user?.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'channel-error') {
        try {
          final creds = await auth.createUserWithEmailAndPassword(
            email: bridgeEmail,
            password: bridgePassword,
          );
          return creds.user?.uid;
        } catch (createErr) {
          debugPrint('Error creating Firebase bridge user: $createErr');
          try {
            final creds = await auth.signInWithEmailAndPassword(
              email: bridgeEmail,
              password: bridgePassword,
            );
            return creds.user?.uid;
          } catch (_) {
            return null;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error in Firebase auth bridge: $e');
      return null;
    }
  }
}
