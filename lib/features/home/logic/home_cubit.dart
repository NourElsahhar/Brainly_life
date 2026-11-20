import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:brainly_life/features/home/logic/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the Home dashboard. Every card loads on its own, so one failing
/// card never hides the others.
///
/// Call [load] when the screen opens and every time the user comes back
/// to it, so the numbers stay fresh.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required this._tasks,
    required this._study,
    required this._habits,
    required this._focus,
    required this._tip,
  }) : super(const HomeState());

  final TaskSummaryProvider _tasks;
  final StudySummaryProvider _study;
  final HabitSummaryProvider _habits;
  final FocusSummaryProvider _focus;
  final AiTipProvider _tip;

  /// The number of the latest request of every card, so an older answer
  /// never replaces a newer one.
  final Map<HomeSection, int> _requests = {};

  /// Loads all cards at the same time. Cards that already show data keep
  /// it until the new data comes; cards with an error show loading again.
  Future<void> load() async {
    emit(
      state.copyWith(
        tasks: _loadingIfError(state.tasks),
        study: _loadingIfError(state.study),
        habits: _loadingIfError(state.habits),
        focus: _loadingIfError(state.focus),
        tip: _loadingIfError(state.tip),
      ),
    );
    await Future.wait([
      for (final section in HomeSection.values) _loadSection(section),
    ]);
  }

  /// Loads one card again (its Retry button).
  Future<void> retry(HomeSection section) async {
    emit(switch (section) {
      HomeSection.tasks => state.copyWith(tasks: const HomeCardLoading()),
      HomeSection.study => state.copyWith(study: const HomeCardLoading()),
      HomeSection.habits => state.copyWith(habits: const HomeCardLoading()),
      HomeSection.focus => state.copyWith(focus: const HomeCardLoading()),
      HomeSection.tip => state.copyWith(tip: const HomeCardLoading()),
    });
    await _loadSection(section);
  }

  Future<void> _loadSection(HomeSection section) async {
    final request = (_requests[section] ?? 0) + 1;
    _requests[section] = request;
    bool isOld() => isClosed || _requests[section] != request;

    switch (section) {
      case HomeSection.tasks:
        final result = await _tasks.todaySummary();
        if (isOld()) return;
        emit(state.copyWith(tasks: _toCard(result)));
      case HomeSection.study:
        final result = await _study.nextSession();
        if (isOld()) return;
        emit(state.copyWith(study: _toCard(result)));
      case HomeSection.habits:
        final result = await _habits.todaySummary();
        if (isOld()) return;
        emit(state.copyWith(habits: _toCard(result)));
      case HomeSection.focus:
        final result = await _focus.todaySummary();
        if (isOld()) return;
        emit(state.copyWith(focus: _toCard(result)));
      case HomeSection.tip:
        final result = await _tip.dailyTip();
        if (isOld()) return;
        emit(state.copyWith(tip: _toCard(result)));
    }
  }

  static HomeCard<T> _toCard<T>(Result<T> result) {
    return switch (result) {
      Success(:final data) => HomeCardLoaded<T>(data),
      Failed(:final failure) => HomeCardError<T>(failure),
    };
  }

  static HomeCard<T> _loadingIfError<T>(HomeCard<T> card) {
    return card is HomeCardError<T> ? HomeCardLoading<T>() : card;
  }
}
