import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/services/badges.dart';

void main() {
  const empty = BadgeStats(
    totalActivities: 0,
    sessionsThisWeek: 0,
    dailyStreak: 0,
    starPoints: 0,
    loggedGym: false,
    dayClosed: false,
    inCommunity: false,
  );

  test('a brand-new user has earned nothing', () {
    expect(Badges.earnedCount(empty), 0);
  });

  test('first activity earns First Step', () {
    final s = Badges.evaluate(const BadgeStats(
      totalActivities: 1,
      sessionsThisWeek: 1,
      dailyStreak: 1,
      starPoints: 9,
      loggedGym: false,
      dayClosed: false,
      inCommunity: false,
    ));
    final firstStep = s.firstWhere((b) => b.def.id == 'first_step');
    expect(firstStep.earned, isTrue);
  });

  test('7-day streak earns the mover badge; 6 days does not', () {
    BadgeStatus mover(int streak) => Badges.evaluate(BadgeStats(
          totalActivities: 5,
          sessionsThisWeek: 2,
          dailyStreak: streak,
          starPoints: 50,
          loggedGym: false,
          dayClosed: false,
          inCommunity: false,
        )).firstWhere((b) => b.def.id == 'mover_7');
    expect(mover(6).earned, isFalse);
    expect(mover(6).progress, '6/7 day streak');
    expect(mover(7).earned, isTrue);
  });

  test('gym session and 100 points unlock their badges', () {
    final s = Badges.evaluate(const BadgeStats(
      totalActivities: 10,
      sessionsThisWeek: 4,
      dailyStreak: 7,
      starPoints: 120,
      loggedGym: true,
      dayClosed: true,
      inCommunity: true,
    ));
    expect(s.where((b) => b.earned).length,
        Badges.all.length); // everything earned
  });

  test('progress hints are present on locked badges', () {
    final s = Badges.evaluate(empty);
    expect(
        s.where((b) => !b.earned).every((b) => b.progress.isNotEmpty), isTrue);
  });
}
