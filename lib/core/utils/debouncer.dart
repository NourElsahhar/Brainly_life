// Debouncer = "wait until the user stops, then run once".
// Used for search boxes so we do not search on every single letter.
//
// Usage inside a Cubit (or a State):
//   final _debouncer = Debouncer();
//
//   void searchChanged(String text) {
//     _debouncer.run(() => _search(text));   // runs 400 ms after the last letter
//   }
//
//   @override
//   Future<void> close() {
//     _debouncer.dispose();                  // IMPORTANT: always dispose
//     return super.close();
//   }
//
// Rules:
//   - Calling run() again before the delay ends cancels the previous call.
//   - dispose() cancels anything still waiting.

import 'dart:async';

class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 400)});

  final Duration delay;
  Timer? _timer;

  /// Runs [action] after [delay]. A new call cancels the one that is waiting.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancels the waiting call (if any).
  void cancel() => _timer?.cancel();

  /// Call this when the Cubit or screen is closed.
  void dispose() => cancel();
}
