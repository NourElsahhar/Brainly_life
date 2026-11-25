// App entry point. TEMPORARY: error handling and the router
// will be added here later.
//
// Run with fake data:   fvm flutter run --dart-define=USE_MOCKS=true
// Run with Firebase:    fvm flutter run

import 'dart:ui' as ui;

import 'package:brainly_life/core/constants/app_config.dart';
import 'package:brainly_life/core/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _catchUnexpectedErrors();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (AppConfig.useEmulator && !AppConfig.useMocks) {
    await _connectToEmulators(AppConfig.emulatorHost);
  }
  await configureDependencies();
  runApp(const BrainlyLifeApp());
}

/// Points Auth, Firestore and Functions at the local Firebase Emulator
/// (ports from firebase.json). Must run before anything uses Firebase.
Future<void> _connectToEmulators(String host) async {
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
}

/// Errors nobody caught: logged in ONE place instead of crashing silently.
///   - FlutterError.onError: errors while building or drawing widgets
///     (in debug the red screen still shows, so you can fix it)
///   - PlatformDispatcher.onError: errors in async code (futures, streams)
/// Later a crash reporter (for example Crashlytics) is added here only.
void _catchUnexpectedErrors() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'Flutter error',
      tag: 'Crash',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error(
      'Uncaught async error',
      tag: 'Crash',
      error: error,
      stackTrace: stack,
    );
    return true; // handled: the app keeps running
  };
}
