import 'package:flutter/foundation.dart';

import '../models/activity.dart';
import '../models/habit.dart';
import 'database_service.dart';
import 'notification_service.dart';

class HabitProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final NotificationService _notif = NotificationService.instance;

  List<Habit> _habits = [];
  List<ActivityLog> _activities = [];
  List<LocalGroup> _localGroups = [];
  final Map<int, Set<DateTime>> _completions = {};
  final Map<int, Map<DateTime, Completion>> _completionDetails = {};
  String? _selectedPath;

  bool _loaded = false;
  bool get isLoaded => _loaded;
  String? get selectedPath => _selectedPath;
  bool get hasSelectedPath =>
      _selectedPath != null && _selectedPath!.isNotEmpty;

  List<Habit> get habits => List.unmodifiable(_habits);
  List<ActivityLog> get activities => List.unmodifiable(_activities);
  List<LocalGroup> get localGroups => List.unmodifiable(_localGroups);

  // -- Loading --

  Future<void> load() async {
    _selectedPath = await _db.getSetting('selected_path');
    _habits = await _db.getActiveHabits();
    _activities = await _db.getActivities();
    _localGroups = await _db.getLocalGroups();
    if (_localGroups.isEmpty) {
      await _seedDefaultGroups();
      _localGroups = await _db.getLocalGroups();
    }
    _completions.clear();
    _completionDetails.clear();
    for (final h in _habits) {
      if (h.id == null) continue;
      final list = await _db.getCompletionsForHabit(h.id!);
      _completions[h.id!] = list.map((c) => c.dayKey).toSet();
      _completionDetails[h.id!] = {
        for (final c in list) c.dayKey: c,
      };
    }
    _loaded = true;
    notifyListeners();
  }

  // -- Activities --

  Future<void> addActivity(ActivityLog activity) async {
    final id = await _db.insertActivity(activity);
    _activities.insert(
      0,
      ActivityLog(
        id: id,
        type: activity.type,
        durationMinutes: activity.durationMinutes,
        intensity: activity.intensity,
        notes: activity.notes,
        completedAt: activity.completedAt,
      ),
    );
    notifyListeners();
  }

  Future<void> deleteActivity(int activityId) async {
    await _db.deleteActivity(activityId);
    _activities.removeWhere((activity) => activity.id == activityId);
    notifyListeners();
  }

  ActivityLog? get latestActivity {
    if (_activities.isEmpty) return null;
    return _activities.first;
  }

  List<ActivityLog> get activitiesThisWeek {
    final today = _dayKey(DateTime.now());
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    return _activities
        .where((activity) => !activity.dayKey.isBefore(weekStart))
        .toList();
  }

  int get activeMinutesThisWeek {
    return activitiesThisWeek.fold<int>(
      0,
      (total, activity) => total + activity.durationMinutes,
    );
  }

  int get activitySessionsThisWeek => activitiesThisWeek.length;

  Map<String, int> get weeklyMinutesByType {
    final breakdown = <String, int>{};
    for (final activity in activitiesThisWeek) {
      breakdown[activity.type] =
          (breakdown[activity.type] ?? 0) + activity.durationMinutes;
    }
    return breakdown;
  }

  // -- Local groups --

  Future<void> addLocalGroup(LocalGroup group) async {
    final id = await _db.insertLocalGroup(group);
    _localGroups.insert(0, group.copyWith(id: id));
    notifyListeners();
  }

  Future<void> toggleJoinGroup(LocalGroup group) async {
    if (group.id == null) return;
    final updated = group.copyWith(joined: !group.joined);
    await _db.updateLocalGroup(updated);
    final index = _localGroups.indexWhere((item) => item.id == group.id);
    if (index != -1) {
      _localGroups[index] = updated;
      notifyListeners();
    }
  }

  Future<void> _seedDefaultGroups() async {
    final now = DateTime.now();
    final defaults = [
      LocalGroup(
        name: 'Beginner Walk & Talk',
        activityType: 'Walking',
        area: 'Approx. local area',
        skillLevel: 'Beginner',
        createdAt: now,
      ),
      LocalGroup(
        name: 'After Work Badminton',
        activityType: 'Badminton',
        area: 'Nearby sports centre',
        skillLevel: 'All',
        createdAt: now,
      ),
      LocalGroup(
        name: 'Gym Confidence Circle',
        activityType: 'Gym',
        area: 'Local gym zone',
        privacy: 'private',
        skillLevel: 'Beginner',
        createdAt: now,
      ),
    ];
    for (final group in defaults) {
      await _db.insertLocalGroup(group);
    }
  }

  Future<void> setSelectedPath(String pathName) async {
    _selectedPath = pathName;
    await _db.setSetting('selected_path', pathName);
    notifyListeners();
  }

  // -- CRUD --

  Future<void> addHabit(Habit habit) async {
    final newId = await _db.insertHabit(habit);
    final saved = habit.copyWith(id: newId);
    _habits.insert(0, saved);
    _completions[newId] = <DateTime>{};
    _completionDetails[newId] = {};
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
    _completionDetails.remove(habitId);
    notifyListeners();
  }

  // -- Completions --

  Set<DateTime> completionsFor(int habitId) =>
      _completions[habitId] ?? <DateTime>{};

  Completion? completionDetailFor(int habitId, DateTime date) {
    final dayKey = DateTime(date.year, date.month, date.day);
    return _completionDetails[habitId]?[dayKey];
  }

  bool isCompletedToday(int habitId) {
    final today = _dayKey(DateTime.now());
    return completionsFor(habitId).contains(today);
  }

  int todayAmount(int habitId) {
    final detail = completionDetailFor(habitId, DateTime.now());
    return detail?.amount ?? 0;
  }

  // v2: Toggle for checkoff habits
  Future<void> toggleToday(int habitId, {String note = ''}) async {
    final today = _dayKey(DateTime.now());
    final set = _completions.putIfAbsent(habitId, () => <DateTime>{});
    final details = _completionDetails.putIfAbsent(habitId, () => {});

    if (set.contains(today)) {
      set.remove(today);
      details.remove(today);
      await _db.removeCompletion(habitId, today);
    } else {
      set.add(today);
      final completion = Completion(
        habitId: habitId,
        date: today,
        amount: 1,
        note: note,
      );
      details[today] = completion;
      await _db.addCompletion(habitId, today, amount: 1, note: note);
    }
    notifyListeners();
  }

  // v2: Increment amount for flexible goal habits
  Future<void> incrementAmount(int habitId, {int by = 1}) async {
    final today = _dayKey(DateTime.now());
    final set = _completions.putIfAbsent(habitId, () => <DateTime>{});
    final details = _completionDetails.putIfAbsent(habitId, () => {});

    final current = details[today]?.amount ?? 0;
    final newAmount = current + by;

    set.add(today);
    final completion = Completion(
      habitId: habitId,
      date: today,
      amount: newAmount,
      note: details[today]?.note ?? '',
    );
    details[today] = completion;
    await _db.addCompletion(habitId, today,
        amount: newAmount, note: completion.note);
    notifyListeners();
  }

  // v2: Set exact amount for flexible goal habits
  Future<void> setAmount(int habitId, int amount) async {
    final today = _dayKey(DateTime.now());
    final set = _completions.putIfAbsent(habitId, () => <DateTime>{});
    final details = _completionDetails.putIfAbsent(habitId, () => {});

    if (amount <= 0) {
      set.remove(today);
      details.remove(today);
      await _db.removeCompletion(habitId, today);
    } else {
      set.add(today);
      final completion = Completion(
        habitId: habitId,
        date: today,
        amount: amount,
        note: details[today]?.note ?? '',
      );
      details[today] = completion;
      await _db.addCompletion(habitId, today,
          amount: amount, note: completion.note);
    }
    notifyListeners();
  }

  // v2: Add or update diary note for today's completion
  Future<void> addNote(int habitId, String note) async {
    final today = _dayKey(DateTime.now());
    final details = _completionDetails.putIfAbsent(habitId, () => {});
    final set = _completions.putIfAbsent(habitId, () => <DateTime>{});

    if (details.containsKey(today)) {
      // Update existing completion's note
      final existing = details[today]!;
      final updated = Completion(
        id: existing.id,
        habitId: habitId,
        date: today,
        amount: existing.amount,
        note: note,
      );
      details[today] = updated;
      await _db.addCompletion(habitId, today,
          amount: updated.amount, note: note);
    } else {
      // Create new completion with note
      set.add(today);
      final completion = Completion(
        habitId: habitId,
        date: today,
        amount: 1,
        note: note,
      );
      details[today] = completion;
      await _db.addCompletion(habitId, today, amount: 1, note: note);
    }
    notifyListeners();
  }

  // v2: Get all notes for a habit (for diary view)
  List<Completion> getNotesForHabit(int habitId) {
    final details = _completionDetails[habitId] ?? {};
    return details.values.where((c) => c.note.isNotEmpty).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // -- Streaks --

  int currentStreak(int habitId) {
    final habit =
        _habits.firstWhere((h) => h.id == habitId, orElse: () => _habits.first);

    if (habit.isQuitHabit) {
      return _quitStreak(habitId);
    }

    final days = completionsFor(habitId);
    if (days.isEmpty) return 0;

    if (habit.isAmountTracking) {
      return _amountStreak(habitId, habit.targetAmount);
    }

    return _checkoffStreak(habitId);
  }

  // Standard checkoff streak
  int _checkoffStreak(int habitId) {
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

  // Amount-based streak: only count days where target was met
  int _amountStreak(int habitId, int target) {
    final details = _completionDetails[habitId] ?? {};
    if (details.isEmpty) return 0;

    var cursor = _dayKey(DateTime.now());
    final todayDetail = details[cursor];
    if (todayDetail == null || todayDetail.amount < target) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (true) {
      final detail = details[cursor];
      if (detail == null || detail.amount < target) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // Quit habit streak: days since last occurrence
  int _quitStreak(int habitId) {
    final days = completionsFor(habitId);
    if (days.isEmpty) {
      // Never logged = count from habit creation date
      final habit = _habits.firstWhere((h) => h.id == habitId);
      return DateTime.now().difference(habit.createdAt).inDays;
    }

    // Find the most recent completion (most recent "slip")
    final sorted = days.toList()..sort((a, b) => b.compareTo(a));
    final lastSlip = sorted.first;
    return DateTime.now().difference(lastSlip).inDays;
  }

  Set<DateTime> completionsInMonth(int habitId, DateTime month) {
    final days = completionsFor(habitId);
    return days
        .where((d) => d.year == month.year && d.month == month.month)
        .toSet();
  }

  int get completedTodayCount {
    return _habits.where((h) {
      if (h.id == null) return false;
      if (h.isQuitHabit) {
        return !isCompletedToday(h.id!); // Quit: NOT logging is good
      }
      if (h.isAmountTracking) return todayAmount(h.id!) >= h.targetAmount;
      return isCompletedToday(h.id!);
    }).length;
  }

  // -- Export --

  String exportAsCsv() {
    final buf = StringBuffer()
      ..writeln(
        'Habit,Path,Anchor,Fallback,Celebration,Type,Tracking,Streak,Total Completions,Created',
      );
    for (final h in _habits) {
      if (h.id == null) continue;
      final streak = currentStreak(h.id!);
      final total = completionsFor(h.id!).length;
      final created = h.createdAt.toIso8601String().split('T').first;
      buf.writeln(
        [
          h.name,
          h.pathName,
          h.anchor,
          h.fallbackBehavior,
          h.celebration,
          h.habitType,
          h.trackingType,
          '$streak',
          '$total',
          created,
        ].map(_csvCell).join(','),
      );
    }
    return buf.toString();
  }

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') || escaped.contains('"')) {
      return '"$escaped"';
    }
    return escaped;
  }

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);
}
