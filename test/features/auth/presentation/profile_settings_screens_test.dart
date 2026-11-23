// Widget tests for ProfileScreen and SettingsScreen with a signed-in mock
// user: the header, the numbers, editing the name, changing settings,
// signing out and deleting the account.
// Run with: fvm flutter test test/features/auth/presentation/profile_settings_screens_test.dart

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/auth/data/models/user_settings_model.dart';
import 'package:brainly_life/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:brainly_life/features/auth/data/repositories/profile_stats_provider.dart';
import 'package:brainly_life/features/auth/logic/auth_cubit.dart';
import 'package:brainly_life/features/auth/logic/auth_state.dart';
import 'package:brainly_life/features/auth/presentation/screens/profile_screen.dart';
import 'package:brainly_life/features/auth/presentation/screens/settings_screen.dart';
import 'package:brainly_life/features/auth/presentation/widgets/delete_account_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'auth_test_app.dart';

void main() {
  late MockAuthRepository repository;

  Future<AuthCubit> pumpScreen(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    repository = MockAuthRepository(startSignedIn: true);
    final cubit = AuthCubit(repository);
    addTearDown(cubit.close);

    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) => ProfileScreen(
            repository: repository,
            statsProvider: const MockProfileStatsProvider(),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, _) => SettingsScreen(repository: repository),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => const Text('login page'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: cubit,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  group('ProfileScreen', () {
    testWidgets('shows the user, the 3 numbers and the menu', (tester) async {
      await pumpScreen(tester, AppRoutes.profile);

      expect(find.text('Demo Student'), findsOneWidget);
      expect(find.text(MockAuthRepository.demoEmail), findsOneWidget);
      expect(find.text('D'), findsOneWidget); // the first letter
      expect(find.text('12'), findsOneWidget);
      expect(find.text('18 h'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text(AppStrings.profileWeeklyAnalytics), findsOneWidget);
      expect(find.text(AppStrings.profileWeeklyReport), findsOneWidget);
    });

    testWidgets('Edit profile changes the name everywhere', (tester) async {
      final cubit = await pumpScreen(tester, AppRoutes.profile);

      await tapAndSettle(tester, find.text(AppStrings.profileEdit));
      await tester.enterText(find.byType(TextField).last, 'Shahd Adel');
      await tapAndSettle(tester, find.text(AppStrings.profileSave));

      expect(find.text('Shahd Adel'), findsOneWidget);
      expect(find.text(AppStrings.profileNameSaved), findsOneWidget);
      expect(cubit.currentUser?.displayName, 'Shahd Adel');
    });

    testWidgets('an empty name is refused in the sheet', (tester) async {
      await pumpScreen(tester, AppRoutes.profile);

      await tapAndSettle(tester, find.text(AppStrings.profileEdit));
      await tester.enterText(find.byType(TextField).last, '   ');
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('Settings opens on top, and back returns to Profile', (
      tester,
    ) async {
      await pumpScreen(tester, AppRoutes.profile);

      await tapAndSettle(tester, find.text(AppStrings.profileSettings).last);
      expect(find.byType(SettingsScreen), findsOneWidget);

      await tapAndSettle(tester, find.byType(BackButton));
      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('the gear in the bar opens Settings too', (tester) async {
      await pumpScreen(tester, AppRoutes.profile);

      await tapAndSettle(tester, find.byTooltip(AppStrings.profileSettings));

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('SettingsScreen', () {
    testWidgets('shows the current values', (tester) async {
      await pumpScreen(tester, AppRoutes.settings);

      expect(find.text('2 h'), findsOneWidget); // default daily hours
      expect(find.text(AppStrings.studyTimeEvening), findsOneWidget);
      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('UTC'), findsOneWidget);
    });

    testWidgets('picking Dark changes the theme setting at once', (
      tester,
    ) async {
      final cubit = await pumpScreen(tester, AppRoutes.settings);

      await tapAndSettle(tester, find.text(AppStrings.settingsThemeDark));

      expect(cubit.currentUser?.settings.themeMode, AppThemeMode.dark);
    });

    testWidgets('daily study hours are picked from a sheet', (tester) async {
      final cubit = await pumpScreen(tester, AppRoutes.settings);

      await tapAndSettle(tester, find.text(AppStrings.settingsDailyHours));
      await tapAndSettle(tester, find.text('4 h'));

      expect(cubit.currentUser?.settings.dailyStudyHours, 4);
      expect(find.text('4 h'), findsOneWidget);
    });

    testWidgets('the AI switch turns AI off', (tester) async {
      final cubit = await pumpScreen(tester, AppRoutes.settings);

      await tapAndSettle(tester, find.byType(Switch));

      expect(cubit.currentUser?.settings.aiEnabled, isFalse);
    });

    testWidgets('Sign out signs the user out', (tester) async {
      final cubit = await pumpScreen(tester, AppRoutes.settings);

      await tapAndSettle(tester, find.text(AppStrings.settingsSignOut));

      expect(cubit.state, isA<Unauthenticated>());
    });

    testWidgets('Delete only works after typing DELETE', (tester) async {
      final cubit = await pumpScreen(tester, AppRoutes.settings);

      await tapAndSettle(tester, find.text(AppStrings.settingsDeleteAccount));
      expect(find.byType(DeleteAccountDialog), findsOneWidget);

      // Wrong word: the button does nothing.
      await tester.enterText(find.byType(TextField), 'delete it');
      await tester.pump();
      await tester.tap(find.text(AppStrings.deleteAction).last);
      await tester.pumpAndSettle();
      expect(find.byType(DeleteAccountDialog), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pump();
      await tapAndSettle(tester, find.text(AppStrings.deleteAction).last);

      expect(find.byType(DeleteAccountDialog), findsNothing);
      expect(cubit.state, isA<Unauthenticated>());
    });

    testWidgets('Cancel keeps the account', (tester) async {
      final cubit = await pumpScreen(tester, AppRoutes.settings);

      await tapAndSettle(tester, find.text(AppStrings.settingsDeleteAccount));
      await tapAndSettle(tester, find.text(AppStrings.deleteCancel));

      expect(find.byType(DeleteAccountDialog), findsNothing);
      expect(cubit.state, isA<Authenticated>());
    });
  });
}
