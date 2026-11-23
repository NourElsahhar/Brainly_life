import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'firestore_mapping.dart';

part 'subject_model.freezed.dart';

@freezed
abstract class Subject with _$Subject {
  const Subject._();

  const factory Subject({
    required String id,
    required String name,
    required int colorValue,
    required DateTime examDate,
    required int priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Subject;

  factory Subject.fromFirestore(String id, Map<String, dynamic> data) {
    return Subject(
      id: id,
      name: requireField<String>(data, 'name'),
      colorValue: requireField<int>(data, 'colorValue'),
      examDate: requireDate(data, 'examDate'),
      priority: requireField<int>(data, 'priority'),
      createdAt: optionalDate(data, 'createdAt'),
      updatedAt: optionalDate(data, 'updatedAt'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'colorValue': colorValue,
      'examDate': Timestamp.fromDate(examDate),
      'priority': priority,
    };
  }
}
