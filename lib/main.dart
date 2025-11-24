// import 'package:flutter/material.dart';
// import 'home.dart';
// import 'settings_provider.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return SettingsProvider(
//         child: MaterialApp(
//         title: 'Memoir',
//         theme: ThemeData(
//           fontFamily: 'Inter',
//           useMaterial3: true,
//           scaffoldBackgroundColor: const Color(0xFFE7F0ED),
//           //scaffoldBackgroundColor: Color(0xFFA6C6B7),
//         ),
//         home: const HomePage(),
//         debugShowCheckedModeBanner: false,
//         ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 1. ADD THIS IMPORT
import 'home.dart';
import 'settings_provider.dart';

// 2. MODIFY THIS FUNCTION
Future<void> main() async {
  // This line loads the API key from your .env file
  await dotenv.load(fileName: ".env");

  // This line runs your app as before
  runApp(const MyApp());
}

// 3. YOUR MyApp WIDGET REMAINS UNCHANGED
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