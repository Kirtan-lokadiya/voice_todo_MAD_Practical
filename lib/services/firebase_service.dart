import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseOptions _firebaseOptions = FirebaseOptions(
    apiKey: "AIzaSyBtZCC8V8QLbpqUwaQB0T9kWcz3muPGEi4",
    authDomain: "to-do-c0a79.firebaseapp.com",
    projectId: "to-do-c0a79",
    storageBucket: "to-do-c0a79.firebasestorage.app",
    messagingSenderId: "531450384054",
    appId: "1:531450384054:web:6bcc7c7fe2f97e867f6017",
    measurementId: "G-EF27S2RVWD",
  );

  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: _firebaseOptions,
      );
      if (kDebugMode) {
        print('Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase: $e');
      }
    }
  }
} 