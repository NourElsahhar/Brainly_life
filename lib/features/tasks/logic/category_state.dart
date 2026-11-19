import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:equatable/equatable.dart';

/// What the categories screen shows.
sealed class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

final class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

final class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

/// The user's categories, sorted by name. May be empty.
final class CategoryLoaded extends CategoryState {
  const CategoryLoaded(this.categories);

  final List<TaskCategory> categories;

  @override
  List<Object?> get props => [categories];
}

/// The categories could not load. Show Retry, which calls `load()`.
final class CategoryError extends CategoryState {
  const CategoryError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
