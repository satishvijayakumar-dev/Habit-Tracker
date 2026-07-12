import 'package:habit_tracker/models/activity.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/models/user_profile.dart';
import 'package:habit_tracker/services/habit_store.dart';

/// In-memory [HabitStore] for tests. Mirrors the SQLite semantics the
/// provider relies on: auto-incrementing ids, a singleton profile row,
/// and (habitId, dayKey)-unique completions with replace-on-conflict.
class InMemoryHabitStore implements HabitStore {
  final Map<String, String> _settings = {};
  UserProfile? _profile;
  final List<BodyMetric> _bodyMetrics = [];
  final List<Habit> _habits = [];
  final Map<int, List<Completion>> _completions = {};
  final List<ActivityLog> _activities = [];
  final List<LocalGroup> _groups = [];

  int _habitId = 0;
  int _metricId = 0;
  int _activityId = 0;
  int _groupId = 0;

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  // -- Settings --
  @override
  Future<String?> getSetting(String key) async => _settings[key];

  @override
  Future<void> setSetting(String key, String value) async {
    _settings[key] = value;
  }

  // -- Profile & body metrics --
  @override
  Future<UserProfile?> getUserProfile() async => _profile;

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    _profile = profile.copyWith(id: 1);
  }

  @override
  Future<List<BodyMetric>> getBodyMetrics() async =>
      [..._bodyMetrics]..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

  @override
  Future<int> insertBodyMetric(BodyMetric metric) async {
    final id = ++_metricId;
    _bodyMetrics.add(BodyMetric(
      id: id,
      weightKg: metric.weightKg,
      waistCm: metric.waistCm,
      note: metric.note,
      recordedAt: metric.recordedAt,
    ));
    return id;
  }

  // -- Habits --
  @override
  Future<List<Habit>> getActiveHabits() async =>
      _habits.where((h) => !h.isArchived).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<int> insertHabit(Habit habit) async {
    final id = ++_habitId;
    _habits.add(habit.copyWith(id: id));
    _completions[id] = [];
    return id;
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final i = _habits.indexWhere((h) => h.id == habit.id);
    if (i != -1) _habits[i] = habit;
  }

  @override
  Future<void> deleteHabit(int habitId) async {
    _habits.removeWhere((h) => h.id == habitId);
    _completions.remove(habitId);
  }

  // -- Completions --
  @override
  Future<List<Completion>> getCompletionsForHabit(int habitId) async =>
      [...?_completions[habitId]];

  @override
  Future<void> addCompletion(int habitId, DateTime date,
      {int amount = 1, String note = ''}) async {
    final key = _dayKey(date);
    final list = _completions.putIfAbsent(habitId, () => []);
    list.removeWhere((c) => c.dayKey == key); // replace-on-conflict
    list.add(
        Completion(habitId: habitId, date: key, amount: amount, note: note));
  }

  @override
  Future<void> removeCompletion(int habitId, DateTime date) async {
    final key = _dayKey(date);
    _completions[habitId]?.removeWhere((c) => c.dayKey == key);
  }

  // -- Activities --
  @override
  Future<List<ActivityLog>> getActivities() async =>
      [..._activities]..sort((a, b) => b.completedAt.compareTo(a.completedAt));

  @override
  Future<int> insertActivity(ActivityLog activity) async {
    final id = ++_activityId;
    _activities.add(ActivityLog(
      id: id,
      type: activity.type,
      durationMinutes: activity.durationMinutes,
      intensity: activity.intensity,
      notes: activity.notes,
      completedAt: activity.completedAt,
    ));
    return id;
  }

  @override
  Future<void> deleteActivity(int activityId) async {
    _activities.removeWhere((a) => a.id == activityId);
  }

  // -- Local groups --
  @override
  Future<List<LocalGroup>> getLocalGroups() async =>
      [..._groups]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<int> insertLocalGroup(LocalGroup group) async {
    final id = ++_groupId;
    _groups.add(group.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateLocalGroup(LocalGroup group) async {
    final i = _groups.indexWhere((g) => g.id == group.id);
    if (i != -1) _groups[i] = group;
  }

  @override
  Future<void> wipeAll() async {
    _settings.clear();
    _profile = null;
    _bodyMetrics.clear();
    _habits.clear();
    _completions.clear();
    _activities.clear();
    _groups.clear();
    _habitId = 0;
    _metricId = 0;
    _activityId = 0;
    _groupId = 0;
  }
}
