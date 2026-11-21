import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../logic/analytics_calendar.dart';
import '../models/analytics_models.dart';

class AnalyticsRemoteDataSource {
  AnalyticsRemoteDataSource({
    required FirebaseFirestore firestore,
    required String uid,
    required this._calendar,
  }) : _user = firestore.collection('users').doc(uid);

  final DocumentReference<Map<String, dynamic>> _user;
  final AnalyticsCalendar _calendar;

  Future<AnalyticsInput> readWeek(AnalyticsWeek week, DateTime now) async {
    final tasks = _user.collection('tasks');
    final start = Timestamp.fromDate(week.startUtc);
    final end = Timestamp.fromDate(week.endUtc);
    final dayStart = week.days.first;
    final dayEnd = week.days.last;

    Future<QuerySnapshot<Map<String, dynamic>>> times(
      CollectionReference<Map<String, dynamic>> collection,
      String field,
    ) => collection
        .where(field, isGreaterThanOrEqualTo: start)
        .where(field, isLessThan: end)
        .get();

    Future<QuerySnapshot<Map<String, dynamic>>> days(String collection) => _user
        .collection(collection)
        .where('date', isGreaterThanOrEqualTo: dayStart)
        .where('date', isLessThanOrEqualTo: dayEnd)
        .get();

    final results = await Future.wait([
      for (final field in ['createdAt', 'completedAt', 'dueAt'])
        times(tasks, field),
      days('studySessions'),
      _user.collection('subjects').get(),
      _user.collection('habits').get(),
      days('habitLogs'),
      times(_user.collection('focusSessions'), 'startedAt'),
    ]);

    final taskDocs = {
      for (final result in results.take(3))
        for (final doc in result.docs) doc.id: doc.data(),
    };
    final subjects = {
      for (final doc in results[4].docs) doc.id: doc.data()['name'] as String,
    };
    final today = _calendar.dateKey(now);
    final observedDays = week.days
        .where((day) => day.compareTo(today) <= 0)
        .toList();
    final logs = <String, Set<String>>{};
    for (final doc in results[6].docs) {
      final data = doc.data();
      (logs[data['habitId'] as String] ??= {}).add(data['date'] as String);
    }

    return AnalyticsInput(
      tasks: taskDocs.values.map(
        (data) => TaskStat(
          createdAt: _date(data['createdAt']),
          completedAt: _date(data['completedAt']),
          dueAt: _date(data['dueAt']),
        ),
      ),
      study: results[3].docs.map((doc) {
        final data = doc.data();
        return StudyStat(
          subject: subjects[data['subjectId']] ?? 'Unknown subject',
          day: data['date'] as String?,
          planned: data['plannedMinutes'] as int? ?? 0,
          actual: data['actualMinutes'] as int? ?? 0,
        );
      }),
      habits: results[5].docs.map(
        (doc) => _habit(
          doc.data(),
          observedDays,
          logs[doc.id] ?? const <String>{},
          today,
        ),
      ),
      focus: results[7].docs
          .map((doc) => doc.data())
          .where((data) => data['type'] == 'focus')
          .map(
            (data) => FocusStat(
              day: _calendar.dateKey(_date(data['startedAt'])!),
              planned: data['plannedMinutes'] as int? ?? 0,
              actual: data['actualMinutes'] as int? ?? 0,
            ),
          ),
    );
  }

  Future<WeeklyReport?> readReport(String weekKey) async {
    final doc = await _user.collection('weeklyReports').doc(weekKey).get();
    final data = doc.data();
    if (data == null) return null;
    return WeeklyReport.fromJson(weekKey, data);
  }

  HabitDayStat _habit(
    Map<String, dynamic> data,
    List<String> days,
    Set<String> done,
    String today,
  ) {
    final rawStart = data['startDate'];
    final start = switch (rawStart) {
      String value => value,
      Timestamp value => _calendar.dateKey(value.toDate()),
      _ => '',
    };
    final name = data['name'] as String;
    final eligible = days.where((day) => day.compareTo(start) >= 0).toList();
    final completed = eligible.where(done.contains).length;
    if (data['archived'] == true) {
      return HabitDayStat(name: name, due: completed, completed: completed);
    }

    if (data['frequencyType'] == 'timesPerWeek' ||
        data['frequencyType'] == 'weekly') {
      final limit = (data['timesPerWeek'] as int? ?? 1).clamp(1, 7);
      final elapsed = eligible
          .where((day) => day != today || done.contains(day))
          .length;
      final due = math.min(limit, elapsed);
      return HabitDayStat(
        name: name,
        due: due,
        completed: math.min(completed, due),
      );
    }

    final weekdays = data['weekdays'] as List? ?? const [];
    final scheduled = eligible.where((day) {
      final dueToday = day == today && !done.contains(day);
      if (dueToday) return false;
      return data['frequencyType'] != 'weekdays' ||
          weekdays.contains(DateTime.parse(day).weekday);
    }).toList();
    return HabitDayStat(
      name: name,
      due: scheduled.length,
      completed: scheduled.where(done.contains).length,
    );
  }

  static DateTime? _date(Object? value) =>
      value is Timestamp ? value.toDate().toUtc() : null;
}
