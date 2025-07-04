// 📁 lib/services/notification_service.dart
// This file is already well-implemented for local notifications
// and does not require changes for Supabase integration.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize timezone data for scheduling accurate notifications.
    tz.initializeTimeZones();

    // Configure Android specific initialization settings.
    // '@mipmap/ic_launcher' refers to the app icon in Android resources.
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Combine platform-specific settings into a general InitializationSettings object.
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    // Initialize the FlutterLocalNotificationsPlugin with the defined settings.
    await _notificationsPlugin.initialize(initSettings);
  }

  /// Schedules a daily recurring notification.
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String message,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      0, // Unique ID for this notification
      'Diary Reminder 📝', // Title of the notification
      message, // Body of the notification
      _nextInstanceOfTime(hour, minute), // Calculate the next scheduled time
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel_id', // Unique channel ID for Android
          'Daily Reminders', // Channel name for Android settings
          channelDescription: 'Reminds user to write their diary daily', // Channel description
          importance: Importance.max, // High importance for prominent display
          priority: Priority.high, // High priority for Android
        ),
      ),
      androidAllowWhileIdle: true, // Allow notification to fire even if device is in low-power idle mode
      matchDateTimeComponents: DateTimeComponents.time, // Match only time for daily recurrence
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime, // Interpret time as absolute
    );
  }

  /// Calculates the next instance of a given hour and minute in the local timezone.
  /// If the scheduled time is in the past for today, it schedules it for tomorrow.
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local); // Get current time in local timezone
    var scheduledTime =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute); // Create scheduled time for today

    // If the scheduled time is before the current time, add one day to schedule for tomorrow.
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    return scheduledTime;
  }
}
