// HabitTemplate = a quick starting point shown on the empty Habits screen.
// Tapping one opens the new habit form with the name and icon already filled.

import 'package:brainly_life/core/constants/app_strings.dart';

class HabitTemplate {
  const HabitTemplate({required this.name, required this.icon});

  final String name;

  /// An icon key from habit_icons.dart.
  final String icon;
}

const List<HabitTemplate> habitTemplates = [
  HabitTemplate(name: AppStrings.habitTemplateRead, icon: 'book'),
  HabitTemplate(name: AppStrings.habitTemplateWater, icon: 'water'),
  HabitTemplate(name: AppStrings.habitTemplateWalk, icon: 'walk'),
];
