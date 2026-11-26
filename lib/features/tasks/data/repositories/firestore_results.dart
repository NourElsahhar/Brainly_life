// FirestoreResults = the shared "exception -> Result" part of the two
// Firestore repositories of the tasks feature (owner: M3).
//
//   runSafely(...)   a Future: any exception becomes Result.failure.
//   watchSafely(...) a Stream: data becomes Result.success, and an error
//                    (also one thrown while opening it, like no signed-in
//                    user) becomes Result.failure INSIDE the stream, so the
//                    stream does not close and the Cubit shows the error.

import 'dart:async';

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/firebase_error_mapper.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/utils.dart';

mixin FirestoreResults {
  /// Runs [action]; any exception becomes a Failure.
  Future<Result<T>> runSafely<T>(
    String name,
    Future<T> Function() action,
  ) async {
    try {
      return Result.success(await action());
    } catch (error) {
      return Result.failure(_fail(name, error));
    }
  }

  /// Opens the stream and wraps every event in a Result.
  Stream<Result<T>> watchSafely<T>(String name, Stream<T> Function() open) {
    final Stream<T> stream;
    try {
      stream = open();
    } catch (error) {
      return Stream.value(Result.failure(_fail(name, error)));
    }
    return stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) => sink.add(Result.success(data)),
        handleError: (error, _, sink) =>
            sink.add(Result.failure(_fail(name, error))),
      ),
    );
  }

  Failure _fail(String name, Object error) {
    final failure = FirebaseErrorMapper.map(error);
    AppLogger.warning(
      '$name failed (${failure.code ?? failure.runtimeType})',
      tag: 'Tasks',
    );
    return failure;
  }
}
