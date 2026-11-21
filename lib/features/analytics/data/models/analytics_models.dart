String dayKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

class AnalyticsWeek {
  const AnalyticsWeek({
    required this.key,
    required this.start,
    required this.startUtc,
    required this.endUtc,
  });

  final String key;
  final DateTime start;
  final DateTime startUtc;
  final DateTime endUtc;

  List<String> get days => List.generate(
    7,
    (index) => dayKey(DateTime.utc(start.year, start.month, start.day + index)),
  );
  bool contains(DateTime? instant) =>
      instant != null &&
      !instant.isBefore(startUtc) &&
      instant.isBefore(endUtc);
}

class TaskStat {
  const TaskStat({required this.createdAt, this.dueAt, this.completedAt});
  final DateTime? createdAt;
  final DateTime? dueAt;
  final DateTime? completedAt;
}

class StudyStat {
  const StudyStat({
    required this.subject,
    this.day,
    required this.planned,
    required this.actual,
  });
  final String subject;
  final String? day;
  final int planned;
  final int actual;
}

class HabitDayStat {
  const HabitDayStat({
    required this.name,
    required this.due,
    required this.completed,
  });
  final String name;
  final int due;
  final int completed;
}

class FocusStat {
  const FocusStat({
    required this.day,
    required this.planned,
    required this.actual,
  });
  final String day;
  final int planned;
  final int actual;
}

class AnalyticsInput {
  AnalyticsInput({
    Iterable<TaskStat> tasks = const [],
    Iterable<StudyStat> study = const [],
    Iterable<HabitDayStat> habits = const [],
    Iterable<FocusStat> focus = const [],
  }) : tasks = List.unmodifiable(tasks),
       study = List.unmodifiable(study),
       habits = List.unmodifiable(habits),
       focus = List.unmodifiable(focus);

  final List<TaskStat> tasks;
  final List<StudyStat> study;
  final List<HabitDayStat> habits;
  final List<FocusStat> focus;
}

class TaskDayStats {
  const TaskDayStats({required this.created, required this.completed});
  final int created;
  final int completed;
}

class WeeklyStats {
  WeeklyStats({
    required this.tasksCreated,
    required this.tasksCompleted,
    required this.tasksOverdue,
    required this.tasksCount,
    required this.studyPlanned,
    required this.studyActual,
    required this.habitsDue,
    required this.habitsCompleted,
    required this.bestHabit,
    required this.focusMinutes,
    required this.focusPlanned,
    required this.focusSessions,
    required Map<String, TaskDayStats> tasksByDay,
    required Map<String, int> focusByDay,
    required Map<String, int> studyBySubject,
    Map<String, int> studyByDay = const {},
  }) : tasksByDay = Map.unmodifiable(tasksByDay),
       focusByDay = Map.unmodifiable(focusByDay),
       studyBySubject = Map.unmodifiable(studyBySubject),
       studyByDay = Map.unmodifiable(studyByDay);

  final int tasksCreated, tasksCompleted, tasksOverdue, tasksCount;
  final int studyPlanned, studyActual;
  final int habitsDue, habitsCompleted;
  final String? bestHabit;
  final int focusMinutes, focusPlanned, focusSessions;
  final Map<String, TaskDayStats> tasksByDay;
  final Map<String, int> focusByDay, studyBySubject, studyByDay;

  double get taskRate => _ratio(tasksCompleted, tasksCount);
  double get studyRate => _ratio(studyActual, studyPlanned);
  double get habitRate => _ratio(habitsCompleted, habitsDue);
  double get focusRate => _ratio(focusMinutes, focusPlanned);

  bool get isEmpty =>
      tasksCount == 0 &&
      studyPlanned == 0 &&
      studyActual == 0 &&
      habitsDue == 0 &&
      focusSessions == 0;

  Map<String, num> reportNumbers(int score) => {
    'tasksCreated': tasksCreated,
    'tasksCompleted': tasksCompleted,
    'tasksOverdue': tasksOverdue,
    'studyPlanned': studyPlanned,
    'studyActual': studyActual,
    'habitsDue': habitsDue,
    'habitsCompleted': habitsCompleted,
    'focusMinutes': focusMinutes,
    'focusSessions': focusSessions,
    'productivityScore': score,
  };

  static double _ratio(int value, int total) =>
      total == 0 ? 0 : (value / total).clamp(0.0, 1.0).toDouble();
}

class WeeklyReport {
  WeeklyReport({
    required this.weekKey,
    required this.summary,
    required List<String> recommendations,
  }) : recommendations = List.unmodifiable(recommendations) {
    if (summary.trim().isEmpty ||
        this.recommendations.length != 3 ||
        this.recommendations.any((item) => item.trim().isEmpty)) {
      throw const FormatException('Invalid weekly report');
    }
  }

  factory WeeklyReport.fromJson(String weekKey, Map<String, Object?> data) =>
      WeeklyReport(
        weekKey: weekKey,
        summary: data['summary'] as String,
        recommendations: List<String>.from(data['recommendations'] as List),
      );

  final String weekKey;
  final String summary;
  final List<String> recommendations;
}
