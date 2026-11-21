import '../data/models/analytics_models.dart';

class ProductivityScore {
  const ProductivityScore();

  static const taskWeight = 35;
  static const studyWeight = 25;
  static const habitWeight = 20;
  static const focusWeight = 20;

  int? calculate(WeeklyStats stats) {
    final components = <(int, double)>[
      if (stats.tasksCount > 0) (taskWeight, stats.taskRate),
      if (stats.studyPlanned > 0) (studyWeight, stats.studyRate),
      if (stats.habitsDue > 0) (habitWeight, stats.habitRate),
      if (stats.focusPlanned > 0) (focusWeight, stats.focusRate),
    ];
    if (components.isEmpty) return null;
    final weighted = components.fold(
      0.0,
      (sum, pair) => sum + pair.$1 * pair.$2,
    );
    final available = components.fold(0, (sum, pair) => sum + pair.$1);
    return (100 * weighted / available).round();
  }
}
