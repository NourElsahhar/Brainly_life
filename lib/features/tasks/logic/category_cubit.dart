import 'dart:async';

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_category_repository.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_repository.dart';
import 'package:brainly_life/features/tasks/logic/category_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the categories screen: list, create, rename, recolour, delete.
///
/// Every action returns null when it worked, or the [Failure] to show
/// (under the name field, or in a snackbar).
class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit(this._categories, this._tasks) : super(const CategoryInitial());

  final TaskCategoryRepository _categories;
  final TaskRepository _tasks;
  StreamSubscription<Result<List<TaskCategory>>>? _subscription;
  List<TaskCategory> _current = const [];

  /// Starts listening to the categories. Call it again to retry.
  Future<void> load() async {
    emit(const CategoryLoading());
    await _subscription?.cancel();
    _subscription = _categories.watchCategories().listen((result) {
      switch (result) {
        case Success(:final data):
          _current = data;
          emit(CategoryLoaded(data));
        case Failed(:final failure):
          emit(CategoryError(failure));
      }
    });
  }

  Future<Failure?> create(String name, int colorValue) async {
    final cleanName = name.trim();
    final problem = _checkName(cleanName);
    if (problem != null) return ValidationFailure(userMessage: problem);

    final result = await _categories.createCategory(
      TaskCategory(id: '', name: cleanName, colorValue: colorValue),
    );
    return result.failureOrNull;
  }

  Future<Failure?> rename(TaskCategory category, String name) async {
    final cleanName = name.trim();
    final problem = _checkName(cleanName, exceptId: category.id);
    if (problem != null) return ValidationFailure(userMessage: problem);

    final result = await _categories.updateCategory(
      category.copyWith(name: cleanName),
    );
    return result.failureOrNull;
  }

  Future<Failure?> recolor(TaskCategory category, int colorValue) async {
    final result = await _categories.updateCategory(
      category.copyWith(colorValue: colorValue),
    );
    return result.failureOrNull;
  }

  /// Deletes the category, then makes its tasks Uncategorized.
  /// Ask the user to confirm before calling it.
  Future<Failure?> delete(TaskCategory category) async {
    final deleted = await _categories.deleteCategory(category.id);
    if (deleted case Failed(:final failure)) return failure;

    final cleared = await _tasks.clearCategory(category.id);
    return cleared.failureOrNull;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }

  /// A message when [name] can't be used, otherwise null.
  /// [exceptId] is the category being renamed, so it can keep its name.
  String? _checkName(String name, {String? exceptId}) {
    if (name.isEmpty) return 'Please enter a category name.';
    if (name.length > TaskCategoryRepository.maxNameLength) {
      return 'A category name can be at most '
          '${TaskCategoryRepository.maxNameLength} characters.';
    }
    final lower = name.toLowerCase();
    final taken = _current.any(
      (c) => c.id != exceptId && c.name.toLowerCase() == lower,
    );
    if (taken) return 'You already have a category with this name.';
    return null;
  }
}
