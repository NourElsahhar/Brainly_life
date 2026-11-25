import '../../../../core/ai/ai.dart';
import '../../../../core/errors/result.dart';
import '../models/analytics_models.dart';
import 'mock_analytics_repository.dart';

class MockWeeklyInsightClient implements AiClient {
  MockWeeklyInsightClient({required this.repository, required this.client});

  final MockAnalyticsRepository repository;
  final AiClient client;

  @override
  Future<Result<AiResponse>> generate(AiRequest request) async {
    final result = await client.generate(request);
    if (request.feature == AiFeature.weeklyInsight &&
        result.dataOrNull != null) {
      try {
        repository.saveReport(
          WeeklyReport.fromJson(
            request.payload['weekKey'] as String,
            result.dataOrNull!.data,
          ),
        );
      } catch (_) {
        return Result.failure(AiGatewayFailure(AiErrorCode.invalidResponse));
      }
    }
    return result;
  }
}
