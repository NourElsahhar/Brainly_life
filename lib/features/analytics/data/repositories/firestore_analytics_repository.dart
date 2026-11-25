import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../datasources/analytics_remote_data_source.dart';
import '../models/analytics_models.dart';
import 'analytics_repository.dart';

class FirestoreAnalyticsRepository implements AnalyticsRepository {
  FirestoreAnalyticsRepository(this.source);
  final AnalyticsRemoteDataSource source;

  @override
  Future<Result<AnalyticsInput>> readWeek(AnalyticsWeek week, DateTime now) =>
      _guard(() => source.readWeek(week, now));

  @override
  Future<Result<WeeklyReport?>> readReport(String weekKey) =>
      _guard(() => source.readReport(weekKey));

  Future<Result<T>> _guard<T>(Future<T> Function() read) async {
    try {
      return Result.success(await read());
    } catch (error) {
      return Result.failure(FirebaseErrorMapper.map(error));
    }
  }
}
