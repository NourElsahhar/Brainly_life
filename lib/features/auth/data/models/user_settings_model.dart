// UserSettings = the user's preferences. It is stored inside the user
// document, in the `settings` map: users/{uid}.settings
//
// Who reads which field:
//   - weekStartDay and timezone -> everyone, through WeekUtils / DateKeyUtils
//   - dailyStudyHours and preferredStudyTime -> the study planner (M2)
//   - themeMode -> app.dart (light / dark / system)
//   - aiEnabled -> the "Use AI features" switch (M5's AI client checks it)
//
// fromMap never crashes. A missing or wrong value becomes the default.
// The model is immutable. Change a value with copyWith.
//
// Usage:
//   final settings = UserSettings.defaults(timezone: 'Africa/Cairo');
//   final updated = settings.copyWith(aiEnabled: false);
//   final map = updated.toMap();                       // to save in Firestore
//   final back = UserSettings.fromMap(map);            // to read from Firestore

import 'package:equatable/equatable.dart';

enum StudyTime { morning, afternoon, evening, night }

enum AppThemeMode { system, light, dark }

class UserSettings extends Equatable {
  const UserSettings({
    required this.dailyStudyHours,
    required this.preferredStudyTime,
    required this.weekStartDay,
    required this.timezone,
    required this.themeMode,
    required this.aiEnabled,
  });

  /// The settings of a brand new user.
  /// [timezone] is an IANA name like 'Africa/Cairo'.
  factory UserSettings.defaults({String timezone = defaultTimezone}) {
    return UserSettings(
      dailyStudyHours: defaultDailyStudyHours,
      preferredStudyTime: StudyTime.evening,
      weekStartDay: DateTime.monday,
      timezone: timezone,
      themeMode: AppThemeMode.system,
      aiEnabled: true,
    );
  }

  /// Reads the `settings` map from Firestore.
  /// Missing or wrong values become the defaults.
  factory UserSettings.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};

    final hours = data['dailyStudyHours'];
    final weekStart = data['weekStartDay'];
    final timezone = data['timezone'];
    final aiEnabled = data['aiEnabled'];

    return UserSettings(
      dailyStudyHours: hours is num ? hours.toDouble() : defaultDailyStudyHours,
      preferredStudyTime: _parseEnum(
        StudyTime.values,
        data['preferredStudyTime'],
        StudyTime.evening,
      ),
      weekStartDay: weekStart is int && weekStart >= 1 && weekStart <= 7
          ? weekStart
          : DateTime.monday,
      timezone: timezone is String && timezone.isNotEmpty
          ? timezone
          : defaultTimezone,
      themeMode: _parseEnum(
        AppThemeMode.values,
        data['themeMode'],
        AppThemeMode.system,
      ),
      aiEnabled: aiEnabled is bool ? aiEnabled : true,
    );
  }

  static const String defaultTimezone = 'UTC';
  static const double defaultDailyStudyHours = 2;

  /// Hours the user wants to study per day.
  final double dailyStudyHours;
  final StudyTime preferredStudyTime;

  /// 1 = Monday ... 7 = Sunday (the same numbers as DateTime.monday ...).
  final int weekStartDay;

  /// IANA timezone name, for example 'Africa/Cairo'.
  final String timezone;
  final AppThemeMode themeMode;

  /// The "Use AI features" switch.
  final bool aiEnabled;

  /// The map saved in Firestore (inside users/{uid}.settings).
  Map<String, dynamic> toMap() {
    return {
      'dailyStudyHours': dailyStudyHours,
      'preferredStudyTime': preferredStudyTime.name,
      'weekStartDay': weekStartDay,
      'timezone': timezone,
      'themeMode': themeMode.name,
      'aiEnabled': aiEnabled,
    };
  }

  UserSettings copyWith({
    double? dailyStudyHours,
    StudyTime? preferredStudyTime,
    int? weekStartDay,
    String? timezone,
    AppThemeMode? themeMode,
    bool? aiEnabled,
  }) {
    return UserSettings(
      dailyStudyHours: dailyStudyHours ?? this.dailyStudyHours,
      preferredStudyTime: preferredStudyTime ?? this.preferredStudyTime,
      weekStartDay: weekStartDay ?? this.weekStartDay,
      timezone: timezone ?? this.timezone,
      themeMode: themeMode ?? this.themeMode,
      aiEnabled: aiEnabled ?? this.aiEnabled,
    );
  }

  @override
  List<Object?> get props => [
    dailyStudyHours,
    preferredStudyTime,
    weekStartDay,
    timezone,
    themeMode,
    aiEnabled,
  ];

  /// Finds the enum value with the same name as [raw], or returns [fallback].
  static T _parseEnum<T extends Enum>(List<T> values, Object? raw, T fallback) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return fallback;
  }
}
