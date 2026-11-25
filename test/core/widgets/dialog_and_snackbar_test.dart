// Tests for ConfirmDialog and AppSnackBar.
// Run with: fvm flutter test test/core/widgets/dialog_and_snackbar_test.dart

import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/app_snack_bar.dart';
import 'package:brainly_life/core/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A screen with one button "Open" that runs [onTap] with a valid context.
  Future<void> pumpHost(
    WidgetTester tester,
    void Function(BuildContext context) onTap,
  ) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => onTap(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('ConfirmDialog', () {
    Future<void> openDialog(
      WidgetTester tester,
      void Function(bool value) onResult,
    ) async {
      await pumpHost(tester, (context) {
        ConfirmDialog.show(
          context,
          title: 'Delete task?',
          message: 'This cannot be undone.',
          confirmLabel: 'Delete',
          isDestructive: true,
        ).then(onResult);
      });
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the title, the message and both buttons', (
      tester,
    ) async {
      await openDialog(tester, (_) {});

      expect(find.text('Delete task?'), findsOneWidget);
      expect(find.text('This cannot be undone.'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('returns true when confirmed', (tester) async {
      bool? result;
      await openDialog(tester, (value) => result = value);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('returns false when cancelled', (tester) async {
      bool? result;
      await openDialog(tester, (value) => result = value);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('returns false when tapping outside', (tester) async {
      bool? result;
      await openDialog(tester, (value) => result = value);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });

  group('AppSnackBar', () {
    Future<void> showAndWait(WidgetTester tester) async {
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('success shows the message and a check icon', (tester) async {
      await pumpHost(
        tester,
        (context) => AppSnackBar.success(context, 'Task saved'),
      );
      await showAndWait(tester);

      expect(find.text('Task saved'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('error shows the message and an error icon', (tester) async {
      await pumpHost(
        tester,
        (context) => AppSnackBar.error(context, 'Could not save'),
      );
      await showAndWait(tester);

      expect(find.text('Could not save'), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    });

    testWidgets('info shows the message and an info icon', (tester) async {
      await pumpHost(tester, (context) => AppSnackBar.info(context, 'Synced'));
      await showAndWait(tester);

      expect(find.text('Synced'), findsOneWidget);
      expect(find.byIcon(Icons.info_rounded), findsOneWidget);
    });

    testWidgets('the action button calls onAction', (tester) async {
      var undone = 0;
      await pumpHost(
        tester,
        (context) => AppSnackBar.info(
          context,
          'Task deleted',
          actionLabel: 'Undo',
          onAction: () => undone++,
        ),
      );
      await showAndWait(tester);

      await tester.tap(find.text('Undo'));
      await tester.pump();

      expect(undone, 1);
    });
  });
}
