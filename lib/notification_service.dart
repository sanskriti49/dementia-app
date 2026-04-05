import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:android_intent_plus/android_intent.dart';
import 'dart:async';
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static Function(String?)? onNotificationClick;

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    String timeZoneName = timezoneInfo.identifier;
    try {
      if (timeZoneName == "Asia/Calcutta") {
        timeZoneName = "Asia/Kolkata";
      }

      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation("Asia/Kolkata"));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationClick?.call(response.payload);
      },
    );
  }
  // static Future<void> requestBatteryOptimization() async {
  //   if (await Permission.ignoreBatteryOptimizations.isDenied) {
  //     await Permission.ignoreBatteryOptimizations.request();
  //   }
  // }
  static Future<void> requestBatteryOptimization() async {
    final intent = AndroidIntent(
      action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
      data: 'package:com.example.my_app',
    );
    await intent.launch();
  }

  static Future<void> requestPermissions() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      bool? granted = await androidPlugin.canScheduleExactNotifications();

      if (granted == false) {
        await androidPlugin.requestExactAlarmsPermission();
      }
    }
  }

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String reminderId,
  }) async {
    var tzTime = tz.TZDateTime.from(scheduledDate, tz.local);

    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) {
      tzTime = tzTime.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders_channel',
          'Daily Reminders',
          channelDescription: 'Notifications for daily tasks',
          importance: Importance.max,
          priority: Priority.high,
        //  ticker: 'ticker',
          fullScreenIntent: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      payload: reminderId,
    );
  }

  static Future<void> showInstantReminder({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'missed_channel',
      'Missed Reminders',
      channelDescription: 'Notifications for missed reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );

  }
  static Future<void> cancelReminder(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  static Future<void> showNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'magic_eye_channel',
      'Magic Eye Reminders',
      channelDescription: 'Reminds user to use visual aid',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: 0,
      title: 'Need help identifying something? 😊',
      body: 'Tap here to use your Magic Eye assistant.',
      notificationDetails: platformDetails,
      payload: 'magic_eye_screen',
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final prefs = await SharedPreferences.getInstance();
      int lastInteraction = prefs.getInt('last_interaction_time') ?? DateTime.now().millisecondsSinceEpoch;

      DateTime lastTime = DateTime.fromMillisecondsSinceEpoch(lastInteraction);
      Duration difference = DateTime.now().difference(lastTime);

      if (difference.inHours >= 4) {
        await NotificationService.init();
        await NotificationService.showNotification();
      }
      return Future.value(true);
    } catch (e) {
      debugPrint("Workmanager Error: $e");
      return Future.value(false);
    }
  });
}