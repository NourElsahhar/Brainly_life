import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' show FirebaseFunctions;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/repositories/daily_ai_tip_provider.dart';

import '../../core/ai/ai.dart';
import '../../core/errors/result.dart';
import '../../core/utils/date_key_utils.dart';
import '../auth/data/models/user_settings_model.dart';
import '../auth/logic/auth_cubit.dart';
import '../auth/logic/auth_state.dart';
import '../home/data/repositories/home_summary_port.dart' as home;
import '../habits/data/repositories/habit_creation_port.dart';
import '../tasks/data/repositories/task_creation_port.dart';
import 'data/datasources/chat_remote_data_source.dart';
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

void registerAiAssistantFeature(GetIt getIt, {required bool useMocks}) {
  getIt.registerLazySingleton(() => AiAccount(getIt, useMocks));
  getIt.registerLazySingleton<AiClient>(
    () => useMocks
        ? MockAiClient()
        : CloudFunctionsAiClient.firebase(
            getIt<FirebaseFunctions>(),
            isEnabled: () async =>
                (await getIt<AiAccount>().settings()).aiEnabled,
          ),
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
