// Tests for ProfileCubit: loading the 3 numbers and changing the name.
// Run with: fvm flutter test test/features/auth/logic/profile_cubit_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/auth/data/models/user_profile_model.dart';
import 'package:brainly_life/features/auth/data/models/user_settings_model.dart';
import 'package:brainly_life/features/auth/data/repositories/auth_repository.dart';
import 'package:brainly_life/features/auth/data/repositories/profile_stats_provider.dart';
import 'package:brainly_life/features/auth/logic/profile_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepo extends Mock implements AuthRepository {}

class FailingStats implements ProfileStatsProvider {
  @override
  Future<Result<ProfileStats>> load() async =>
      const Result.failure(NetworkFailure());
}

void main() {
  late MockAuthRepo repository;
  late UserProfile user;
  late List<UserProfile> published;

  setUp(() {
    repository = MockAuthRepo();
    published = [];
    user = UserProfile(
      uid: 'u1',
      email: 'a@b.com',
      displayName: 'Shahd',
      createdAt: DateTime.utc(2026, 1, 1),
      settings: UserSettings.defaults(),
    );
  });

  ProfileCubit build({ProfileStatsProvider? stats}) => ProfileCubit(
    repository: repository,
    statsProvider: stats ?? const MockProfileStatsProvider(),
    currentUser: () => user,
    onProfileUpdated: (profile) {
      user = profile;
      published.add(profile);
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    'loadStats shows the numbers',
    build: build,
    act: (cubit) => cubit.loadStats(),
    expect: () => [
      const ProfileState(
        stats: ProfileStats(
          streakDays: 12,
          studiedMinutes: 18 * 60,
          tasksDone: 42,
        ),
      ),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'loadStats failing shows zeros (no error)',
    build: () => build(stats: FailingStats()),
    act: (cubit) => cubit.loadStats(),
    expect: () => [const ProfileState(stats: ProfileStats.empty)],
  );

  blocTest<ProfileCubit, ProfileState>(
    'updateName saves the trimmed name and gives it to AuthCubit',
    setUp: () => when(
      () => repository.updateDisplayName(any()),
    ).thenAnswer((_) async => const Result<void>.success(null)),
    build: build,
    act: (cubit) async => expect(await cubit.updateName('  Nour  '), isTrue),
    expect: () => [
      const ProfileState(isSavingName: true),
      const ProfileState(),
    ],
    verify: (_) {
      verify(() => repository.updateDisplayName('Nour')).called(1);
      expect(published.single.displayName, 'Nour');
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    'updateName with an empty name does nothing',
    build: build,
    act: (cubit) async => expect(await cubit.updateName('   '), isFalse),
    expect: () => <ProfileState>[],
    verify: (_) => verifyNever(() => repository.updateDisplayName(any())),
  );

  blocTest<ProfileCubit, ProfileState>(
    'updateName failing keeps the old name and shows the error',
    setUp: () => when(
      () => repository.updateDisplayName(any()),
    ).thenAnswer((_) async => const Result<void>.failure(NetworkFailure())),
    build: build,
    act: (cubit) async => expect(await cubit.updateName('Nour'), isFalse),
    expect: () => [
      const ProfileState(isSavingName: true),
      const ProfileState(failure: NetworkFailure(), failureId: 1),
    ],
    verify: (_) {
      expect(published, isEmpty);
      expect(user.displayName, 'Shahd');
    },
  );

  group('updateAvatar', () {
    blocTest<ProfileCubit, ProfileState>(
      'saves the avatar and gives the new profile to AuthCubit',
      setUp: () => when(
        () => repository.updateAvatar(any()),
      ).thenAnswer((_) async => const Result<void>.success(null)),
      build: build,
      act: (cubit) async => expect(await cubit.updateAvatar('rocket'), isTrue),
      expect: () => [
        const ProfileState(isSavingName: true),
        const ProfileState(),
      ],
      verify: (_) {
        verify(() => repository.updateAvatar('rocket')).called(1);
        expect(published.single.avatarId, 'rocket');
      },
    );

    blocTest<ProfileCubit, ProfileState>(
      'null removes the avatar',
      setUp: () {
        user = user.copyWith(avatarId: 'book');
        when(
          () => repository.updateAvatar(any()),
        ).thenAnswer((_) async => const Result<void>.success(null));
      },
      build: build,
      act: (cubit) async => expect(await cubit.updateAvatar(null), isTrue),
      verify: (_) => expect(published.single.avatarId, isNull),
    );

    blocTest<ProfileCubit, ProfileState>(
      'the same avatar again does nothing',
      setUp: () => user = user.copyWith(avatarId: 'star'),
      build: build,
      act: (cubit) async => expect(await cubit.updateAvatar('star'), isTrue),
      expect: () => <ProfileState>[],
      verify: (_) => verifyNever(() => repository.updateAvatar(any())),
    );

    blocTest<ProfileCubit, ProfileState>(
      'a failed save keeps the old avatar and shows the error',
      setUp: () => when(
        () => repository.updateAvatar(any()),
      ).thenAnswer((_) async => const Result<void>.failure(NetworkFailure())),
      build: build,
      act: (cubit) async => expect(await cubit.updateAvatar('rocket'), isFalse),
      expect: () => [
        const ProfileState(isSavingName: true),
        const ProfileState(failure: NetworkFailure(), failureId: 1),
      ],
      verify: (_) => expect(published, isEmpty),
    );
  });
}
