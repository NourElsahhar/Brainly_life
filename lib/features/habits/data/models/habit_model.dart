import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum HabitFrequencyType { daily, weekdays, timesPerWeek }

/// A habit the user wants to repeat.
///
/// Stored at `users/{uid}/habits/{id}`. Exact moments are in UTC.
/// Day-level values ([startDate], [lastCompletedDate]) are dateKey
/// strings in the format `yyyy-MM-dd`.
class Habit extends Equatable {
  const Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.startDate,
    required this.createdAt,
    required this.updatedAt,
    this.frequencyType = HabitFrequencyType.daily,
    this.weekdays = const [],
    this.timesPerWeek,
    this.reminderTime,
    this.archived = false,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastCompletedDate,
  });

  static const int maxNameLength = 50;
  static const int minTimesPerWeek = 1;
  static const int maxTimesPerWeek = 7;

  final String id;

  final String name;

  /// Icon name chosen by the user.
  final String icon;

  /// Color as an ARGB int.
  final int colorValue;

  final HabitFrequencyType frequencyType;

  /// Days of the week (1 = Monday ... 7 = Sunday).
  /// Used only when [frequencyType] is `weekdays`.
  final List<int> weekdays;

  /// Target per week (1 to 7). Used only when [frequencyType] is
  /// `timesPerWeek`.
  final int? timesPerWeek;

  /// Daily reminder time as `HH:mm`. Null means no reminder.
  final String? reminderTime;

  /// First day of the habit, as a dateKey.
  final String startDate;

  final bool archived;

  final int currentStreak;

  final int bestStreak;

  /// Last day the habit was completed, as a dateKey. Null if never.
  final String? lastCompletedDate;

  final DateTime createdAt;

  final DateTime updatedAt;

  /// Returns a copy with the given fields changed.
  ///
  /// Passing null to a normal parameter keeps the old value,
  /// so use a `clear...` flag to set a field back to null.
  Habit copyWith({
    String? id,
    String? name,
    String? icon,
    int? colorValue,
    HabitFrequencyType? frequencyType,
    List<int>? weekdays,
    int? timesPerWeek,
    String? reminderTime,
    String? startDate,
    bool? archived,
    int? currentStreak,
    int? bestStreak,
    String? lastCompletedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearTimesPerWeek = false,
    bool clearReminderTime = false,
    bool clearLastCompletedDate = false,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      frequencyType: frequencyType ?? this.frequencyType,
      weekdays: weekdays ?? this.weekdays,
      timesPerWeek: clearTimesPerWeek
          ? null
          : (timesPerWeek ?? this.timesPerWeek),
      reminderTime: clearReminderTime
          ? null
          : (reminderTime ?? this.reminderTime),
      startDate: startDate ?? this.startDate,
      archived: archived ?? this.archived,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastCompletedDate: clearLastCompletedDate
          ? null
          : (lastCompletedDate ?? this.lastCompletedDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Habit.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Habit.fromMap(doc.id, doc.data()!);
  }

  factory Habit.fromMap(String id, Map<String, dynamic> map) {
    return Habit(
      id: id,
      name: map['name'] as String,
      icon: map['icon'] as String,
      colorValue: map['colorValue'] as int,
      frequencyType: HabitFrequencyType.values.byName(
        map['frequencyType'] as String,
      ),
      weekdays: (map['weekdays'] as List? ?? const []).cast<int>().toList(),
      timesPerWeek: map['timesPerWeek'] as int?,
      reminderTime: map['reminderTime'] as String?,
      startDate: map['startDate'] as String,
      archived: map['archived'] as bool? ?? false,
      currentStreak: map['currentStreak'] as int? ?? 0,
      bestStreak: map['bestStreak'] as int? ?? 0,
      lastCompletedDate: map['lastCompletedDate'] as String?,
      createdAt: _readDate(map['createdAt'])!,
      updatedAt: _readDate(map['updatedAt'])!,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon,
      'colorValue': colorValue,
      'frequencyType': frequencyType.name,
      'weekdays': weekdays,
      'timesPerWeek': timesPerWeek,
      'reminderTime': reminderTime,
      'startDate': startDate,
      'archived': archived,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastCompletedDate': lastCompletedDate,
      'createdAt': _writeDate(createdAt),
      'updatedAt': _writeDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    icon,
    colorValue,
    frequencyType,
    weekdays,
    timesPerWeek,
    reminderTime,
    startDate,
    archived,
    currentStreak,
    bestStreak,
    lastCompletedDate,
    createdAt,
    updatedAt,
  ];
}

DateTime? _readDate(Object? value) {
  if (value == null) return null;
  return (value as Timestamp).toDate().toUtc();
}

Timestamp? _writeDate(DateTime? value) {
  if (value == null) return null;
  return Timestamp.fromDate(value.toUtc());
}
