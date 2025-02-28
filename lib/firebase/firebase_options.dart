import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyAGO7Y_lWJvs17ucP2PJWsWX3geiCDmE2Q',
      appId: '1:837379419254:android:cbb61771fc89cc1bc64357',
      messagingSenderId: '837379419254',
      projectId: 'realestate-cd6fb',
      storageBucket: 'realestate-cd6fb.firebasestorage.app',
    );
  }

  // Development environment options
  static FirebaseOptions get development {
    return currentPlatform;
  }

  // Production environment options
  static FirebaseOptions get production {
    return currentPlatform;
  }

  // Prevent instantiation
  DefaultFirebaseOptions._();
}
