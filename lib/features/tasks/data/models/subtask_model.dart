import 'package:equatable/equatable.dart';

/// One checklist item inside a task.
///
/// Subtasks are stored inside the task document as a list of maps,
/// not as a separate Firestore collection.
class Subtask extends Equatable {
  const Subtask({required this.id, required this.title, this.done = false});

  /// Unique inside its task.
  final String id;

  final String title;

  /// Whether the user checked this item.
  final bool done;

  Subtask copyWith({String? id, String? title, bool? done}) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      done: done ?? this.done,
    );
  }

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'] as String,
      title: map['title'] as String,
      done: map['done'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'done': done};
  }

  @override
  List<Object?> get props => [id, title, done];
}
