import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService.init failed: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      await init();
      if (Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final granted = await androidPlugin.requestNotificationsPermission();
          return granted ?? false;
        }
        return true;
      }
      if (Platform.isIOS) {
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final result = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return result ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('NotificationService.requestPermissions failed: $e');
      return false;
    }
  }

  Future<void> scheduleForHabit(Habit habit) async {
    if (habit.id == null || !habit.hasReminder) return;
    try {
      await init();
      if (!_initialized) return;
      await cancelForHabit(habit.id!);
      final scheduled = _nextInstanceOfTime(
        habit.reminderHour!,
        habit.reminderMinute!,
      );
      await _plugin.zonedSchedule(
        habit.id!,
        'Habit Reminder',
        'Time to: ${habit.name}',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminders',
            'Habit Reminders',
            channelDescription: 'Daily reminders for your ActivHealth loops',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('NotificationService.scheduleForHabit failed: $e');
    }
  }

  Future<void> cancelForHabit(int habitId) async {
    try {
      await init();
      await _plugin.cancel(habitId);
    } catch (e) {
      debugPrint('NotificationService.cancelForHabit failed: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await init();
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService.cancelAll failed: $e');
    }
  }

  /// Notification id range reserved for user-set daily reminders, so they
  /// never collide with per-habit reminders (which use the habit's id).
  static const int _reminderIdBase = 900000;

  /// Replaces all scheduled daily reminders with [minutesSinceMidnight].
  Future<void> syncDailyReminders(List<int> minutesSinceMidnight) async {
    try {
      await init();
      if (!_initialized) return;
      // Clear the reserved range, then reschedule.
      for (var i = 0; i < 24; i++) {
        await _plugin.cancel(_reminderIdBase + i);
      }
      if (await requestPermissions() == false) return;

      for (var i = 0; i < minutesSinceMidnight.length && i < 24; i++) {
        final mins = minutesSinceMidnight[i];
        final scheduled = _nextInstanceOfTime(mins ~/ 60, mins % 60);
        await _plugin.zonedSchedule(
          _reminderIdBase + i,
          'ActivHealth',
          'Time to move — your coach has today\'s focus ready.',
          scheduled,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'activhealth_reminders',
              'Daily Reminders',
              channelDescription: 'Daily reminders you set in ActivHealth',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    } catch (e) {
      debugPrint('NotificationService.syncDailyReminders failed: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (rollsToTomorrow(now, hour, minute)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Whether a reminder at [hour]:[minute] should fire tomorrow rather
  /// than today, given [now] — i.e. the time has already passed (or is
  /// exactly now). Pure and time-zone agnostic so it can be unit-tested.
  static bool rollsToTomorrow(DateTime now, int hour, int minute) {
    final todayAtTime = DateTime(now.year, now.month, now.day, hour, minute);
    return !todayAtTime.isAfter(now);
  }
}
