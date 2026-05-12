import 'package:flutter/foundation.dart';

import '../models/habit.dart';
import 'database_service.dart';
import 'notification_service.dart';

/// Holds the list of habits and per-habit completions in memory and
/// keeps them synced with the database. UI listens via Provider.
class HabitProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final NotificationService _notif = NotificationService.instance;

  List<Habit> _habits = [];

  /// Map of habit id -> Set of normalized (year, month, day) DateTimes
  /// for that habit's completions. Set, not List, so streak/lookup is O(1)
  /// and we never double-count a day.
  final Map<int, Set<DateTime>> _completions = {};

  bool _loaded = false;
  bool get isLoaded => _loaded;

  List<Habit> get habits => List.unmodifiable(_habits);

  // ── Loading ────────────────────────────────────────────────────────────────

  Future<void> load() async {
    _habits = await _db.getActiveHabits();
    _completions.clear();
    for (final h in _habits) {
      if (h.id == null) continue;
      final list = await _db.getCompletionsForHabit(h.id!);
      _completions[h.id!] = list.map((c) => c.dayKey).toSet();
    }
    _loaded = true;
    notifyListeners();
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Future<void> addHabit(Habit habit) async {
    final newId = await _db.insertHabit(habit);
    final saved = habit.copyWith(id: newId);
    _habits.insert(0, saved);
    _completions[newId] = <DateTime>{};
    if (saved.hasReminder) {
      await _notif.scheduleForHabit(saved);
    }
    notifyListeners();
  }

  Future<void> updateHabit(Habit habit) async {
    if (habit.id == null) return;
    await _db.updateHabit(habit);
    final idx = _habits.indexWhere((h) => h.id == habit.id);
    if (idx != -1) _habits[idx] = habit;

    // Re-sync notification: cancel old, schedule new if applicable.
    await _notif.cancelForHabit(habit.id!);
    if (habit.hasReminder) {
      await _notif.scheduleForHabit(habit);
    }
    notifyListeners();
  }

  Future<void> deleteHabit(int habitId) async {
    await _notif.cancelForHabit(habitId);
    await _db.deleteHabit(habitId);
    _habits.removeWhere((h) => h.id == habitId);
    _completions.remove(habitId);
    notifyListeners();
  }

  // ── Completions ────────────────────────────────────────────────────────────

  Set<DateTime> completionsFor(int habitId) =>
      _completions[habitId] ?? <DateTime>{};

  bool isCompletedToday(int habitId) {
    final today = _dayKey(DateTime.now());
    return completionsFor(habitId).contains(today);
  }

  Future<void> toggleToday(int habitId) async {
    final today = _dayKey(DateTime.now());
    final set = _completions.putIfAbsent(habitId, () => <DateTime>{});
    if (set.contains(today)) {
      set.remove(today);
      await _db.removeCompletion(habitId, today);
    } else {
      set.add(today);
      await _db.addCompletion(habitId, today);
    }
    notifyListeners();
  }

  /// Current streak: number of consecutive days up to today (or up to
  /// yesterday if today isn't done — we don't break the streak just because
  /// the user hasn't checked in yet today).
  int currentStreak(int habitId) {
    final days = completionsFor(habitId);
    if (days.isEmpty) return 0;

    var cursor = _dayKey(DateTime.now());
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Returns completions for [habitId] within the given month.
  Set<DateTime> completionsInMonth(int habitId, DateTime month) {
    final days = completionsFor(habitId);
    return days
        .where((d) => d.year == month.year && d.month == month.month)
        .toSet();
  }

  int get completedTodayCount {
    return _habits.where((h) => h.id != null && isCompletedToday(h.id!)).length;
  }

  // ── Export ─────────────────────────────────────────────────────────────────

  String exportAsCsv() {
    final buf = StringBuffer()
      ..writeln('Habit,Streak,Total Completions,Created');
    for (final h in _habits) {
      if (h.id == null) continue;
      final streak = currentStreak(h.id!);
      final total = completionsFor(h.id!).length;
      final created = h.createdAt.toIso8601String().split('T').first;
      // Escape commas in names by wrapping in quotes.
      final safeName = h.name.contains(',') ? '"${h.name}"' : h.name;
      buf.writeln('$safeName,$streak,$total,$created');
    }
    return buf.toString();
  }

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);
}
