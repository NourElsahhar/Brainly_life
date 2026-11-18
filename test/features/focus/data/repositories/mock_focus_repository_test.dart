import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:brainly_life/features/focus/data/models/focus_settings_model.dart';
import 'package:brainly_life/features/focus/data/repositories/mock_focus_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FocusSession newSession(String dateKey, int day) {
    final start = DateTime.utc(2026, 11, day, 9);
    return FocusSession(
      id: '',
      type: FocusSessionType.focus,
      startedAt: start,
      endedAt: start.add(const Duration(minutes: 25)),
      plannedMinutes: 25,
      actualMinutes: 25,
      completed: true,
      dateKey: dateKey,
      createdAt: start,
      updatedAt: start,
    );
  }

  late MockFocusRepository repository;

  setUp(() {
    repository = MockFocusRepository();
  });

  test('saveSession gives the session an id', () async {
    final saved = (await repository.saveSession(newSession('2026-11-14', 14)))
        .dataOrNull!;
    expect(saved.id, isNotEmpty);
  });

  test('getSessions returns only sessions inside the date range', () async {
    for (final day in [10, 12, 20]) {
      await repository.saveSession(
        newSession('2026-11-${day.toString().padLeft(2, '0')}', day),
      );
    }

    final sessions = (await repository.getSessions(
      fromDate: '2026-11-11',
      toDate: '2026-11-15',
    )).dataOrNull!;
    expect(sessions.map((s) => s.dateKey), ['2026-11-12']);
  });

  test('getSettings returns defaults until settings are saved', () async {
    expect((await repository.getSettings()).dataOrNull, const FocusSettings());

    await repository.saveSettings(const FocusSettings(focusMinutes: 50));
    expect((await repository.getSettings()).dataOrNull!.focusMinutes, 50);
  });
}
