import 'package:flutter/foundation.dart';

import '../models/activity.dart';
import '../models/habit.dart';
import '../models/user_profile.dart';
import 'activity_energy.dart';
import 'badges.dart';
import 'database_service.dart';
import 'habit_store.dart';
import 'notification_service.dart';
import 'streak_engine.dart';

class HabitProvider extends ChangeNotifier {
  /// Persistence backend. Defaults to the SQLite [DatabaseService];
  /// tests inject an in-memory [HabitStore].
  final HabitStore _db;
  final NotificationService _notif = NotificationService.instance;

  HabitProvider({HabitStore? store}) : _db = store ?? DatabaseService.instance;

  /// Free tier: up to this many active loops. Pro removes the cap.
  static const int freeLoopLimit = 3;

  List<Habit> _habits = [];
  List<ActivityLog> _activities = [];
  List<LocalGroup> _localGroups = [];
  List<BodyMetric> _bodyMetrics = [];
  final Map<int, Set<DateTime>> _completions = {};
  final Map<int, Map<DateTime, Completion>> _completionDetails = {};
  String? _selectedPath;
  UserProfile? _profile;
  String _userName = '';
  bool _isPro = false;
  Map<String, String> _todayCheckIn = {};

  bool _loaded = false;
  bool get isLoaded => _loaded;
  String? get selectedPath => _selectedPath;
  bool get hasSelectedPath =>
      _selectedPath != null && _selectedPath!.isNotEmpty;
  UserProfile? get profile => _profile;
  bool get hasProfile => _profile?.isComplete ?? false;
  String get userName => _userName;
  bool get isPro => _isPro;
  bool get canAddLoop => _isPro || _habits.length < freeLoopLimit;
  Map<String, String> get todayCheckIn => Map.unmodifiable(_todayCheckIn);
  bool get hasCheckedInToday => _todayCheckIn.isNotEmpty;

  List<Habit> get habits => List.unmodifiable(_habits);
  List<ActivityLog> get activities => List.unmodifiable(_activities);
  List<LocalGroup> get localGroups => List.unmodifiable(_localGroups);
  List<BodyMetric> get bodyMetrics => List.unmodifiable(_bodyMetrics);

  // -- Loading --

