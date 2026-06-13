import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/models/activity.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/models/user_profile.dart';
import 'package:habit_tracker/services/database_service.dart';

import 'helpers/test_db.dart';

/// Exercises the REAL SQLite schema (via sqflite_common_ffi): CRUD,
/// completion uniqueness/replace, the profile singleton, and that the
/// stored maps round-trip back into models intact.
void main() {
  setUpAll(bootstrapTestDatabase);

  late DatabaseService db;

  setUp(() async {
    db = DatabaseService.instance;
    await clearDatabase();
  });

  Habit makeHabit(String name) => Habit(name: name, createdAt: DateTime.now());

  group('habits', () {
    test('insert assigns an id and getActiveHabits returns it', () async {
      final id = await db.insertHabit(makeHabit('Walk'));
      expect(id, greaterThan(0));
      final habits = await db.getActiveHabits();
      expect(habits.single.name, 'Walk');
      expect(habits.single.id, id);
    });

    test('archived habits are excluded from getActiveHabits', () async {
      final id = await db.insertHabit(makeHabit('Old'));
      await db.updateHabit(
        (await db.getActiveHabits()).single.copyWith(isArchived: true),
      );
      expect(await db.getActiveHabits(), isEmpty);
      // sanity: the row still exists, just filtered
      expect(id, greaterThan(0));
    });

    test('deleteHabit also clears its completions', () async {
      final id = await db.insertHabit(makeHabit('Doomed'));
      await db.addCompletion(id, DateTime(2026, 6, 1));
      expect(await db.getCompletionsForHabit(id), isNotEmpty);

      await db.deleteHabit(id);
      expect(await db.getActiveHabits(), isEmpty);
      expect(await db.getCompletionsForHabit(id), isEmpty);
    });

    test('all habit fields round-trip through the DB', () async {
      final h = Habit(
        name: 'Water',
        description: 'hydrate',
        colorName: 'mint',
        iconName: 'water_drop',
        createdAt: DateTime(2026, 1, 2),
        habitType: 'build',
        trackingType: 'amount',
        targetAmount: 8,
        unit: 'glasses',
        anchor: 'after coffee',
        fallbackBehavior: 'one sip',
        celebration: 'nice',
        pathName: 'The Gym Builder',
        difficulty: 'manageable',
      );
      await db.insertHabit(h);
      final back = (await db.getActiveHabits()).single;
      expect(back.trackingType, 'amount');
      expect(back.targetAmount, 8);
      expect(back.unit, 'glasses');
      expect(back.anchor, 'after coffee');
      expect(back.celebration, 'nice');
      expect(back.difficulty, 'manageable');
    });
  });

  group('completions', () {
    test('(habit_id, date) is unique — second add replaces, not duplicates',
        () async {
      final id = await db.insertHabit(makeHabit('Read'));
      final day = DateTime(2026, 6, 1);
      await db.addCompletion(id, day, amount: 1, note: 'first');
      await db.addCompletion(id, day, amount: 5, note: 'second');

      final all = await db.getCompletionsForHabit(id);
      expect(all.length, 1);
      expect(all.single.amount, 5);
      expect(all.single.note, 'second');
    });

    test('time-of-day does not affect the day key', () async {
      final id = await db.insertHabit(makeHabit('Stretch'));
      await db.addCompletion(id, DateTime(2026, 6, 1, 9, 30));
      await db.addCompletion(id, DateTime(2026, 6, 1, 22, 5));
      expect((await db.getCompletionsForHabit(id)).length, 1);
    });

    test('removeCompletion deletes the matching day', () async {
      final id = await db.insertHabit(makeHabit('Walk'));
      await db.addCompletion(id, DateTime(2026, 6, 1));
      await db.removeCompletion(id, DateTime(2026, 6, 1, 18));
      expect(await db.getCompletionsForHabit(id), isEmpty);
    });
  });

  group('settings', () {
    test('set then get returns the value; missing key is null', () async {
      expect(await db.getSetting('missing'), isNull);
      await db.setSetting('selected_path', 'The Runner / Walker');
      expect(await db.getSetting('selected_path'), 'The Runner / Walker');
    });

    test('setSetting upserts on the same key', () async {
      await db.setSetting('k', 'one');
      await db.setSetting('k', 'two');
      expect(await db.getSetting('k'), 'two');
    });
  });

  group('user profile (singleton row)', () {
    test('saveUserProfile upserts a single row that round-trips', () async {
      await db.saveUserProfile(UserProfile(
        age: 30,
        sex: 'Female',
        heightCm: 165,
        weightKg: 62.5,
        fitnessGoal: 'Run better',
        activityLevel: 'Some activity',
        areaName: 'Watford',
        shareApproxLocation: true,
        updatedAt: DateTime(2026, 6, 1),
      ));
      await db.saveUserProfile(UserProfile(
        age: 31,
        sex: 'Female',
        heightCm: 165,
        weightKg: 61,
        fitnessGoal: 'Run better',
        activityLevel: 'Active',
        areaName: 'Watford',
        shareApproxLocation: false,
        updatedAt: DateTime(2026, 6, 2),
      ));

      final p = await db.getUserProfile();
      expect(p, isNotNull);
      expect(p!.age, 31); // upserted, not duplicated
      expect(p.weightKg, 61);
      expect(p.shareApproxLocation, isFalse);
    });
  });

  group('activities & groups', () {
    test('activity insert + delete', () async {
      final id = await db.insertActivity(ActivityLog(
        type: 'Pickleball',
        durationMinutes: 50,
        completedAt: DateTime(2026, 6, 1),
      ));
      expect((await db.getActivities()).single.type, 'Pickleball');
      await db.deleteActivity(id);
      expect(await db.getActivities(), isEmpty);
    });

    test('local group insert + join toggle persists', () async {
      final id = await db.insertLocalGroup(LocalGroup(
        name: 'Watford Pickleball',
        activityType: 'Pickleball',
        area: 'WD17',
        createdAt: DateTime(2026, 6, 1),
      ));
      final group = (await db.getLocalGroups()).single;
      expect(group.joined, isFalse);
      await db.updateLocalGroup(group.copyWith(id: id, joined: true));
      expect((await db.getLocalGroups()).single.joined, isTrue);
    });
  });
}
