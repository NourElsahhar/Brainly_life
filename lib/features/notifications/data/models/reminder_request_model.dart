import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Which feature owns the reminder.
enum ReminderType { task, study, habit, focus, custom }

/// How often the reminder repeats.
enum ReminderRepeat { none, daily, weekly }

/// The shared contract every feature uses to ask for a reminder.
///
/// [id] must be deterministic (for example `task_<taskId>`), so scheduling
/// the same item again replaces the old reminder instead of duplicating it.
class ReminderRequest extends Equatable {
  const ReminderRequest({
    required this.id,
    required this.type,
    required this.refId,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.route,
    this.repeat = ReminderRepeat.none,
    this.weekdays = const [],
  });

  /// Deterministic id, e.g. `task_abc123` or `study_xyz789`.
  final String id;

  /// The feature that owns this reminder.
  final ReminderType type;

  /// Id of the item that owns the reminder (task id, session id, ...).
  final String refId;

  /// Notification title.
  final String title;

  /// Notification text.
  final String body;

  /// First fire time. Always stored in UTC.
  final DateTime scheduledAt;

  /// How often the reminder repeats.
  final ReminderRepeat repeat;

  /// Days of the week (1 = Monday ... 7 = Sunday).
  /// Used only when [repeat] is [ReminderRepeat.weekly].
  final List<int> weekdays;

  /// Deep link opened when the user taps the notification, e.g. `/tasks/abc123`.
  final String route;

  ReminderRequest copyWith({
    String? id,
    ReminderType? type,
    String? refId,
    String? title,
    String? body,
    DateTime? scheduledAt,
    ReminderRepeat? repeat,
    List<int>? weekdays,
    String? route,
  }) {
    return ReminderRequest(
      id: id ?? this.id,
      type: type ?? this.type,
      refId: refId ?? this.refId,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      repeat: repeat ?? this.repeat,
      weekdays: weekdays ?? this.weekdays,
      route: route ?? this.route,
    );
  }

   factory ReminderRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ReminderRequest.fromMap(doc.id, doc.data()!);
  }

  factory ReminderRequest.fromMap(String id, Map<String, dynamic> data) {
    return ReminderRequest(
      id: id,
      type: ReminderType.values.byName(data['type'] as String),
      refId: data['refId'] as String,
      title: data['title'] as String,
      body: data['body'] as String,
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate().toUtc(),
      repeat: ReminderRepeat.values.byName(data['repeat'] as String),
      weekdays: List<int>.from(data['weekdays'] as List? ?? const []),
      route: data['route'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'refId': refId,
      'title': title,
      'body': body,
      'scheduledAt': Timestamp.fromDate(scheduledAt.toUtc()),
      'repeat': repeat.name,
      'weekdays': weekdays,
      'route': route,
    };
  }

  @override
  List<Object?> get props => [
    id,
    type,
    refId,
    title,
    body,
    scheduledAt,
    repeat,
    weekdays,
    route,
  ];
}
