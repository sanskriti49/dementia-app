import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_provider.dart';
import 'settings.dart';
import 'chatbot.dart';
import 'reminders_screen.dart';
import 'visual_aide_screen.dart';
import 'family_page.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  // Use a high-level build context to handle navigation after drawer closes
  void _navigate(Widget screen) {
    Navigator.pop(context); // Close drawer first
    Future.delayed(const Duration(milliseconds: 250), () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsProvider.of(context);
    const Color accentBlue = Color(0xFF3B82F6); // Using your ChatScreen accentBlue

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          _buildHeader(settings, accentBlue),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildItem(Icons.home_rounded, 'Home', accentBlue,
                        () => Navigator.pop(context), settings, isSelected: true),
                _buildItem(Icons.calendar_today_rounded, 'My Schedule', const Color(0xFFFFB38A),
                        () => _navigate(const RemindersScreen()), settings),
                _buildItem(Icons.forum_rounded, 'Talk to Us', const Color(0xFF81C784),
                        () => _navigate(const ChatScreen()), settings),
                _buildItem(Icons.favorite_rounded, 'Loved Ones', const Color(0xFFFF8FA3),
                        () => _navigate(const FamilyPage()), settings),
                const Divider(height: 40, thickness: 1, indent: 10, endIndent: 10),
                _buildItem(Icons.settings_outlined, 'App Settings', Colors.blueGrey,
                        () => _navigate(SettingsPage()), settings),
              ],
            ),
          ),
          // Footer for Presentation appeal
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "Memoir v1.0 • Kanpur, India",
              style: GoogleFonts.atkinsonHyperlegible(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(SettingsProviderState settings, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24.0, 70.0, 24.0, 30.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 35.0,
            backgroundColor: color,
            // FIXED: If userName is 'User' or empty, show Icon. Otherwise show Initial.
            child: (settings.userName == "User" || settings.userName.isEmpty)
                ? const Icon(Icons.person_rounded, color: Colors.white, size: 40)
                : Text(
              settings.userName[0].toUpperCase(),
              style: GoogleFonts.atkinsonHyperlegible(
                  color: Colors.white,
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20.0),
          Text(
            'Hello ${settings.userName},',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: settings.s(26.0),
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          Text(
            'You have 3 tasks left today',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: settings.s(14.0),
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String title, Color color, VoidCallback onTap, dynamic settings, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color, size: 28.0),
        title: Text(
          title,
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: settings.s(18.0),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? color : const Color(0xFF0F172A),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}