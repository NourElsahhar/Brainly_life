// Tests for UserSettings and UserProfile.
// Run with: fvm flutter test test/features/auth/data/models/user_profile_model_test.dart

import 'package:brainly_life/features/auth/data/models/user_profile_model.dart';
import 'package:brainly_life/features/auth/data/models/user_settings_model.dart';
import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserSettings', () {
    test('defaults', () {
      final settings = UserSettings.defaults();

      expect(settings.dailyStudyHours, 2);
      expect(settings.preferredStudyTime, StudyTime.evening);
      expect(settings.weekStartDay, DateTime.monday);
      expect(settings.timezone, 'UTC');
      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.aiEnabled, isTrue);
    });

    test('defaults can take the user timezone', () {
      expect(
        UserSettings.defaults(timezone: 'Africa/Cairo').timezone,
        'Africa/Cairo',
      );
    });

    test('fromMap reads every field', () {
      final settings = UserSettings.fromMap({
        'dailyStudyHours': 3.5,
        'preferredStudyTime': 'morning',
        'weekStartDay': 6,
        'timezone': 'Africa/Cairo',
        'themeMode': 'dark',
        'aiEnabled': false,
      });

      expect(settings.dailyStudyHours, 3.5);
      expect(settings.preferredStudyTime, StudyTime.morning);
      expect(settings.weekStartDay, 6);
      expect(settings.timezone, 'Africa/Cairo');
      expect(settings.themeMode, AppThemeMode.dark);
      expect(settings.aiEnabled, isFalse);
    });

    test('a whole number of hours is accepted (Firestore int)', () {
      expect(UserSettings.fromMap({'dailyStudyHours': 4}).dailyStudyHours, 4);
    });

    test('null or empty map gives the defaults', () {
      expect(UserSettings.fromMap(null), UserSettings.defaults());
      expect(UserSettings.fromMap(const {}), UserSettings.defaults());
    });

    test('wrong values fall back to the defaults', () {
      final settings = UserSettings.fromMap({
        'dailyStudyHours': 'lots',
        'preferredStudyTime': 5,
        'weekStartDay': 9,
        'timezone': '',
        'themeMode': 'purple',
        'aiEnabled': 'yes',
      });

      expect(settings, UserSettings.defaults());
    });

    test('toMap and fromMap give the same settings back', () {
      const settings = UserSettings(
        dailyStudyHours: 5,
        preferredStudyTime: StudyTime.night,
        weekStartDay: DateTime.saturday,
        timezone: 'Africa/Cairo',
        themeMode: AppThemeMode.light,
        aiEnabled: false,
      );

      expect(UserSettings.fromMap(settings.toMap()), settings);
    });

    test('toMap uses lowercase names for enums', () {
      final map = UserSettings.defaults().toMap();

      expect(map['preferredStudyTime'], 'evening');
      expect(map['themeMode'], 'system');
    });

    test('copyWith changes only what you ask', () {
      final settings = UserSettings.defaults().copyWith(aiEnabled: false);

      expect(settings.aiEnabled, isFalse);
      expect(settings.themeMode, AppThemeMode.system);
    });
  });

  group('UserProfile', () {
    final createdAt = DateTime.utc(2026, 11, 19, 10);

    UserProfile sample() => UserProfile(
          uid: 'u1',
          displayName: 'Nour',
          email: 'nour@example.com',
          photoUrl: 'https://example.com/me.png',
          createdAt: createdAt,
          settings: UserSettings.defaults(timezone: 'Africa/Cairo'),
        );

    test('fromMap reads every field', () {
      final profile = UserProfile.fromMap('u1', {
        'displayName': 'Nour',
        'email': 'nour@example.com',
        'photoUrl': 'https://example.com/me.png',
        'createdAt': Timestamp.fromDate(createdAt),
        'settings': {'timezone': 'Africa/Cairo'},
      });

      expect(profile.uid, 'u1');
      expect(profile.displayName, 'Nour');
      expect(profile.email, 'nour@example.com');
      expect(profile.photoUrl, 'https://example.com/me.png');
      expect(profile.createdAt, createdAt);
      expect(profile.settings.timezone, 'Africa/Cairo');
    });

    test('null data gives safe empty values', () {
      final profile = UserProfile.fromMap('u1', null);

      expect(profile.uid, 'u1');
      expect(profile.displayName, '');
      expect(profile.email, '');
      expect(profile.photoUrl, isNull);
      expect(profile.settings, UserSettings.defaults());
    });

    test('a pending createdAt uses the current time', () {
      withClock(Clock.fixed(DateTime.utc(2026, 1, 1)), () {
        final profile = UserProfile.fromMap('u1', {'email': 'a@b.com'});

        expect(profile.createdAt, DateTime.utc(2026, 1, 1));
      });
    });

    test('an empty photoUrl becomes null', () {
      expect(UserProfile.fromMap('u1', {'photoUrl': ''}).photoUrl, isNull);
    });

    test('toFirestore has the fields and not createdAt, updatedAt or uid', () {
      final data = sample().toFirestore();

      expect(data['displayName'], 'Nour');
      expect(data['email'], 'nour@example.com');
      expect(data['photoUrl'], 'https://example.com/me.png');
      expect(data['settings'], sample().settings.toMap());
      expect(data.containsKey('createdAt'), isFalse);
      expect(data.containsKey('updatedAt'), isFalse);
      expect(data.containsKey('uid'), isFalse);
    });

    test('write then read gives the same profile', () {
      final profile = sample();

      final back = UserProfile.fromMap('u1', {
        ...profile.toFirestore(),
        'createdAt': Timestamp.fromDate(profile.createdAt),
      });

      expect(back, profile);
    });

    test('copyWith changes only what you ask', () {
      final renamed = sample().copyWith(displayName: 'Sara');

      expect(renamed.displayName, 'Sara');
      expect(renamed.email, 'nour@example.com');
      expect(renamed.uid, 'u1');
      expect(renamed.createdAt, createdAt);
    });

    test('clearPhotoUrl removes the photo', () {
      expect(sample().copyWith(clearPhotoUrl: true).photoUrl, isNull);
      expect(sample().copyWith().photoUrl, 'https://example.com/me.png');
    });

    test('two profiles with the same data are equal', () {
      expect(sample(), sample());
      expect(sample(), isNot(sample().copyWith(displayName: 'Sara')));
    });
  });
}