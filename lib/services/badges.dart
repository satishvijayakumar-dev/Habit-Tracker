/// Achievement badges. Pure (no Flutter): icon/colour are carried as string
/// keys the UI maps to IconData/Color, so the earn logic is unit-testable.
///
/// Badges turn "stale points" into meaningful, earned status.
library;

class BadgeDef {
  final String id;
  final String name;
  final String description;
  final String iconName; // mapped in the UI
  final String colorName; // mapped in the UI

  const BadgeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.colorName,
  });
}

class BadgeStatus {
  final BadgeDef def;
  final bool earned;

  /// Short progress hint for locked badges, e.g. "3/7 day streak".
  final String progress;

  const BadgeStatus(
      {required this.def, required this.earned, this.progress = ''});
}

/// Snapshot of the stats badges are evaluated against.
class BadgeStats {
  final int totalActivities;
  final int sessionsThisWeek;
  final int dailyStreak;
  final int starPoints;
  final bool loggedGym;
  final bool dayClosed; // all loops protected today
  final bool inCommunity;

  const BadgeStats({
    required this.totalActivities,
    required this.sessionsThisWeek,
    required this.dailyStreak,
    required this.starPoints,
    required this.loggedGym,
    required this.dayClosed,
    required this.inCommunity,
  });
}

abstract final class Badges {
  static const all = [
    BadgeDef(
      id: 'first_step',
      name: 'First Step',
      description: 'Log your first activity',
      iconName: 'directions_walk',
      colorName: 'mint',
    ),
    BadgeDef(
      id: 'consistent',
      name: 'Consistent',
      description: '3 sessions in a week',
      iconName: 'event_available',
      colorName: 'orange',
    ),
    BadgeDef(
      id: 'mover_7',
      name: '7-Day Mover',
      description: 'Stay active 7 days in a row',
      iconName: 'local_fire_department',
      colorName: 'red',
    ),
    BadgeDef(
      id: 'strength_starter',
      name: 'Strength Starter',
      description: 'Complete a gym session',
      iconName: 'fitness_center',
      colorName: 'purple',
    ),
    BadgeDef(
      id: 'loop_closer',
      name: 'Loop Closer',
      description: 'Close every loop in a day',
      iconName: 'donut_large',
      colorName: 'teal',
    ),
    BadgeDef(
      id: 'century',
      name: 'Century',
      description: 'Earn 100 star points',
      iconName: 'star',
      colorName: 'red',
    ),
    BadgeDef(
      id: 'community_member',
      name: 'Community Member',
      description: 'Join the community',
      iconName: 'groups',
      colorName: 'blue',
    ),
  ];

  static List<BadgeStatus> evaluate(BadgeStats s) {
    return [
      BadgeStatus(
        def: all[0],
        earned: s.totalActivities >= 1,
        progress: s.totalActivities >= 1 ? '' : 'Log 1 activity',
      ),
      BadgeStatus(
        def: all[1],
        earned: s.sessionsThisWeek >= 3,
        progress:
            s.sessionsThisWeek >= 3 ? '' : '${s.sessionsThisWeek}/3 sessions',
      ),
      BadgeStatus(
        def: all[2],
        earned: s.dailyStreak >= 7,
        progress: s.dailyStreak >= 7 ? '' : '${s.dailyStreak}/7 day streak',
      ),
      BadgeStatus(
        def: all[3],
        earned: s.loggedGym,
        progress: s.loggedGym ? '' : 'Log a gym session',
      ),
      BadgeStatus(
        def: all[4],
        earned: s.dayClosed,
        progress: s.dayClosed ? '' : 'Close all loops today',
      ),
      BadgeStatus(
        def: all[5],
        earned: s.starPoints >= 100,
        progress: s.starPoints >= 100 ? '' : '${s.starPoints}/100 points',
      ),
      BadgeStatus(
        def: all[6],
        earned: s.inCommunity,
        progress: s.inCommunity ? '' : 'Opt in to community',
      ),
    ];
  }

  static int earnedCount(BadgeStats s) =>
      evaluate(s).where((b) => b.earned).length;
}
