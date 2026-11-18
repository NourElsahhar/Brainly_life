import 'package:equatable/equatable.dart';

/// The user's timer settings.
///
/// Stored at `users/{uid}/preferences/focus`.
class FocusSettings extends Equatable {
  const FocusSettings({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsBeforeLong = 4,
    this.autoStart = false,
    this.sound = true,
    this.vibration = true,
    this.keepScreenOn = false,
  });

  final int focusMinutes;

  final int shortBreakMinutes;

  final int longBreakMinutes;

  /// Number of focus blocks before a long break.
  final int sessionsBeforeLong;

  /// Start the next block automatically.
  final bool autoStart;

  final bool sound;

  final bool vibration;

  final bool keepScreenOn;

  FocusSettings copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLong,
    bool? autoStart,
    bool? sound,
    bool? vibration,
    bool? keepScreenOn,
  }) {
    return FocusSettings(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      sessionsBeforeLong: sessionsBeforeLong ?? this.sessionsBeforeLong,
      autoStart: autoStart ?? this.autoStart,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    );
  }

  /// Missing fields fall back to the defaults.
  factory FocusSettings.fromMap(Map<String, dynamic> map) {
    const defaults = FocusSettings();
    return FocusSettings(
      focusMinutes: map['focusMinutes'] as int? ?? defaults.focusMinutes,
      shortBreakMinutes:
          map['shortBreakMinutes'] as int? ?? defaults.shortBreakMinutes,
      longBreakMinutes:
          map['longBreakMinutes'] as int? ?? defaults.longBreakMinutes,
      sessionsBeforeLong:
          map['sessionsBeforeLong'] as int? ?? defaults.sessionsBeforeLong,
      autoStart: map['autoStart'] as bool? ?? defaults.autoStart,
      sound: map['sound'] as bool? ?? defaults.sound,
      vibration: map['vibration'] as bool? ?? defaults.vibration,
      keepScreenOn: map['keepScreenOn'] as bool? ?? defaults.keepScreenOn,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'focusMinutes': focusMinutes,
      'shortBreakMinutes': shortBreakMinutes,
      'longBreakMinutes': longBreakMinutes,
      'sessionsBeforeLong': sessionsBeforeLong,
      'autoStart': autoStart,
      'sound': sound,
      'vibration': vibration,
      'keepScreenOn': keepScreenOn,
    };
  }

  @override
  List<Object?> get props => [
    focusMinutes,
    shortBreakMinutes,
    longBreakMinutes,
    sessionsBeforeLong,
    autoStart,
    sound,
    vibration,
    keepScreenOn,
  ];
}
