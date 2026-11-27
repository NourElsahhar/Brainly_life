import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart'
    show FirebaseFunctions, FirebaseFunctionsException, HttpsCallableOptions;

import '../errors/failure.dart';
import '../errors/result.dart';
import 'ai_client.dart';
import 'ai_failures.dart';
import 'ai_models.dart';

typedef AiGatewayCall = Future<Object?> Function(Map<String, Object?> request);

class CloudFunctionsAiClient implements AiClient {
  CloudFunctionsAiClient({required this._call, required this._isEnabled});

  factory CloudFunctionsAiClient.firebase(
    FirebaseFunctions functions, {
    required Future<bool> Function() isEnabled,
  }) {
    final callable = functions.httpsCallable(
      'aiGateway',
      options: HttpsCallableOptions(timeout: _timeout),
    );
    return CloudFunctionsAiClient(
      call: (request) async => (await callable.call<Object?>(request)).data,
      isEnabled: isEnabled,
    );
  }

  static const _timeout = Duration(seconds: 30);
  final AiGatewayCall _call;
  final Future<bool> Function() _isEnabled;

  @override
  Future<Result<AiResponse>> generate(AiRequest request) async {
    try {
      if (!await _isEnabled()) {
        return Result.failure(AiGatewayFailure(AiErrorCode.disabled));
      }
      if (utf8.encode(jsonEncode(request.payload)).length > 20 * 1024) {
        return Result.failure(AiGatewayFailure(AiErrorCode.payloadTooLarge));
      }
      final result = await _attempt(request);
      final failure = result.failureOrNull;
      if (failure is AiGatewayFailure &&
          failure.kind == AiErrorCode.providerUnavailable) {
        return await _attempt(request);
      }
      return result;
    } catch (_) {
      return Result.failure(AiGatewayFailure(AiErrorCode.internal));
    }
  }

  Future<Result<AiResponse>> _attempt(AiRequest request) async {
    try {
      final raw = await _call(request.toJson()).timeout(_timeout);
      if (raw case {'ok': false, 'error': {'code': final String code}}) {
        return Result.failure(AiGatewayFailure(AiErrorCode.fromWire(code)));
      }
      if (raw is! Map || raw['ok'] != true) {
        return Result.failure(AiGatewayFailure(AiErrorCode.invalidResponse));
      }
      final json = jsonDecode(jsonEncode(raw)) as Map<String, Object?>;
      final response = AiResponse.fromJson(json);
      if (response.usage.feature != request.feature ||
          response.usage.remainingToday < 0) {
        return Result.failure(AiGatewayFailure(AiErrorCode.invalidResponse));
      }
      return Result.success(response);
    } on TimeoutException {
      return const Result.failure(
        NetworkFailure(userMessage: 'Baseet AI timed out. Please try again.'),
      );
    } on FirebaseFunctionsException catch (error) {
      final details = error.details;
      final code = details is Map && details['code'] is String
          ? details['code'] as String
          : error.code;
      return Result.failure(AiGatewayFailure(AiErrorCode.fromWire(code)));
    } catch (_) {
      return Result.failure(AiGatewayFailure(AiErrorCode.invalidResponse));
    }
  }
}
