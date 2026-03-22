import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exam_ace/core/services/notification_service.dart';
import 'package:exam_ace/features/home/providers/tasks_provider.dart';

/// Reschedules daily reminders from current [notificationSettingsProvider] and
/// [todayCombinedTasksProvider]. Call after Home loads or when notification settings change.
Future<void> syncNotificationSchedule(WidgetRef ref) async {
  final settings = ref.read(notificationSettingsProvider);
  final todayCombined = ref.read(todayCombinedTasksProvider);
  await NotificationService.scheduleDailyReminders(
    taskCount: todayCombined.length,
    incompleteCount: todayCombined.where((t) => !t.isComplete).length,
    settings: settings,
  );
}
