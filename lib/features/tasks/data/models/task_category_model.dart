import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A user-defined group of tasks, e.g. "University" or "Personal".
///
/// Stored at `users/{uid}/taskCategories/{id}`.
class TaskCategory extends Equatable {
  const TaskCategory({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  final String id;

  final String name;

  /// The chosen colour as a 32-bit ARGB number, e.g. 0xFF4CAF50.
  /// The UI turns it into a colour with `Color(colorValue)`.
  final int colorValue;

  TaskCategory copyWith({String? id, String? name, int? colorValue}) {
    return TaskCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  factory TaskCategory.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return TaskCategory.fromMap(doc.id, doc.data()!);
  }

  factory TaskCategory.fromMap(String id, Map<String, dynamic> map) {
    return TaskCategory(
      id: id,
      name: map['name'] as String,
      colorValue: map['colorValue'] as int,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name, 'colorValue': colorValue};
  }

  @override
  List<Object?> get props => [id, name, colorValue];
}
