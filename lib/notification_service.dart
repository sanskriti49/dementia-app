import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Function(String?)? onNotificationClick;

  static Future<void> init() async {
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
  static Future<void> requestPermissions() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  static Future<void> showNotification() async {
    // const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    //   'magic_eye_channel',
    //   'Magic Eye Reminders',
    //   channelDescription: 'Reminds user to use visual aid',
    //   importance: Importance.max,
    //  // priority: Priority.high,
    // );
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'magic_eye_channel',
      'Magic Eye Reminders',
      description: 'Reminds user to use visual aid',
      importance: Importance.max,
    );

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'magic_eye_channel',
      'Magic Eye Reminders',
      channelDescription: 'Reminds user to use visual aid',
      importance: Importance.max,
      priority: Priority.high,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id:0,
      notificationDetails: platformDetails,
      title:'Need help identifying something? 😊',
      body:'Tap here to use your Magic Eye assistant.',
      payload: 'magic_eye_screen',
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    try{
      final prefs = await SharedPreferences.getInstance();
      int lastInteraction = prefs.getInt('last_interaction_time') ?? DateTime.now().millisecondsSinceEpoch;
      int thresholdHours = prefs.getInt('inactive_threshold') ?? 4;


      if (lastInteraction != null) {
        DateTime lastTime = DateTime.fromMillisecondsSinceEpoch(lastInteraction);
        Duration difference = DateTime.now().difference(lastTime);

        print("System Debug: Last used ${difference.inMinutes} minutes ago");

        //  show notification if inactive for more than X hours
        if (difference.inHours >= 4) {
          await NotificationService.init();
          await NotificationService.showNotification();
        }
      }
      return Future.value(true);
    } catch (e) {
      debugPrint("Workmanager Error: $e");
      return Future.value(false);
    }
  });
}