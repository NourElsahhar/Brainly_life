// AppConfig = settings that come from the command line, not from code.
//
// USE_MOCKS:
//   fvm flutter run --dart-define=USE_MOCKS=true    -> fake (mock) data
//   fvm flutter run                                 -> real Firebase
//
// With mocks the app works with no internet and no Firebase data, so you can
// build your screens before the real repositories are ready.
//
// You normally do NOT read AppConfig yourself. Your registerXFeature()
// function receives `useMocks` and picks the Mock or the real repository.

class AppConfig {
  const AppConfig._();

  static const bool useMocks = bool.fromEnvironment('USE_MOCKS');
}
