// import 'package:flutter/foundation.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;
//
// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
//
//   // static Future<void> init() async {
//   //   tz.initializeTimeZones();
//   //
//   //   const AndroidInitializationSettings androidSettings =
//   //   AndroidInitializationSettings('@mipmap/ic_launcher');
//   //
//   //   const InitializationSettings settings = InitializationSettings(
//   //     android: androidSettings,
//   //   );
//   //
//   //   // FIX: You MUST add 'initializationSettings:' before 'settings'
//   //   await _notificationsPlugin.initialize(
//   //     initializationSettings: settings, // This label is mandatory in v20
//   //     onDidReceiveNotificationResponse: (NotificationResponse details) {
//   //       debugPrint("Notification tapped: ${details.payload}");
//   //     },
//   //   );
//   // }
//
//   static Future<void> init() async {
//     tz.initializeTimeZones();
//
//     const AndroidInitializationSettings androidSettings =
//     AndroidInitializationSettings('@mipmap/ic_launcher');
//
//     const InitializationSettings settings = InitializationSettings(
//       android: androidSettings,
//     );
//
//     // FIX: Removed the 'initializationSettings:' label.
//     // Just pass 'settings' directly as the first argument.
//     await _notificationsPlugin.initialize(
//       settings,
//       onDidReceiveNotificationResponse: (NotificationResponse details) {
//         debugPrint("Notification tapped: ${details.payload}");
//       },
//     );
//   }
//   static Future<void> scheduleNotification(int id, String title, String body, DateTime scheduledTime) async {
//     await _notificationsPlugin.zonedSchedule(
//       id: id,
//       title: title,
//       body: body,
//       scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
//       notificationDetails: const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'reminders_channel',
//           'Reminders',
//           importance: Importance.max,
//           priority: Priority.high,
//         ),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//     );
//   }
//
//   static Future<void> scheduleInactivityNudge(int id, String language) async {
//     String title = language == "Hindi" ? "नमस्ते संस्कृति!" : "Hi Sanskriti!";
//     String body = language == "Hindi"
//         ? "क्या आप कुछ देखना चाहती हैं? मैं आपकी मदद के लिए यहाँ हूँ।"
//         : "Would you like to see something? I am here to help.";
//
//     final scheduledTime = DateTime.now().add(const Duration(hours: 4));
//
//     await _notificationsPlugin.zonedSchedule(
//       id: id,
//       title: title,
//       body: body,
//       scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
//       notificationDetails: const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'nudge_channel',
//           'Gentle Nudges',
//           importance: Importance.low,
//           priority: Priority.low,
//         ),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//     );
//   }
//
//   static Future<void> cancelNudge(int id) async {
//     await _notificationsPlugin.cancel(id: id);
//   }
// }