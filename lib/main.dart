// App entry point. TEMPORARY: DI, error handling and the router
// will be added here later.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BrainlyLifeApp());
}


// git add -A
// git commit -m "feat: add Material 3 light and dark theme"
// git push -u origin feature/m1-theme