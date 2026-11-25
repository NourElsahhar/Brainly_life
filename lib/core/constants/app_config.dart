// AppConfig = settings that come from the command line, not from code.
//
// USE_MOCKS:
//   fvm flutter run --dart-define=USE_MOCKS=true    -> fake (mock) data
//   fvm flutter run                                 -> real Firebase
//
// With mocks the app works with no internet and no Firebase data, so you can
// build your screens before the real repositories are ready.
//
// USE_EMULATOR (real repositories, but on the Firebase Emulator on your PC,
// so you can test the rules and your queries without touching real data):
//   firebase emulators:start                                   (in the repo)
//   fvm flutter run --dart-define=USE_EMULATOR=true            (Android emulator)
//   fvm flutter run --dart-define=USE_EMULATOR=true \
//       --dart-define=EMULATOR_HOST=192.168.1.5                 (real phone:
//                                                   your PC's IP, same Wi-Fi)
//
// You normally do NOT read AppConfig yourself. Your registerXFeature()
// function receives `useMocks` and picks the Mock or the real repository.

class AppConfig {
  const AppConfig._();

  static const bool useMocks = bool.fromEnvironment('USE_MOCKS');

  static const bool useEmulator = bool.fromEnvironment('USE_EMULATOR');

  /// 10.0.2.2 = "my PC" as seen from the Android emulator.
  static const String emulatorHost = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: '10.0.2.2',
  );
}
