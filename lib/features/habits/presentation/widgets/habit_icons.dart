// The icons a habit can use. A habit stores only the key (a String), and this
// file turns the key into an icon. Unknown keys show a check icon, so an old
// or wrong key never breaks a screen. The form uses these keys, in this order.

import 'package:flutter/material.dart';

const Map<String, IconData> habitIcons = {
  'book': Icons.menu_book_rounded,
  'water': Icons.water_drop_outlined,
  'walk': Icons.directions_run_rounded,
  'leaf': Icons.eco_outlined,
  'fitness': Icons.fitness_center_rounded,
  'sleep': Icons.nightlight_round,
  'write': Icons.edit_outlined,
  'music': Icons.music_note_rounded,
};

IconData habitIconFor(String key) =>
    habitIcons[key] ?? Icons.check_circle_outline_rounded;
