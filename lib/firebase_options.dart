import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return androidOptions;
  }

  static const FirebaseOptions androidOptions = FirebaseOptions(
    apiKey: 'AIzaSyAGO7Y_lWJvs17ucP2PJWsWX3geiCDmE2Q',
    appId: '1:837379419254:android:cbb61771fc89cc1bc64357',
    messagingSenderId: '837379419254',
    projectId: 'realestate-cd6fb',
    storageBucket: 'realestate-cd6fb.appspot.com',
  );
}
