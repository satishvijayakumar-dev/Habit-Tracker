import 'package:flutter/material.dart';

/// Maps stable string keys (stored in the DB) to Flutter Color/IconData
/// objects. Keeping the DB string-based means we don't break when icon
/// codepoints change between Flutter versions.

const Map<String, Color> kHabitColors = {
  'blue': Colors.blue,
  'red': Colors.red,
  'green': Colors.green,
  'orange': Colors.orange,
  'purple': Colors.purple,
  'pink': Colors.pink,
  'teal': Colors.teal,
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

Color colorFor(String name) => kHabitColors[name] ?? Colors.blue;

IconData iconFor(String name) =>
    kHabitIcons[name] ?? Icons.check_circle_outline;
