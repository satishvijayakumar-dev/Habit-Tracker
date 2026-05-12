import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit.dart';

/// Wraps flutter_local_notifications with sensible defaults for iOS + Android.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      // We request permissions explicitly via requestPermissions() so we can
      // surface the result to the user. Avoid double-prompting on init.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _initialized = true;
  }

  /// Requests notification permission. Returns true if granted.
  /// On iOS this triggers the system prompt the first time it's called.
  /// On Android 13+ it triggers the runtime POST_NOTIFICATIONS prompt.
  Future<bool> requestPermissions() async {
    await init();

    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }

    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }

    return true;
  }

  /// Schedules (or replaces) a daily reminder for the given habit at its
  /// reminder time. No-ops if the habit has no reminder.
  Future<void> scheduleForHabit(Habit habit) async {
    if (habit.id == null || !habit.hasReminder) return;
    await init();

    // Cancel any existing notification for this habit first.
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
          channelDescription: 'Daily reminders for your habits',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
    );
  }

  Future<void> cancelForHabit(int habitId) async {
    await init();
    await _plugin.cancel(habitId);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// Returns the next occurrence of [hour]:[minute] in the local timezone.
  /// If that time has already passed today, returns tomorrow's occurrence.
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
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
