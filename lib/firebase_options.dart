import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Configuration Firebase générée pour le projet Tracker Fleet.
///
/// ⚠️  IMPORTANT : Remplacez les valeurs `TODO` ci-dessous par les clés
/// de votre propre projet Firebase. Vous pouvez les trouver dans la
/// console Firebase → Paramètres du projet → Vos applications.
///
/// Alternativement, exécutez la commande FlutterFire CLI :
/// ```bash
/// dart pub global activate flutterfire_cli
/// flutterfire configure
/// ```
/// pour régénérer automatiquement ce fichier.
class DefaultFirebaseOptions {
  /// Retourne les [FirebaseOptions] correspondant à la plateforme courante.
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
          'DefaultFirebaseOptions is not configured for Linux.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions is not configured for Fuchsia.',
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Web
  // ---------------------------------------------------------------------------
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TODO_YOUR_WEB_API_KEY',
    appId: 'TODO_YOUR_WEB_APP_ID',
    messagingSenderId: 'TODO_YOUR_MESSAGING_SENDER_ID',
    projectId: 'TODO_YOUR_PROJECT_ID',
    authDomain: 'TODO_YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'TODO_YOUR_PROJECT_ID.firebasestorage.app',
  );

  // ---------------------------------------------------------------------------
  // Android
  // ---------------------------------------------------------------------------
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TODO_YOUR_ANDROID_API_KEY',
    appId: 'TODO_YOUR_ANDROID_APP_ID',
    messagingSenderId: 'TODO_YOUR_MESSAGING_SENDER_ID',
    projectId: 'TODO_YOUR_PROJECT_ID',
    storageBucket: 'TODO_YOUR_PROJECT_ID.firebasestorage.app',
  );

  // ---------------------------------------------------------------------------
  // iOS
  // ---------------------------------------------------------------------------
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TODO_YOUR_IOS_API_KEY',
    appId: 'TODO_YOUR_IOS_APP_ID',
    messagingSenderId: 'TODO_YOUR_MESSAGING_SENDER_ID',
    projectId: 'TODO_YOUR_PROJECT_ID',
    storageBucket: 'TODO_YOUR_PROJECT_ID.firebasestorage.app',
    iosBundleId: 'com.example.trackerFlutter',
  );

  // ---------------------------------------------------------------------------
  // macOS
  // ---------------------------------------------------------------------------
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'TODO_YOUR_MACOS_API_KEY',
    appId: 'TODO_YOUR_MACOS_APP_ID',
    messagingSenderId: 'TODO_YOUR_MESSAGING_SENDER_ID',
    projectId: 'TODO_YOUR_PROJECT_ID',
    storageBucket: 'TODO_YOUR_PROJECT_ID.firebasestorage.app',
    iosBundleId: 'com.example.trackerFlutter',
  );

  // ---------------------------------------------------------------------------
  // Windows
  // ---------------------------------------------------------------------------
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'TODO_YOUR_WINDOWS_API_KEY',
    appId: 'TODO_YOUR_WINDOWS_APP_ID',
    messagingSenderId: 'TODO_YOUR_MESSAGING_SENDER_ID',
    projectId: 'TODO_YOUR_PROJECT_ID',
    authDomain: 'TODO_YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'TODO_YOUR_PROJECT_ID.firebasestorage.app',
  );
}
