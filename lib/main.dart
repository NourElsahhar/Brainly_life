// App entry point. TEMPORARY: error handling and the router
// will be added here later.
//
// Run with fake data:   fvm flutter run --dart-define=USE_MOCKS=true
// Run with Firebase:    fvm flutter run

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await configureDependencies();
  runApp(const BrainlyLifeApp());
}