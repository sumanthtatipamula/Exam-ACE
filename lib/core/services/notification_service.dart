import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// --- Settings provider ---

class NotificationSettings {
  final bool enabled;
  final bool morningEnabled;
  final bool eveningEnabled;
  final TimeOfDay morningTime;
  final TimeOfDay eveningTime;

  const NotificationSettings({
    this.enabled = true,
    this.morningEnabled = true,
    this.eveningEnabled = true,
    this.morningTime = const TimeOfDay(hour: 7, minute: 0),
    this.eveningTime = const TimeOfDay(hour: 20, minute: 0),
  });

  NotificationSettings copyWith({
    bool? enabled,
    bool? morningEnabled,
    bool? eveningEnabled,
    TimeOfDay? morningTime,
    TimeOfDay? eveningTime,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      morningEnabled: morningEnabled ?? this.morningEnabled,
      eveningEnabled: eveningEnabled ?? this.eveningEnabled,
      morningTime: morningTime ?? this.morningTime,
      eveningTime: eveningTime ?? this.eveningTime,
    );
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
        (ref) {
  return NotificationSettingsNotifier();
});

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings());

  void setEnabled(bool v) => state = state.copyWith(enabled: v);
  void setMorningEnabled(bool v) => state = state.copyWith(morningEnabled: v);
  void setEveningEnabled(bool v) => state = state.copyWith(eveningEnabled: v);
  void setMorningTime(TimeOfDay t) => state = state.copyWith(morningTime: t);
  void setEveningTime(TimeOfDay t) => state = state.copyWith(eveningTime: t);
}

// --- Service ---

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _morningId = 1001;
  static const _eveningId = 1002;

  static Future<void> init() async {
    tz.initializeTimeZones();
    // Schedules use [TZDateTime] in UTC built from Dart local [DateTime] — no flutter_timezone
    // plugin required; wall-clock times follow the device timezone.

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> scheduleDailyReminders({
    required int taskCount,
    required int incompleteCount,
    required NotificationSettings settings,
  }) async {
    await _plugin.cancel(_morningId);
    await _plugin.cancel(_eveningId);

    if (!settings.enabled || taskCount <= 0) return;

    final now = DateTime.now();

    if (settings.morningEnabled) {
      final morning = DateTime(
        now.year,
        now.month,
        now.day,
        settings.morningTime.hour,
        settings.morningTime.minute,
      );

      if (morning.isAfter(now)) {
        final scheduled =
            tz.TZDateTime.from(morning.toUtc(), tz.UTC);
        await _plugin.zonedSchedule(
          _morningId,
          'Good Morning!',
          'You have $taskCount task${taskCount == 1 ? '' : 's'} today.',
          scheduled,
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }

    if (settings.eveningEnabled && incompleteCount > 0) {
      final evening = DateTime(
        now.year,
        now.month,
        now.day,
        settings.eveningTime.hour,
        settings.eveningTime.minute,
      );

      if (evening.isAfter(now)) {
        final scheduled =
            tz.TZDateTime.from(evening.toUtc(), tz.UTC);
        await _plugin.zonedSchedule(
          _eveningId,
          'Daily Review',
          '$incompleteCount task${incompleteCount == 1 ? '' : 's'} still incomplete.',
          scheduled,
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static const _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_tasks',
      'Daily Tasks',
      channelDescription: 'Reminders about your daily tasks',
      importance: Importance.high,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );
}
