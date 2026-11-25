// DeviceTimezone must never throw: with no phone (tests) it returns UTC.
// Run with: fvm flutter test test/core/utils/device_timezone_test.dart

import 'package:brainly_life/core/utils/device_timezone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('no platform (tests) -> UTC, no exception', () async {
    expect(await DeviceTimezone.current(), DeviceTimezone.fallback);
  });
}
