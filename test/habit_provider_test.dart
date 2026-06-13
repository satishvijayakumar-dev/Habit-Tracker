import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/models/activity.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/models/user_profile.dart';
import 'package:habit_tracker/services/habit_provider.dart';

import 'helpers/in_memory_store.dart';

void main() {
  late HabitProvider provider;

  setUp(() async {
    provider = HabitProvider(store: InMemoryHabitStore());
    await provider.load();
  });

  Habit makeHabit(String name,
      {String type = 'build', String tracking = 'checkoff', int target = 1}) {
    return Habit(
      name: name,
      createdAt: DateTime.now(),
      habitType: type,
      trackingType: tracking,
      targetAmount: target,
      celebration: 'That counts',
    );
  }

  group('load & seeding', () {
    test('seeds 3 default community groups on first run', () {
      expect(provider.localGroups.length, 3);
      expect(
        provider.localGroups.map((g) => g.activityType),
        containsAll(['Walking', 'Badminton', 'Gym']),
      );
    });

    test('starts with no habits, no profile, not pro', () {
      expect(provider.habits, isEmpty);
      expect(provider.hasProfile, isFalse);
      expect(provider.isPro, isFalse);
      expect(provider.userName, isEmpty);
    });
  });

  group('habit CRUD + completions', () {
    test('add, toggle today, streak = 1, untoggle back to 0', () async {
      await provider.addHabit(makeHabit('Morning water'));
      final id = provider.habits.first.id!;

      expect(provider.isCompletedToday(id), isFalse);
      await provider.toggleToday(id);
      expect(provider.isCompletedToday(id), isTrue);
      expect(provider.currentStreak(id), 1);
      expect(provider.completedTodayCount, 1);

      await provider.toggleToday(id);
      expect(provider.isCompletedToday(id), isFalse);
      expect(provider.currentStreak(id), 0);
    });

    test('completions survive a provider reload (store round-trip)', () async {
      final store = InMemoryHabitStore();
      final p1 = HabitProvider(store: store);
      await p1.load();
      await p1.addHabit(makeHabit('Read'));
      final id = p1.habits.first.id!;
      await p1.toggleToday(id, note: 'chapter 4');

      final p2 = HabitProvider(store: store);
      await p2.load();
      expect(p2.isCompletedToday(id), isTrue);
      expect(p2.completionDetailFor(id, DateTime.now())?.note, 'chapter 4');
    });

    test('amount tracking: increments accumulate and hit the target', () async {
      await provider
          .addHabit(makeHabit('Water', tracking: 'amount', target: 3));
      final id = provider.habits.first.id!;

      await provider.incrementAmount(id);
      await provider.incrementAmount(id);
      expect(provider.todayAmount(id), 2);
      expect(provider.completedTodayCount, 0); // target not met yet

      await provider.incrementAmount(id);
      expect(provider.todayAmount(id), 3);
      expect(provider.completedTodayCount, 1);
      expect(provider.currentStreak(id), 1);
    });

    test('REGRESSION: streak lookup after habit deletion returns 0, no crash',
        () async {
      await provider.addHabit(makeHabit('Doomed'));
      final id = provider.habits.first.id!;
      await provider.deleteHabit(id);

      expect(provider.habits, isEmpty);
      // v1.5.0 crashed here (orElse: habits.first on an empty list).
      expect(provider.currentStreak(id), 0);
      expect(provider.completedTodayCount, 0);
    });

    test('quit habit: not logging counts as protected', () async {
      await provider.addHabit(makeHabit('No late snacks', type: 'quit'));
      final id = provider.habits.first.id!;

      expect(provider.completedTodayCount, 1); // clean day = protected
      await provider.toggleToday(id); // log a slip
      expect(provider.completedTodayCount, 0);
      expect(provider.currentStreak(id), 0);
    });
  });

  group('check-in persistence', () {
    test('saveCheckIn round-trips through the store and a fresh provider',
        () async {
      final store = InMemoryHabitStore();
      final p1 = HabitProvider(store: store);
      await p1.load();
      expect(p1.hasCheckedInToday, isFalse);
      await p1.saveCheckIn(
        energy: 'Low',
        soreness: 'High',
        time: '15 min',
        mood: 'Tired',
      );
      expect(p1.todayCheckIn['soreness'], 'High');

      final p2 = HabitProvider(store: store);
      await p2.load();
      expect(p2.hasCheckedInToday, isTrue);
      expect(p2.todayCheckIn['energy'], 'Low');
      expect(p2.todayCheckIn['mood'], 'Tired');
    });
  });

  group('identity & entitlement', () {
    test('userName persists and trims', () async {
      final store = InMemoryHabitStore();
      final p1 = HabitProvider(store: store);
      await p1.load();
      await p1.setUserName('  Sam  ');
      expect(p1.userName, 'Sam');

      final p2 = HabitProvider(store: store);
      await p2.load();
      expect(p2.userName, 'Sam');
    });

    test('free tier caps at 3 loops; Pro removes the cap', () async {
      final store = InMemoryHabitStore();
      final p1 = HabitProvider(store: store);
      await p1.load();
      for (final name in ['One', 'Two', 'Three']) {
        await p1.addHabit(makeHabit(name));
      }
      expect(p1.canAddLoop, isFalse);

      await p1.setPro(true);
      expect(p1.canAddLoop, isTrue);

      final p2 = HabitProvider(store: store);
      await p2.load();
      expect(p2.isPro, isTrue);
    });
  });

  group('activity & insights', () {
    test('logged activity feeds weekly minutes, sessions, and star points',
        () async {
      await provider.addActivity(ActivityLog(
        type: 'Badminton',
        durationMinutes: 40,
        intensity: 'Moderate',
        completedAt: DateTime.now(),
      ));

      expect(provider.activeMinutesThisWeek, 40);
      expect(provider.activitySessionsThisWeek, 1);
      expect(provider.weeklyMinutesByType['Badminton'], 40);
      // movement (40~/10=4) + session (5) = 9
      expect(provider.starPoints, 9);
      expect(provider.estimatedCaloriesThisWeek, greaterThan(0));
    });

    test('weekly minutes target follows activity level', () async {
      expect(provider.weeklyMinutesTarget, 150); // no profile -> default

      await provider.saveProfile(UserProfile(
        age: 35,
        sex: 'Male',
        heightCm: 178,
        weightKg: 80,
        fitnessGoal: 'Build strength',
        activityLevel: 'Active',
        areaName: 'Watford',
        shareApproxLocation: false,
        updatedAt: DateTime.now(),
      ));
      expect(provider.weeklyMinutesTarget, 200);
    });
  });

  group('export', () {
    test('CSV export includes habit rows and escapes commas', () async {
      await provider.addHabit(makeHabit('Read, daily'));
      final csv = provider.exportAsCsv();
      expect(csv, contains('Habit,Path,Anchor'));
      expect(csv, contains('"Read, daily"'));
    });
  });
}
