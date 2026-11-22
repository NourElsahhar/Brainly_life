// Tests for SplashScreen.
// Run with: fvm flutter test test/features/auth/presentation/splash_screen_test.dart

import 'package:brainly_life/core/theme/app_theme.dart';
import 'package:brainly_life/features/auth/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpSplash(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    VoidCallback? onFinished,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
        home: SplashScreen(onFinished: onFinished),
      ),
    );
  }

  // The opacity of the closest FadeTransition around [child].
  double opacityOf(WidgetTester tester, Finder child) {
    final fade = find
        .ancestor(of: child, matching: find.byType(FadeTransition))
        .first;
    return tester.widget<FadeTransition>(fade).opacity.value;
  }

  group('SplashScreen', () {
    testWidgets('has the name, the tagline, the logo and the spinner',
        (tester) async {
      await pumpSplash(tester);

      expect(find.text('Baseet'), findsOneWidget);
      expect(find.text('Your day, made simpler.'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

        testWidgets('everything fades in, in order', (tester) async {
      await pumpSplash(tester);
      final name = find.text('Baseet');
      final tagline = find.text('Your day, made simpler.');

      expect(opacityOf(tester, name), 0);
      expect(opacityOf(tester, tagline), 0);

      // Halfway through the animation. This works for any SplashScreen.duration.
      await tester.pump(SplashScreen.duration * 0.5);
      expect(opacityOf(tester, name), greaterThan(0.5));
      expect(opacityOf(tester, tagline), lessThan(opacityOf(tester, name)));

      await tester.pump(SplashScreen.duration);
      expect(opacityOf(tester, name), 1);
      expect(opacityOf(tester, tagline), 1);
    });
    testWidgets('calls onFinished once, after the full duration',
        (tester) async {
      var finished = 0;
      await pumpSplash(tester, onFinished: () => finished++);

      await tester.pump(
        SplashScreen.duration - const Duration(milliseconds: 100),
      );
      expect(finished, 0);

      await tester.pump(const Duration(milliseconds: 200));
      expect(finished, 1);

      await tester.pump(const Duration(seconds: 2));
      expect(finished, 1);
    });

    testWidgets('works without onFinished', (tester) async {
      await pumpSplash(tester);

      await tester.pump(SplashScreen.duration);

      expect(tester.takeException(), isNull);
    });

    testWidgets('uses the light logo in light mode', (tester) async {
      await pumpSplash(tester);

      final image = tester.widget<Image>(find.byType(Image)).image;
      expect((image as AssetImage).assetName, SplashScreen.lightLogo);
    });

    testWidgets('uses the dark logo in dark mode', (tester) async {
      await pumpSplash(tester, brightness: Brightness.dark);

      final image = tester.widget<Image>(find.byType(Image)).image;
      expect((image as AssetImage).assetName, SplashScreen.darkLogo);
    });
  });
}