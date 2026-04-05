import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'database_helper.dart';
import 'utils/permissions_helper.dart';
import 'home.dart';
import 'settings_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';
import 'visual_aide_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      return Future.value(false);
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper().database;
  await dotenv.load(fileName: ".env");

  await NotificationService.init();
  await NotificationService.requestPermissions();

  await requestBatteryOptimization();


  NotificationService.onNotificationClick = (payload) {
    if (payload == 'magic_eye_screen') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => const VisualAideScreen()),
      );
    }
  };

  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  runApp(
    SettingsProvider(
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Memoir',
      theme: ThemeData(
        fontFamily: 'Lexend',
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}