import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum FocusSessionType { focus, shortBreak, longBreak }

/// One finished (or stopped) timer block.
///
/// Stored at `users/{uid}/focusSessions/{id}`. Exact moments are in UTC,
/// and [dateKey] is the day in the user's timezone (`yyyy-MM-dd`).
class FocusSession extends Equatable {
  const FocusSession({
    required this.id,
    required this.type,
    required this.startedAt,
    required this.endedAt,
    required this.plannedMinutes,
    required this.actualMinutes,
    required this.dateKey,
    required this.createdAt,
    required this.updatedAt,
    this.completed = false,
    this.taskId,
    this.studySessionId,
  });

  static const int maxActualMinutes = 240;

  final String id;

  final FocusSessionType type;

  final DateTime startedAt;

  final DateTime endedAt;

  final int plannedMinutes;

  final int actualMinutes;

  /// True if the block ran until the end. False if the user stopped early.
  final bool completed;

  final String dateKey;

  /// Linked task, if the timer was started from a task.
  final String? taskId;

  /// Linked study session, if the timer was started from the planner.
  final String? studySessionId;

  final DateTime createdAt;

  final DateTime updatedAt;

  FocusSession copyWith({
    String? id,
    FocusSessionType? type,
    DateTime? startedAt,
    DateTime? endedAt,
    int? plannedMinutes,
    int? actualMinutes,
    bool? completed,
    String? dateKey,
    String? taskId,
    String? studySessionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearTaskId = false,
    bool clearStudySessionId = false,
  }) {
    return FocusSession(
      id: id ?? this.id,
      type: type ?? this.type,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      completed: completed ?? this.completed,
      dateKey: dateKey ?? this.dateKey,
      taskId: clearTaskId ? null : (taskId ?? this.taskId),
      studySessionId: clearStudySessionId
          ? null
          : (studySessionId ?? this.studySessionId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory FocusSession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return FocusSession.fromMap(doc.id, doc.data()!);
  }

  factory FocusSession.fromMap(String id, Map<String, dynamic> map) {
    return FocusSession(
      id: id,
      type: FocusSessionType.values.byName(map['type'] as String),
      startedAt: _readDate(map['startedAt'])!,
      endedAt: _readDate(map['endedAt'])!,
      plannedMinutes: map['plannedMinutes'] as int,
      actualMinutes: map['actualMinutes'] as int,
      completed: map['completed'] as bool? ?? false,
      dateKey: map['dateKey'] as String,
      taskId: map['taskId'] as String?,
      studySessionId: map['studySessionId'] as String?,
      createdAt: _readDate(map['createdAt'])!,
      updatedAt: _readDate(map['updatedAt'])!,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'startedAt': _writeDate(startedAt),
      'endedAt': _writeDate(endedAt),
      'plannedMinutes': plannedMinutes,
      'actualMinutes': actualMinutes,
      'completed': completed,
      'dateKey': dateKey,
      'taskId': taskId,
      'studySessionId': studySessionId,
      'createdAt': _writeDate(createdAt),
      'updatedAt': _writeDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [
    id,
    type,
    startedAt,
    endedAt,
    plannedMinutes,
    actualMinutes,
    completed,
    dateKey,
    taskId,
    studySessionId,
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
