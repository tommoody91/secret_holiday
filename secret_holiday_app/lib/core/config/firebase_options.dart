import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration options
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCK8-9_7lplVm3azEvR_Tz2EHIVT21F7BQ',
    appId: '1:744352475732:web:abc123def456789012345',
    messagingSenderId: '744352475732',
    projectId: 'secret-holiday',
    storageBucket: 'secret-holiday.firebasestorage.app',
    authDomain: 'secret-holiday.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCK8-9_7lplVm3azEvR_Tz2EHIVT21F7BQ',
    appId: '1:744352475732:android:be9e04291a3738e50a5bc1',
    messagingSenderId: '744352475732',
    projectId: 'secret-holiday',
    storageBucket: 'secret-holiday.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDvrsxGhnayw80xivbxbQ5fokTINOLiDgs',
    appId: '1:744352475732:ios:694855d7a5a0118e0a5bc1',
    messagingSenderId: '744352475732',
    projectId: 'secret-holiday',
    iosBundleId: 'com.poncha25.secret-holiday',
    storageBucket: 'secret-holiday.firebasestorage.app',
  );
}
