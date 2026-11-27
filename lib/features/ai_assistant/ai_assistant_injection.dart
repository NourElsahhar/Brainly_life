import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/repositories/daily_ai_tip_provider.dart';

import '../../core/ai/ai.dart';
import '../../core/ai/firebase_gemini_call.dart';
import '../../core/ai/shared_prefs_ai_usage_counter.dart';
import '../../core/errors/result.dart';
import '../../core/utils/date_key_utils.dart';
import '../auth/data/models/user_settings_model.dart';
import '../auth/logic/auth_cubit.dart';
import '../auth/logic/auth_state.dart';
import '../auth/data/repositories/profile_stats_provider.dart';
import '../home/data/repositories/home_summary_port.dart' as home;
import '../study_planner/data/repositories/study_repository.dart';
import '../habits/data/repositories/habit_creation_port.dart';
import '../tasks/data/repositories/task_creation_port.dart';
import 'data/datasources/chat_remote_data_source.dart';
import 'data/repositories/ai_chat_context.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/firestore_chat_repository.dart';
import 'data/repositories/mock_chat_repository.dart';
import 'logic/ai_action_handler.dart';
import 'logic/chat_cubit.dart';

class AiAccount {
  AiAccount(this.services, this.useMocks);
  final GetIt services;
  final bool useMocks;
  String get uid =>
      useMocks ? 'demo' : services<FirebaseAuth>().currentUser?.uid ?? '';

  /// The signed-in user's settings, from AuthCubit (no extra Firestore read,
  /// and always the latest values after the user changes Settings).
  Future<UserSettings> settings() async {
    if (useMocks) return UserSettings.defaults();
    final state = services<AuthCubit>().state;
    if (state is! Authenticated) throw StateError('Sign in required');
    return state.user.settings;
  }
}

class TeamAiTipProvider implements home.AiTipProvider {
  TeamAiTipProvider(this.account, this.client);
  final AiAccount account;
  final AiClient client;
  final _providers = <String, DailyAiTipProvider>{};
  @override
  Future<Result<String>> dailyTip() async {
    try {
      final settings = await account.settings();
      final key = '${account.uid}:${settings.timezone}';
      final provider = _providers.putIfAbsent(
        key,
        () => DailyAiTipProvider(
          client: client,
          preferences: SharedPreferencesAsync(),
          accountKey: account.uid,
          today: () => DateKeyUtils.todayKey(timezone: settings.timezone),
          isEnabled: () async => (await account.settings()).aiEnabled,
        ),
      );
      return await provider.dailyTip();
    } catch (_) {
      return const Result.success('Choose one small task to start your day.');
    }
  }
}

/// The real AI client: Gemini through Firebase AI Logic, with the user's
/// data for the chat and the weekly report saved in Firestore.
GeminiAiClient _geminiClient(GetIt getIt) {
  final account = getIt<AiAccount>();
  Future<String> timezone() async => (await account.settings()).timezone;
  T? optional<T extends Object>() =>
      getIt.isRegistered<T>() ? getIt<T>() : null;

  return GeminiAiClient(
    call: firebaseGeminiCall(),
    isEnabled: () async => (await account.settings()).aiEnabled,
    usage: SharedPrefsAiUsageCounter(
      preferences: SharedPreferencesAsync(),
      accountKey: account.uid,
    ),
    today: () async => DateKeyUtils.todayKey(timezone: await timezone()),
    chatContext: () => AiChatContext(
      timezone: timezone,
      now: DateTime.now,
      study: optional<StudyRepository>,
      tasks: optional<home.TaskSummaryProvider>,
      streak: optional<ProfileStreakSource>,
    ).build(),
    saveWeeklyReport: (weekKey, stats, report) async {
      // Same document the aiGateway's persist hook wrote. Saved once:
      // a second report for the same week never replaces the first.
      final ref = getIt<FirebaseFirestore>()
          .collection('users')
          .doc(account.uid)
          .collection('weeklyReports')
          .doc(weekKey);
      await getIt<FirebaseFirestore>()
          .runTransaction((transaction) async {
            final existing = await transaction.get(ref);
            if (existing.exists) return;
            transaction.set(ref, {
              'weekKey': weekKey,
              'stats': stats,
              'summary': report['summary'],
              'recommendations': report['recommendations'],
              'generatedAt': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'promptVersion': 1,
            });
          })
          .timeout(const Duration(seconds: 15));
    },
  );
}

void registerAiAssistantFeature(GetIt getIt, {required bool useMocks}) {
  getIt.registerLazySingleton(() => AiAccount(getIt, useMocks));
  // Mock mode: MockAiClient. Real mode: Gemini directly through Firebase
  // AI Logic (free on Spark, no Cloud Functions). CloudFunctionsAiClient
  // (the aiGateway function) is kept for when the team gets Blaze.
  getIt.registerLazySingleton<AiClient>(
    () => useMocks ? MockAiClient() : _geminiClient(getIt),
  );
  final mockChat = MockChatRepository();
  getIt.registerFactory<ChatRepository>(
    () => useMocks
        ? mockChat
        : FirestoreChatRepository(
            ChatRemoteDataSource(
              getIt<FirebaseFirestore>(),
              getIt<AiAccount>().uid,
            ),
          ),
  );
  getIt.registerFactory(
    () => ChatCubit(repository: getIt(), client: getIt(), now: DateTime.now),
  );
  getIt.registerLazySingleton(
    () => AiActionHandler(
      createTask: (title) =>
          getIt<TaskCreationPort>().createTask(TaskDraft(title: title)),
      createHabit: (title) =>
          getIt<HabitCreationPort>().createHabit(HabitDraft(name: title)),
    ),
  );
  getIt.registerLazySingleton<home.AiTipProvider>(
    () => TeamAiTipProvider(getIt(), getIt()),
  );
}
