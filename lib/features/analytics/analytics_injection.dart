import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../ai_assistant/ai_assistant_injection.dart';
import '../../core/ai/ai.dart';
import 'data/datasources/analytics_remote_data_source.dart';
import 'data/repositories/firestore_analytics_repository.dart';
import 'data/repositories/mock_analytics_repository.dart';
import 'data/repositories/mock_weekly_insight_client.dart';
import 'logic/analytics_cubit.dart';
import 'logic/iana_analytics_calendar.dart';

class AnalyticsFactory {
  AnalyticsFactory(this.services, this.useMocks);
  final GetIt services;
  final bool useMocks;
  final _mock = MockAnalyticsRepository();
  Future<AnalyticsCubit> create() async {
    final account = services<AiAccount>();
    final settings = await account.settings();
    tzdata.initializeTimeZones();
    final calendar = ianaAnalyticsCalendar(
      timezone: settings.timezone,
      weekStartDay: settings.weekStartDay,
    );
    final ai = services<AiClient>();
    return AnalyticsCubit(
      repository: useMocks
          ? _mock
          : FirestoreAnalyticsRepository(
              AnalyticsRemoteDataSource(
                firestore: services<FirebaseFirestore>(),
                uid: account.uid,
                calendar: calendar,
              ),
            ),
      calendar: calendar,
      ai: useMocks
          ? MockWeeklyInsightClient(client: ai, repository: _mock)
          : ai,
      now: DateTime.now,
    );
  }
}

void registerAnalyticsFeature(GetIt getIt, {required bool useMocks}) {
  getIt.registerLazySingleton(() => AnalyticsFactory(getIt, useMocks));
}
