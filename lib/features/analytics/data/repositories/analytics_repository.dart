import '../../../../core/errors/result.dart';
import '../models/analytics_models.dart';

abstract interface class AnalyticsRepository {
  Future<Result<AnalyticsInput>> readWeek(AnalyticsWeek week, DateTime now);
  Future<Result<WeeklyReport?>> readReport(String weekKey);
}
