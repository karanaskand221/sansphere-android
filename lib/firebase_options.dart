import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyB64J31BsWmjtltHKAX1C7pAyAi_7hnM5I",
    authDomain: "gen-lang-client-0227443307.firebaseapp.com",
    projectId: "gen-lang-client-0227443307",
    storageBucket: "gen-lang-client-0227443307.firebasestorage.app",
    messagingSenderId: "1070172783321",
    appId: "1:1070172783321:web:aed160f259e7195ffb74c8",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyAwmf5jsIwxeczBUePW1iWSt9Xodor06RU",
    authDomain: "gen-lang-client-0227443307.firebaseapp.com",
    projectId: "gen-lang-client-0227443307",
    storageBucket: "gen-lang-client-0227443307.firebasestorage.app",
    messagingSenderId: "1070172783321",
    appId: "1:1070172783321:android:7580f33ec2dd10e0fb74c8",
  );
}
