import '../models/activity.dart';
import '../models/habit.dart';
import '../models/user_profile.dart';

/// Persistence seam for [HabitProvider].
///
/// [DatabaseService] is the production (SQLite) implementation. Tests
/// inject an in-memory implementation so provider/flow logic can be
/// exercised without a real database (and without native code assets,
/// which the Flutter test toolchain handles poorly on some platforms).
abstract class HabitStore {
  // Settings
  Future<String?> getSetting(String key);
  Future<void> setSetting(String key, String value);

  // Profile & body metrics
  Future<UserProfile?> getUserProfile();
  Future<void> saveUserProfile(UserProfile profile);
  Future<List<BodyMetric>> getBodyMetrics();
  Future<int> insertBodyMetric(BodyMetric metric);

  // Habits
  Future<List<Habit>> getActiveHabits();
  Future<int> insertHabit(Habit habit);
  Future<void> updateHabit(Habit habit);
  Future<void> deleteHabit(int habitId);

  // Completions
  Future<List<Completion>> getCompletionsForHabit(int habitId);
  Future<void> addCompletion(int habitId, DateTime date,
      {int amount = 1, String note = ''});
  Future<void> removeCompletion(int habitId, DateTime date);

  // Activities
  Future<List<ActivityLog>> getActivities();
  Future<int> insertActivity(ActivityLog activity);
  Future<void> deleteActivity(int activityId);

  // Local groups
  Future<List<LocalGroup>> getLocalGroups();
  Future<int> insertLocalGroup(LocalGroup group);
  Future<void> updateLocalGroup(LocalGroup group);

  /// Irreversibly delete ALL locally stored data — habits, completions,
  /// activities, body metrics, profile, local groups, and settings. Used by
  /// the account-deletion flow so nothing personal survives on-device.
  Future<void> wipeAll();
}
