// Checks that the snackbar, the dialog, the error view and the skeletons
// look like the Canva design (UI components sheet).
// Run with: fvm flutter test test/core/widgets/feedback_widgets_look_test.dart

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Shows [child] with a button "Open" that runs [onOpen].
  Future<void> pumpWith(
    WidgetTester tester, {
    Widget? child,
    void Function(BuildContext context)? onOpen,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                child ??
                TextButton(
                  onPressed: () => onOpen!(context),
                  child: const Text('Open'),
                ),
          ),
        ),
      ),
    );
  }

  Future<void> openWith(
    WidgetTester tester,
    void Function(BuildContext context) onOpen,
  ) async {
    await pumpWith(tester, onOpen: onOpen);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('AppSnackBar', () {
    testWidgets('success is a dark bar', (tester) async {
      await openWith(tester, (c) => AppSnackBar.success(c, 'Task saved'));

      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(bar.backgroundColor, AppPalette.dark.surfaceRaised);
    });

    testWidgets('error is a red bar', (tester) async {
      await openWith(tester, (c) => AppSnackBar.error(c, 'Could not save'));

      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(bar.backgroundColor, AppPalette.light.error);
    });
  });

  group('ConfirmDialog', () {
    testWidgets('has two text buttons, the destructive one is red', (
      tester,
    ) async {
      await openWith(
        tester,
        (c) => ConfirmDialog.show(
          c,
          title: 'Delete task?',
          message: 'This cannot be undone.',
          confirmLabel: 'Delete',
          isDestructive: true,
        ),
      );

      expect(find.byType(TextButton), findsNWidgets(3)); // + "Open"
      final delete = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Delete'),
      );
      expect(
        delete.style?.foregroundColor?.resolve(<WidgetState>{}),
        AppPalette.light.error,
      );
    });
  });

  group('ErrorView', () {
    testWidgets('Try again is a primary (filled) button', (tester) async {
      await pumpWith(
        tester,
        child: ErrorView(failure: const UnknownFailure(), onRetry: () {}),
      );

      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.type, AppButtonType.primary);
    });
  });

  group('Skeletons', () {
    testWidgets('SkeletonLines draws one bar per width', (tester) async {
      await pumpWith(
        tester,
        child: const SkeletonLines(widths: [0.9, 0.6, 0.3]),
      );

      expect(find.byType(FractionallySizedBox), findsNWidgets(3));
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    });

    testWidgets('SkeletonCard is a card with three bars', (tester) async {
      await pumpWith(tester, child: const SkeletonCard());

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.byType(FractionallySizedBox), findsNWidgets(3));
    });
  });
}

