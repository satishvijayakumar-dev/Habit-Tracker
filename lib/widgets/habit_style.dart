import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Maps stable string keys (stored in the DB) to Flutter Color/IconData
/// objects. Keeping the DB string-based means we don't break when icon
/// codepoints change between Flutter versions.
///
/// The palette is the curated Midnight Coach accent set — desaturated,
/// dark-surface-safe hues that sit well next to the brand coral.

const Map<String, Color> kHabitColors = {
  'blue': Color(0xFF5BC0EB), // sky
  'red': Ah.accent, // coral
  'green': Ah.mint,
  'orange': Ah.warning, // amber
  'purple': Color(0xFF9B8AFB), // violet
  'pink': Color(0xFFF472B6), // rose
  'teal': Color(0xFF2DD4BF),
};

const Map<String, IconData> kHabitIcons = {
  'check_circle': Icons.check_circle_outline,
  'star': Icons.star_outline,
  'favorite': Icons.favorite_outline,
  'local_fire_department': Icons.local_fire_department_outlined,
  'bolt': Icons.bolt_outlined,
  'menu_book': Icons.menu_book_outlined,
  'fitness_center': Icons.fitness_center_outlined,
  'self_improvement': Icons.self_improvement_outlined,
  'water_drop': Icons.water_drop_outlined,
  'directions_run': Icons.directions_run_outlined,
  'directions_walk': Icons.directions_walk_outlined,
  'route': Icons.route_outlined,
  'groups': Icons.groups_outlined,
  'sports_tennis': Icons.sports_tennis_outlined,
  'business_center': Icons.business_center_outlined,
  'edit_note': Icons.edit_note_outlined,
  'laptop_mac': Icons.laptop_mac_outlined,
  'restaurant': Icons.restaurant_outlined,
  'center_focus_strong': Icons.center_focus_strong_outlined,
  'bedtime': Icons.bedtime_outlined,
};

Color colorFor(String name) => kHabitColors[name] ?? const Color(0xFF5BC0EB);

IconData iconFor(String name) =>
    kHabitIcons[name] ?? Icons.check_circle_outline;
