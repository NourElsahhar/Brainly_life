import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'firestore_mapping.dart';
import 'plan_constraints_model.dart';
import 'study_enums.dart';

part 'study_plan_model.freezed.dart';

@freezed
abstract class StudyPlan with _$StudyPlan {
  const StudyPlan._();

  const factory StudyPlan({
    required String id,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required PlanGenerator generatedBy,
    int? promptVersion,
    @Default(PlanStatus.active) PlanStatus status,
    required PlanConstraints constraints,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _StudyPlan;

  factory StudyPlan.fromFirestore(String id, Map<String, dynamic> data) {
    return StudyPlan(
      id: id,
      title: requireField<String>(data, 'title'),
      startDate: requireDate(data, 'startDate'),
      endDate: requireDate(data, 'endDate'),
      generatedBy: parseEnum(
        PlanGenerator.values,
        data['generatedBy'],
        'generatedBy',
      ),
      promptVersion: optionalField<int>(data, 'promptVersion'),
      status: parseEnum(PlanStatus.values, data['status'], 'status'),
      constraints: PlanConstraints.fromFirestore(
        requireMap(data, 'constraints'),
      ),
      createdAt: optionalDate(data, 'createdAt'),
      updatedAt: optionalDate(data, 'updatedAt'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'generatedBy': generatedBy.name,
      'promptVersion': promptVersion,
      'status': status.name,
      'constraints': constraints.toFirestore(),
    };
  }
}
