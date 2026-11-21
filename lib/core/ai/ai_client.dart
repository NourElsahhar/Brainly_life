import '../errors/result.dart';
import 'ai_models.dart';

abstract interface class AiClient {
  Future<Result<AiResponse>> generate(AiRequest request);
}
