import '../../../../core/errors/result.dart';

abstract interface class AiTipProvider {
  Future<Result<String>> dailyTip();
}
