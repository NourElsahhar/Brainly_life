// Checks that the logo files used by the splash screen exist
// and are declared in pubspec.yaml.
// Run with: fvm flutter test test/core/theme/branding_assets_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const logos = [
    'assets/branding/baseet_logo_light.png',
    'assets/branding/baseet_logo_dark.png',
  ];

  test('the splash logo files exist', () {
    for (final path in logos) {
      expect(File(path).existsSync(), isTrue, reason: 'Missing file: $path');
    }
  });

  test('the splash logo files are declared in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    for (final path in logos) {
      expect(pubspec.contains(path), isTrue, reason: '$path is not declared');
    }
  });
}