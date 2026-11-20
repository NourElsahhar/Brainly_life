import 'package:brainly_life/features/focus/data/models/focus_settings_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults are 25 / 5 / 15 minutes and 4 sessions', () {
    const settings = FocusSettings();
    expect(settings.focusMinutes, 25);
    expect(settings.shortBreakMinutes, 5);
    expect(settings.longBreakMinutes, 15);
    expect(settings.sessionsBeforeLong, 4);
    expect(settings.autoStart, isFalse);
  });

  test('toFirestore then fromMap gives the same settings', () {
    const settings = FocusSettings(
      focusMinutes: 50,
      autoStart: true,
      keepScreenOn: true,
    );
    expect(FocusSettings.fromMap(settings.toFirestore()), settings);
  });

  test('fromMap uses defaults for missing fields', () {
    expect(FocusSettings.fromMap({}), const FocusSettings());
  });
}
