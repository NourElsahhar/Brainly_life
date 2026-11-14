// Checks that every font file we use is really in the project
// and is declared in pubspec.yaml.
// Run with: fvm flutter test test/core/theme/fonts_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const fontFiles = [
    'PlusJakartaSans-SemiBold.ttf',
    'PlusJakartaSans-Bold.ttf',
    'PlusJakartaSans-ExtraBold.ttf',
    'Inter-Regular.ttf',
    'Inter-Medium.ttf',
    'Cairo-Regular.ttf',
    'Cairo-Medium.ttf',
    'Cairo-SemiBold.ttf',
    'Cairo-Bold.ttf',
  ];

  group('Fonts', () {
    test('every font file exists in assets/fonts', () {
      for (final name in fontFiles) {
        expect(
          File('assets/fonts/$name').existsSync(),
          isTrue,
          reason: 'Missing font file: assets/fonts/$name',
        );
      }
    });

    test('every font file is declared in pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      for (final name in fontFiles) {
        expect(
          pubspec.contains('assets/fonts/$name'),
          isTrue,
          reason: '$name is not declared in pubspec.yaml',
        );
      }
    });

    test('the three font families are declared', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(pubspec.contains('family: PlusJakartaSans'), isTrue);
      expect(pubspec.contains('family: Inter'), isTrue);
      expect(pubspec.contains('family: Cairo'), isTrue);
    });
  });
}