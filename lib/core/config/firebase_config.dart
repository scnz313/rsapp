import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '/firebase_options.dart';
import 'firebase_auth_config.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    try {
      // Initialize Firebase core first
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Configure Firebase Auth specifically
      await FirebaseAuthConfig.configure();
      
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      rethrow;
    }
  }
}
