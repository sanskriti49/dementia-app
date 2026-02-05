import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'home.dart';
import 'settings_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';
import 'visual_aide_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('last_interaction_time')) {
    await prefs.setInt('last_interaction_time', DateTime.now().millisecondsSinceEpoch);
  }

  await NotificationService.init();

  await NotificationService.requestPermissions();

  NotificationService.onNotificationClick = (payload) {
    if (payload == 'magic_eye_screen') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => const VisualAideScreen()),
      );
    }
  };

  await dotenv.load(fileName: ".env");

  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  Workmanager().registerPeriodicTask(
    "1",
    "checkInactivityTask",
    frequency: const Duration(hours: 1),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsProvider(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Memoir',
        theme: ThemeData(
          fontFamily: 'Inter',
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFE7F0ED),
        ),
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}