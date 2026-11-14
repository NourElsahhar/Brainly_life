// Result<T> is what every repository method returns instead of throwing.
//
// A Result is exactly ONE of two things:
//   - Success: holds the data      -> Success(data)
//   - Failed:  holds a Failure     -> Failed(failure)
//
// Why? So a Cubit never needs try/catch. It just checks which one it got,
// and Dart forces you to handle both cases.
//
// Creating one (inside a repository):
//   return Result.success(tasks);
//   return Result.failure(const NetworkFailure());
//
// Using one (inside a Cubit), with a switch:
//   final result = await repository.getTasks();
//   switch (result) {
//     case Success(:final data):
//       emit(TaskListLoaded(data));
//     case Failed(:final failure):
//       emit(TaskListError(failure));
//   }
//
// Or the short way:
//   result.fold(
//     onSuccess: (data) => emit(TaskListLoaded(data)),
//     onFailure: (failure) => emit(TaskListError(failure)),
//   );

import 'package:equatable/equatable.dart';

import 'failure.dart';

sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Failure failure) = Failed<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failed<T>;

  /// The data if this is a Success, otherwise null.
  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        Failed<T>() => null,
      };

  /// The failure if this is a Failed, otherwise null.
  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Failed<T>(:final failure) => failure,
      };

  /// Runs one of the two callbacks depending on the result.
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) =>
      switch (this) {
        Success<T>(:final data) => onSuccess(data),
        Failed<T>(:final failure) => onFailure(failure),
      };
}

// ignore: deprecated_member_use
final class Success<T> extends Result<T> with EquatableMixin {
  const Success(this.data);

  final T data;

  @override
  List<Object?> get props => [data];
}

// ignore: deprecated_member_use
final class Failed<T> extends Result<T> with EquatableMixin {
  const Failed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}