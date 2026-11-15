// Tests for LoadingView, ErrorView and EmptyView.
// Run with: fvm flutter test test/core/widgets/state_views_test.dart

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/empty_view.dart';
import 'package:brainly_life/core/widgets/error_view.dart';
import 'package:brainly_life/core/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpView(WidgetTester tester, Widget view) {
    return tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: Scaffold(body: view)),
    );
  }

  group('LoadingView', () {
    testWidgets('shows a spinner', (tester) async {
      await pumpView(tester, const LoadingView());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the message when given', (tester) async {
      await pumpView(tester, const LoadingView(message: 'Please wait'));

      expect(find.text('Please wait'), findsOneWidget);
    });
  });

  group('ErrorView', () {
    testWidgets('shows the failure message', (tester) async {
      await pumpView(tester, const ErrorView(failure: UnknownFailure()));

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text(const UnknownFailure().userMessage), findsOneWidget);
    });

    testWidgets('a network failure has its own title', (tester) async {
      await pumpView(tester, const ErrorView(failure: NetworkFailure()));

      expect(find.text('No connection'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('retry button calls onRetry', (tester) async {
      var retries = 0;
      await pumpView(
        tester,
        ErrorView(failure: const UnknownFailure(), onRetry: () => retries++),
      );

      await tester.tap(find.text('Try again'));
      await tester.pump();

      expect(retries, 1);
    });

    testWidgets('no retry button without onRetry', (tester) async {
      await pumpView(tester, const ErrorView(failure: UnknownFailure()));

      expect(find.text('Try again'), findsNothing);
    });
  });

  group('EmptyView', () {
    testWidgets('shows the title and the message', (tester) async {
      await pumpView(
        tester,
        const EmptyView(
          icon: Icons.inbox_outlined,
          title: 'No tasks today',
          message: 'Enjoy your free time',
        ),
      );

      expect(find.text('No tasks today'), findsOneWidget);
      expect(find.text('Enjoy your free time'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('action button calls onAction', (tester) async {
      var taps = 0;
      await pumpView(
        tester,
        EmptyView(
          icon: Icons.add,
          title: 'No subjects',
          actionLabel: 'Add subject',
          onAction: () => taps++,
        ),
      );

      await tester.tap(find.text('Add subject'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('no button when there is no action', (tester) async {
      await pumpView(
        tester,
        const EmptyView(icon: Icons.add, title: 'No subjects'),
      );

      expect(find.byType(InkWell), findsNothing);
    });
  });
}