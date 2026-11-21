import '../../../../core/errors/result.dart';
import '../models/analytics_models.dart';
import 'analytics_repository.dart';

class MockAnalyticsRepository implements AnalyticsRepository {
  MockAnalyticsRepository({this.empty = false});

  final bool empty;
  final reports = <String, WeeklyReport>{};

  @override
  Future<Result<AnalyticsInput>> readWeek(
    AnalyticsWeek week,
    DateTime now,
  ) async {
    if (empty) return Result.success(AnalyticsInput());
    final created = week.startUtc;
    final completed = created.add(const Duration(minutes: 15));
    final previous = now.isAfter(week.endUtc);
    return Result.success(
      AnalyticsInput(
        tasks: [
          TaskStat(createdAt: created, completedAt: completed),
          TaskStat(
            createdAt: created,
            dueAt: created.add(const Duration(minutes: 30)),
          ),
        ],
        study: [
          StudyStat(
            subject: 'Mathematics',
            day: week.days.first,
            planned: 60,
            actual: previous ? 35 : 50,
          ),
          StudyStat(
            subject: 'Biology',
            day: week.days[1],
            planned: 30,
            actual: 20,
          ),
        ],
        habits: const [HabitDayStat(name: 'Read', due: 4, completed: 3)],
        focus: [
          FocusStat(
            day: week.days.first,
            planned: 50,
            actual: previous ? 25 : 45,
          ),
        ],
      ),
    );
  }

  @override
  Future<Result<WeeklyReport?>> readReport(String weekKey) async =>
      Result.success(reports[weekKey]);

  void saveReport(WeeklyReport report) => reports[report.weekKey] = report;
}
