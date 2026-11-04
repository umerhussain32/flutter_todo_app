import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Reminder notifications.
///
/// Everything here is best-effort and fully guarded: it initialises lazily
/// (never before the first frame), and any failure simply disables
/// reminders instead of affecting the rest of the app.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        // Fall back to UTC if the device timezone can't be read.
      }
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
      );
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('Notifications disabled: $e');
    }
  }

  Future<void> schedule({
    required int id,
    required String title,
    required DateTime when,
  }) async {
    if (!_ready || when.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: 'Reminder',
        body: title,
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'todo_reminders',
            'Todo reminders',
            channelDescription: 'Reminders for your todos',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Could not schedule reminder: $e');
    }
  }

  Future<void> cancel(int id) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }
}
