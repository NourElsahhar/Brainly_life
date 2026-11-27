// The only file that talks to Firebase AI Logic (package firebase_ai).
// It sends a prompt to Gemini through the Gemini Developer API, which is
// free on the Spark plan (no Blaze, no Cloud Functions, no API key in the
// app: Firebase keeps the key).
//
// Setup (once, in the Firebase console): AI Services -> AI Logic ->
// Get started -> choose "Gemini Developer API".

import 'package:firebase_ai/firebase_ai.dart'
    show
        Content,
        FirebaseAI,
        FirebaseAIException,
        GenerationConfig,
        InvalidApiKey,
        QuotaExceeded,
        ServiceApiNotEnabled,
        UnsupportedUserLocation;
import 'package:flutter/foundation.dart' show debugPrint;

import 'ai_failures.dart';
import 'gemini_ai_client.dart';
import 'gemini_prompts.dart';

/// The Gemini model. Change it here only.
const String geminiModel = 'gemini-3.5-flash-lite';
/// Used when [geminiModel] is too busy.
const String fallbackModel = 'gemini-3.8-flash';
/// Shows the real reason in the `flutter run` terminal (debug only).
void _log(String message) => debugPrint('[AI] $message');

/// A [GeminiCall] that uses Firebase AI Logic.
GeminiCall firebaseGeminiCall({String model = geminiModel}) {
  return (AiPrompt prompt, {required double temperature}) async {
    final generative = FirebaseAI.googleAI().generativeModel(
      model: model,
      systemInstruction: Content.system(prompt.system),
      generationConfig: GenerationConfig(
        temperature: temperature,
        responseMimeType: 'application/json',
      ),
    );
        try {
      // Busy model (500 "high demand"): try again after a short wait, and
      // the last try uses the lighter model, which is usually less busy.
      for (var attempt = 0; ; attempt++) {
        final current = attempt < 2
            ? generative
            : FirebaseAI.googleAI().generativeModel(
                model: fallbackModel,
                systemInstruction: Content.system(prompt.system),
                generationConfig: GenerationConfig(
                  temperature: temperature,
                  responseMimeType: 'application/json',
                ),
              );
        try {
          final response = await current.generateContent([
            Content.text(prompt.user),
          ]);
          return response.text;
        } on FirebaseAIException catch (e) {
          final busy = '$e'.contains('high demand') || '$e'.contains('[500]');
          if (!busy || attempt >= 2) rethrow;
          _log('model busy, retry ${attempt + 1}');
          await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
        }
      }
    } on QuotaExceeded catch (e) {
      _log('quota: $e');
      throw const GeminiCallException(AiErrorCode.rateLimited);
    } on ServiceApiNotEnabled catch (e) {
      _log('API not enabled: $e');
      throw const GeminiCallException(AiErrorCode.invalidFeature);
    } on InvalidApiKey catch (e) {
      _log('key: $e');
      throw const GeminiCallException(AiErrorCode.invalidFeature);
    } on UnsupportedUserLocation catch (e) {
      _log('location: $e');
      throw const GeminiCallException(AiErrorCode.providerUnavailable);
    } on FirebaseAIException catch (e) {
      _log('error ${e.runtimeType}: $e');
      throw const GeminiCallException(AiErrorCode.providerUnavailable);
    } catch (e) {
      _log('failed ${e.runtimeType}: $e');
      rethrow;
    }
  };
}