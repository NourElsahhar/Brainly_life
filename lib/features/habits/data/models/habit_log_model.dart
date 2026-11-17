import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// One completed day of a habit.
///
/// Stored at `users/{uid}/habitLogs/{habitId}_{dateKey}`.
/// The id is built from the habit and the day, so a habit can never be
/// completed twice on the same day.
class HabitLog extends Equatable {
  const HabitLog({
    required this.habitId,
    required this.date,
    required this.completedAt,
  });

  final String habitId;

  /// The day as a dateKey (`yyyy-MM-dd`).
  final String date;

  /// The exact moment the user completed it, in UTC.
  final DateTime completedAt;

  /// Document id: `<habitId>_<dateKey>`.
  String get id => buildId(habitId, date);

  static String buildId(String habitId, String dateKey) =>
      '${habitId}_$dateKey';

  HabitLog copyWith({String? habitId, String? date, DateTime? completedAt}) {
    return HabitLog(
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory HabitLog.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return HabitLog.fromMap(doc.data()!);
  }

  factory HabitLog.fromMap(Map<String, dynamic> map) {
    return HabitLog(
      habitId: map['habitId'] as String,
      date: map['date'] as String,
      completedAt: (map['completedAt'] as Timestamp).toDate().toUtc(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'habitId': habitId,
      'date': date,
      'completedAt': Timestamp.fromDate(completedAt.toUtc()),
    };
  }

  @override
  List<Object?> get props => [habitId, date, completedAt];
}
