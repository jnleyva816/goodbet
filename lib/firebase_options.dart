// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDag94cdfX4nAiFuDGPBOFveAetjgoLiqA',
    appId: '1:551918089816:web:549d830a3920d80484fc2d',
    messagingSenderId: '551918089816',
    projectId: 'goodbet-5e52d',
    authDomain: 'goodbet-5e52d.firebaseapp.com',
    storageBucket: 'goodbet-5e52d.appspot.com',
    measurementId: 'G-3937ZFT3ED',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAdyGgQI9tqbBjyuzEcbCQj5NJNlB_dH_c',
    appId: '1:551918089816:android:048f6d307577ca4784fc2d',
    messagingSenderId: '551918089816',
    projectId: 'goodbet-5e52d',
    storageBucket: 'goodbet-5e52d.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC059Au1yQ8jMu4OV3c66isVcPzw1tG6wA',
    appId: '1:551918089816:ios:25ce57fa66c11aed84fc2d',
    messagingSenderId: '551918089816',
    projectId: 'goodbet-5e52d',
    storageBucket: 'goodbet-5e52d.appspot.com',
    iosBundleId: 'com.example.goodbet',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC059Au1yQ8jMu4OV3c66isVcPzw1tG6wA',
    appId: '1:551918089816:ios:25ce57fa66c11aed84fc2d',
    messagingSenderId: '551918089816',
    projectId: 'goodbet-5e52d',
    storageBucket: 'goodbet-5e52d.appspot.com',
    iosBundleId: 'com.example.goodbet',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDag94cdfX4nAiFuDGPBOFveAetjgoLiqA',
    appId: '1:551918089816:web:b05c90e1d70e14d584fc2d',
    messagingSenderId: '551918089816',
    projectId: 'goodbet-5e52d',
    authDomain: 'goodbet-5e52d.firebaseapp.com',
    storageBucket: 'goodbet-5e52d.appspot.com',
    measurementId: 'G-FEQD3SMFYM',
  );
}
