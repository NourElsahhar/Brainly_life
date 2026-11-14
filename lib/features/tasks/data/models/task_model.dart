import 'package:brainly_life/features/tasks/data/models/subtask_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TaskPriority { low, medium, high }

enum TaskStatus { todo, done }

/// A to-do item owned by the user.
///
/// Stored at `users/{uid}/tasks/{id}`. All times are in UTC.
class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.priority = TaskPriority.medium,
    this.categoryId,
    this.dueAt,
    this.status = TaskStatus.todo,
    this.completedAt,
    this.subtasks = const [],
    this.reminderOffsetMinutes,
    this.reminderId,
  });

  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 1000;
  static const int maxSubtasks = 20;

  final String id;

  final String title;

  final String? description;

  final TaskPriority priority;

  /// Null means "Uncategorized".
  final String? categoryId;

  /// Null means the task has no deadline.
  final DateTime? dueAt;

  final TaskStatus status;

  /// When the task was marked as done. Null while it is not done.
  final DateTime? completedAt;

  final List<Subtask> subtasks;

  /// Minutes before [dueAt] to remind the user:
  /// 0 = at the due time, 10, 60, or 1440 (one day). Null means no reminder.
  final int? reminderOffsetMinutes;

  /// Id of the scheduled reminder, e.g. `task_<id>`. Null if there is none.
  final String? reminderId;

  final DateTime createdAt;

  final DateTime updatedAt;

  bool get isDone => status == TaskStatus.done;

  /// Returns a copy with the given fields changed.
  ///
  /// Passing null to a normal parameter keeps the old value,
  /// so use a `clear...` flag to set a field back to null.
  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    String? categoryId,
    DateTime? dueAt,
    TaskStatus? status,
    DateTime? completedAt,
    List<Subtask>? subtasks,
    int? reminderOffsetMinutes,
    String? reminderId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDescription = false,
    bool clearCategory = false,
    bool clearDueAt = false,
    bool clearCompletedAt = false,
    bool clearReminder = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      priority: priority ?? this.priority,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
      status: status ?? this.status,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      subtasks: subtasks ?? this.subtasks,
      reminderOffsetMinutes: clearReminder
          ? null
          : (reminderOffsetMinutes ?? this.reminderOffsetMinutes),
      reminderId: clearReminder ? null : (reminderId ?? this.reminderId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Task.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Task.fromMap(doc.id, doc.data()!);
  }

  factory Task.fromMap(String id, Map<String, dynamic> map) {
    return Task(
      id: id,
      title: map['title'] as String,
      description: map['description'] as String?,
      priority: TaskPriority.values.byName(map['priority'] as String),
      categoryId: map['categoryId'] as String?,
      dueAt: _readDate(map['dueAt']),
      status: TaskStatus.values.byName(map['status'] as String),
      completedAt: _readDate(map['completedAt']),
      subtasks: (map['subtasks'] as List? ?? const [])
          .map(
            (item) => Subtask.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      reminderOffsetMinutes: map['reminderOffsetMinutes'] as int?,
      reminderId: map['reminderId'] as String?,
      createdAt: _readDate(map['createdAt'])!,
      updatedAt: _readDate(map['updatedAt'])!,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'priority': priority.name,
      'categoryId': categoryId,
      'dueAt': _writeDate(dueAt),
      'status': status.name,
      'completedAt': _writeDate(completedAt),
      'subtasks': subtasks.map((subtask) => subtask.toMap()).toList(),
      'reminderOffsetMinutes': reminderOffsetMinutes,
      'reminderId': reminderId,
      'createdAt': _writeDate(createdAt),
      'updatedAt': _writeDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    priority,
    categoryId,
    dueAt,
    status,
    completedAt,
    subtasks,
    reminderOffsetMinutes,
    reminderId,
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
