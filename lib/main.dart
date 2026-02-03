import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'home.dart';
import 'settings_provider.dart';

Future<void> main() async {
  // loads the API key from your .env file
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsProvider(
      child: MaterialApp(
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