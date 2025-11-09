import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io' show Platform;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // 🔔 Define notification channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'expiry_channel_id', // Channel ID
    'Expiry Reminders', // Channel name
    description: 'Reminds you before products expire',
    importance: Importance.max,
  );

  // 🧩 Call this once in main.dart
  static Future<void> init() async {
    // Initialize time zones
    tz.initializeTimeZones();

    // ⚙️ Initialization settings for Android and iOS
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(android: android, iOS: ios);

    // Initialize the plugin
    await _notifications.initialize(settings);

    // ✅ Create Android notification channel
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // ✅ Ask for Android 13+ permission
    if (Platform.isAndroid) {
      final androidInfo = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
     await androidInfo?.requestNotificationsPermission();

    }

    // ✅ Ask iOS permission
    if (Platform.isIOS) {
      final iosInfo = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosInfo?.requestPermissions(alert: true, badge: true, sound: true);
    }

    print("✅ NotificationService initialized successfully!");
  }

  // 🕒 Schedule a single notification
  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final now = DateTime.now();

    // ⚠️ If the date is in the past, schedule 5s later instead
    final scheduled = scheduledDate.isBefore(now)
        ? now.add(const Duration(seconds: 5))
        : scheduledDate;

    // 🔧 Ensure we’re using a proper timezone
    final tzTime = tz.TZDateTime.from(scheduled, tz.local);

    await _notifications.zonedSchedule(
      scheduled.hashCode, // unique ID
      title,
      body,
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    print("✅ Notification scheduled for $tzTime ($title)");
  }

  // 📅 Schedule multiple reminders automatically
  static Future<void> scheduleExpiryReminders({
    required String productName,
    required DateTime expiryDate,
  }) async {
    final reminders = <Duration>[
      const Duration(days: 30),
      const Duration(days: 14),
      const Duration(days: 7),
      const Duration(days: 3),
      const Duration(days: 1),
      Duration.zero,
    ];

    for (final duration in reminders) {
      final scheduledDate = expiryDate.subtract(duration);
      if (scheduledDate.isAfter(DateTime.now())) {
        final body = duration == Duration.zero
            ? "Your product '$productName' expires today! Use it soon."
            : "Your product '$productName' will expire in ${duration.inDays} days.";

        await scheduleNotification(
          title: "Expiry Reminder",
          body: body,
          scheduledDate: scheduledDate,
        );
      }
    }

    print("🗓 All reminders scheduled for $productName (expiry: $expiryDate)");
  }
}