  Future<void> load() async {
    _selectedPath = await _db.getSetting('selected_path');
    _userName = await _db.getSetting('user_name') ?? '';
    _isPro = (await _db.getSetting('pro_active')) == '1';
    _communityOptIn = (await _db.getSetting('community_opt_in')) == '1';
    _reminderMinutes =
        _parseReminders(await _db.getSetting('reminder_minutes'));
    _todayCheckIn = _parseCheckIn(
      await _db.getSetting('checkin_${_settingDayKey(DateTime.now())}'),
    );
    _profile = await _db.getUserProfile();
    _bodyMetrics = await _db.getBodyMetrics();
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

  /// Irreversibly wipe every trace of the user from this device — the SQLite
  /// store plus all in-memory state and scheduled reminders. Used by the
  /// account-deletion flow (paired with server-side deletion). After this the
  /// app is back to a brand-new, unonboarded state.
  Future<void> deleteAllLocalData() async {
    await _db.wipeAll();
    await _notif.syncDailyReminders(const []); // cancel all scheduled reminders

    _habits = [];
    _activities = [];
    _localGroups = [];
    _bodyMetrics = [];
    _completions.clear();
    _completionDetails.clear();
    _selectedPath = null;
    _profile = null;
    _userName = '';
    _isPro = false;
    _communityOptIn = false;
    _reminderMinutes = [];
    _todayCheckIn = {};

    notifyListeners();
  }

  Future<void> saveProfile(UserProfile profile) async {
    final saved = profile.copyWith(id: 1, updatedAt: DateTime.now());
    await _db.saveUserProfile(saved);
    _profile = saved;
    if (_bodyMetrics.isEmpty ||
        (_bodyMetrics.first.weightKg - saved.weightKg).abs() >= 0.1) {
      final metric = BodyMetric(
        weightKg: saved.weightKg,
        recordedAt: DateTime.now(),
        note: 'Profile update',
      );
      final id = await _db.insertBodyMetric(metric);
      _bodyMetrics.insert(
        0,
        BodyMetric(
          id: id,
          weightKg: metric.weightKg,
          recordedAt: metric.recordedAt,
          note: metric.note,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> addBodyMetric(BodyMetric metric) async {
    final id = await _db.insertBodyMetric(metric);
    _bodyMetrics.insert(
      0,
      BodyMetric(
        id: id,
        weightKg: metric.weightKg,
        waistCm: metric.waistCm,
        note: metric.note,
        recordedAt: metric.recordedAt,
      ),
    );
    if (_profile != null) {
      _profile = _profile!.copyWith(
        weightKg: metric.weightKg,
        updatedAt: DateTime.now(),
      );
      await _db.saveUserProfile(_profile!);
    }
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

  int get estimatedCaloriesThisWeek {
    return activitiesThisWeek.fold<int>(
      0,
      (total, activity) => total + _estimateCalories(activity),
    );
  }

  int get starPoints {
    final movementPoints = activeMinutesThisWeek ~/ 10;
    final sessionPoints = activitySessionsThisWeek * 5;
    final loopPoints = completedTodayCount * 3;
    final profilePoints = hasProfile ? 20 : 0;
    return movementPoints + sessionPoints + loopPoints + profilePoints;
  }

  int get missedPlannedSessionsThisWeek {
    final target = _weeklySessionTarget;
    final completed = activitySessionsThisWeek;
    return completed >= target ? 0 : target - completed;
  }

  List<String> get weeklyExercisePlan {
    final path = (_selectedPath ?? '').toLowerCase();
    final goal = (_profile?.fitnessGoal ?? '').toLowerCase();
    if (path.contains('gym') || goal.contains('strength')) {
      return const [
        'Day 1: Full body strength - squat, push, row, core',
        'Day 2: Zone 2 cardio or brisk walk',
        'Day 3: Upper body - press, pull, shoulder stability',
        'Day 4: Lower body - hinge, lunge, calf, mobility',
      ];
    }
    if (path.contains('run') || path.contains('walk') || goal.contains('run')) {
      // A balanced, progressive running week: easy aerobic base, one quality
      // (speed) session, a long run, and recovery — the classic structure,
      // with conversational-pace guidance to keep beginners safe.
      return const [
        'Day 1: Easy run/walk 25-40 min · conversational pace',
        'Day 2: Intervals 6×1 min hard / 2 min easy · warm up first',
        'Day 3: Recovery walk + mobility · very easy effort',
        'Day 4: Long run/walk 40-60 min · steady, hydrate well',
      ];
    }
    if (path.contains('office') || path.contains('remote')) {
      return const [
        'Day 1: 25-minute walk plus posture reset',
        'Day 2: Mobility and core basics',
        'Day 3: Brisk walk or light jog',
        'Day 4: Bodyweight strength circuit',
      ];
    }
    return const [
      'Day 1: Easy walk',
      'Day 2: Strength basics',
      'Day 3: Mobility and recovery',
      'Day 4: Social activity or sport',
    ];
  }

  List<String> get exerciseLibrary {
    return const [
      'Squat',
      'Lunge',
      'Hip hinge',
      'Push-up',
      'Chest press',
      'Shoulder press',
      'Lat pulldown',
      'Seated row',
      'Plank',
      'Dead bug',
      'Treadmill walk',
      'Cycling',
      'Mobility flow',
      'Badminton drills',
    ];
  }

  int _estimateCalories(ActivityLog activity) {
    return ActivityEnergy.caloriesBurned(
      type: activity.type,
      intensity: activity.intensity,
      minutes: activity.durationMinutes,
      weightKg: _profile?.weightKg ?? 75,
    );
  }

  int get _weeklySessionTarget {
    final level = _profile?.activityLevel.toLowerCase() ?? '';
    if (level.contains('active')) return 5;
    if (level.contains('new')) return 3;
    return 4;
  }

  // -- AI-recommended minutes per activity (the coach default) --

  /// Base session length (minutes) the coach suggests for each activity,
  /// scaled by the user's activity level. The user can always override.
  int recommendedMinutesFor(String activityType) {
    const base = {
      'walking': 30,
      'running': 30,
      'gym': 45,
      'badminton': 45,
      'tennis': 60,
      'pickleball': 45,
      'padel': 60,
      'squash': 40,
      'football': 60,
      '5-a-side football': 60,
      'stretching': 15,
      'cycling': 40,
    };
    final key = activityType.toLowerCase();
    var minutes = base[key] ?? 30;

    final level = _profile?.activityLevel.toLowerCase() ?? '';
    final factor = level.contains('active')
        ? 1.2
        : (level.contains('getting') || level.contains('new'))
            ? 0.8
            : 1.0;
    // Office / remote personas benefit from a touch more daily walking.
    final path = (_selectedPath ?? '').toLowerCase();
    if (key == 'walking' &&
        (path.contains('office') || path.contains('remote'))) {
      minutes += 10;
    }
    return ((minutes * factor) / 5).round() * 5; // nearest 5 min
  }

  // -- Scientific energy targets (Mifflin–St Jeor BMR → TDEE) --

  bool get hasEnergyTargets => _profile?.isComplete ?? false;

  /// Basal Metabolic Rate (kcal/day). Null until the profile is complete.
  int? get bmr {
    final p = _profile;
    if (p == null || !p.isComplete) return null;
    final base = 10 * p.weightKg + 6.25 * p.heightCm - 5 * p.age;
    final sexOffset = switch (p.sex.toLowerCase()) {
      'male' => 5.0,
      'female' => -161.0,
      _ => -78.0, // average when unspecified
    };
    return (base + sexOffset).round();
  }

  double get _activityFactor {
    final level = _profile?.activityLevel.toLowerCase() ?? '';
    if (level.contains('active')) return 1.725;
    if (level.contains('some')) return 1.55;
    return 1.375; // getting started / light
  }

  /// Total Daily Energy Expenditure (kcal/day) — maintenance calories.
  int? get tdee {
    final b = bmr;
    if (b == null) return null;
    return (b * _activityFactor).round();
  }

  /// Recommended daily calorie INTAKE, adjusted for the user's goal.
  int? get dailyIntakeTarget {
    final t = tdee;
    if (t == null) return null;
    final goal = _profile?.fitnessGoal.toLowerCase() ?? '';
    if (goal.contains('lose')) return t - 500; // ~0.45 kg/week deficit
    if (goal.contains('strength') || goal.contains('gain')) return t + 250;
    return t;
  }

  /// Recommended calories to BURN through activity per day, derived from the
  /// weekly active-minutes target at a moderate effort.
  int? get dailyBurnTarget {
    final p = _profile;
    if (p == null || !p.isComplete) return null;
    final dailyMinutes = weeklyMinutesTarget / 7.0;
    const moderateMet = 5.5;
    final kcalPerMin = moderateMet * 3.5 * p.weightKg / 200.0;
    return (kcalPerMin * dailyMinutes).round();
  }

  int? get weeklyBurnTarget {
    final d = dailyBurnTarget;
    return d == null ? null : d * 7;
  }

  // -- Star points breakdown (how it was earned) --

  List<({String label, int points})> get starPointsBreakdown => [
        (
          label: 'Active minutes ($activeMinutesThisWeek min)',
          points: activeMinutesThisWeek ~/ 10
        ),
        (
          label: 'Sessions logged ($activitySessionsThisWeek)',
          points: activitySessionsThisWeek * 5
        ),
        (
          label: 'Loops protected today ($completedTodayCount)',
          points: completedTodayCount * 3
        ),
        (label: 'Profile complete', points: hasProfile ? 20 : 0),
      ];

  // -- Daily active streak (forgiving: any health-positive action) --

  /// Day-keys on which the user did *something* healthy — closed a loop or
  /// logged any activity (incl. a recovery action). Powers the daily streak.
  Set<DateTime> get _activeDays {
    final days = <DateTime>{};
    for (final set in _completions.values) {
      days.addAll(set);
    }
    for (final a in _activities) {
      days.add(a.dayKey);
    }
    return days;
  }

  int get dailyActiveStreak => StreakEngine.checkoffStreak(
        completedDays: _activeDays,
        today: DateTime.now(),
      );

  bool get isActiveToday => _activeDays.contains(_dayKey(DateTime.now()));

  /// Streak protection: a small recovery action keeps the chain alive on a
  /// day the user otherwise did nothing.
  Future<void> logRecoveryAction() async {
    await addActivity(ActivityLog(
      type: 'Recovery',
      durationMinutes: 10,
      intensity: 'Easy',
      notes: 'Streak protection — light recovery',
      completedAt: DateTime.now(),
    ));
  }

  // -- Badges / achievements --

  List<BadgeStatus> get badgeStatuses => Badges.evaluate(_badgeStats);
  int get earnedBadgeCount => Badges.earnedCount(_badgeStats);

  BadgeStats get _badgeStats => BadgeStats(
        totalActivities: _activities.length,
        sessionsThisWeek: activitySessionsThisWeek,
        dailyStreak: dailyActiveStreak,
        starPoints: starPoints,
        loggedGym: _activities.any((a) => a.type.toLowerCase().contains('gym')),
        dayClosed: _habits.isNotEmpty && completedTodayCount >= _habits.length,
        inCommunity: _communityOptIn,
      );

  // -- Community opt-in (local pref until accounts land) --

  bool _communityOptIn = false;
  bool get communityOptIn => _communityOptIn;

  Future<void> setCommunityOptIn(bool value) async {
    _communityOptIn = value;
    await _db.setSetting('community_opt_in', value ? '1' : '0');
    notifyListeners();
  }

  // -- Reminders (user-set daily prompts) --

  List<int> _reminderMinutes = []; // minutes since midnight, sorted
  List<int> get reminderMinutes => List.unmodifiable(_reminderMinutes);

  Future<void> addReminder(int hour, int minute) async {
    final mins = hour * 60 + minute;
    if (_reminderMinutes.contains(mins)) return;
    _reminderMinutes = [..._reminderMinutes, mins]..sort();
    await _persistReminders();
    notifyListeners();
  }

  Future<void> removeReminder(int minutesSinceMidnight) async {
    _reminderMinutes =
        _reminderMinutes.where((m) => m != minutesSinceMidnight).toList();
    await _persistReminders();
    notifyListeners();
  }

  Future<void> _persistReminders() async {
    await _db.setSetting('reminder_minutes', _reminderMinutes.join(','));
    await _notif.syncDailyReminders(_reminderMinutes);
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

  Future<void> setUserName(String name) async {
    _userName = name.trim();
    await _db.setSetting('user_name', _userName);
    notifyListeners();
  }

  Future<void> setPro(bool active) async {
    _isPro = active;
    await _db.setSetting('pro_active', active ? '1' : '0');
    notifyListeners();
  }

  // -- Daily check-in (persisted per day; powers the coach) --

  String _settingDayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<int> _parseReminders(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    return raw
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList()
      ..sort();
  }

  Map<String, String> _parseCheckIn(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    final parts = raw.split('|');
    if (parts.length != 4) return {};
    return {
      'energy': parts[0],
      'soreness': parts[1],
      'time': parts[2],
      'mood': parts[3],
    };
  }

  Future<void> saveCheckIn({
    required String energy,
    required String soreness,
    required String time,
    required String mood,
  }) async {
    _todayCheckIn = {
      'energy': energy,
      'soreness': soreness,
      'time': time,
      'mood': mood,
    };
    await _db.setSetting(
      'checkin_${_settingDayKey(DateTime.now())}',
      '$energy|$soreness|$time|$mood',
    );
    notifyListeners();
  }

  /// Weekly active-minutes target, used by the Momentum Ring.
  /// Defaults to the WHO/NHS guideline of 150 moderate minutes.
  int get weeklyMinutesTarget {
    final level = _profile?.activityLevel.toLowerCase() ?? '';
    if (level.contains('active')) return 200;
    if (level.contains('new')) return 90;
    return 150;
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

  // -- Streaks (pure logic lives in StreakEngine; unit-tested) --

  int currentStreak(int habitId) {
    Habit? habit;
    for (final h in _habits) {
      if (h.id == habitId) {
        habit = h;
        break;
      }
    }
    // Habit may have just been deleted while a frame is still building.
    if (habit == null) return 0;

    return StreakEngine.currentStreak(
      habit: habit,
      completedDays: completionsFor(habitId),
      details: _completionDetails[habitId] ?? {},
    );
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
