// Tests for Debouncer.
// Run with: fvm flutter test test/core/utils/debouncer_test.dart

import 'package:brainly_life/core/utils/debouncer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const delay = Duration(milliseconds: 300);

  group('Debouncer', () {
    testWidgets('runs the action after the delay', (tester) async {
      final debouncer = Debouncer(delay: delay);
      var calls = 0;

      debouncer.run(() => calls++);
      await tester.pump(const Duration(milliseconds: 299));
      expect(calls, 0);

      await tester.pump(const Duration(milliseconds: 2));
      expect(calls, 1);
    });

    testWidgets('a new call cancels the waiting one', (tester) async {
      final debouncer = Debouncer(delay: delay);
      final results = <String>[];

      debouncer.run(() => results.add('a'));
      await tester.pump(const Duration(milliseconds: 100));
      debouncer.run(() => results.add('ab'));
      await tester.pump(const Duration(milliseconds: 100));
      debouncer.run(() => results.add('abc'));

      await tester.pump(const Duration(milliseconds: 301));

      expect(results, ['abc']);
    });

    testWidgets('cancel stops the action', (tester) async {
      final debouncer = Debouncer(delay: delay);
      var calls = 0;

      debouncer.run(() => calls++);
      debouncer.cancel();
      await tester.pump(const Duration(seconds: 1));

      expect(calls, 0);
    });

    testWidgets('dispose stops the action', (tester) async {
      final debouncer = Debouncer(delay: delay);
      var calls = 0;

      debouncer.run(() => calls++);
      debouncer.dispose();
      await tester.pump(const Duration(seconds: 1));

      expect(calls, 0);
    });

    testWidgets('can be used again after it ran', (tester) async {
      final debouncer = Debouncer(delay: delay);
      var calls = 0;

      debouncer.run(() => calls++);
      await tester.pump(const Duration(milliseconds: 301));
      debouncer.run(() => calls++);
      await tester.pump(const Duration(milliseconds: 301));

      expect(calls, 2);
    });
  });
}
