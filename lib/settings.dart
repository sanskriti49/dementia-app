import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/permissions_helper.dart';
import 'emergency_contacts_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double? _dragValue; //slider vlaue
  Future<void> _handleBatteryPermission() async {
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Fix Reminder Issues"),
          content: const Text(
              "To make reminders work on time, please allow battery optimization to be disabled for this app."
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await requestBatteryOptimization();
                setState(() {});
              },
              child: const Text("Open Settings"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Already allowed ✅")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsProvider.of(context);

    final double displayValue = (_dragValue ?? settings.fontSizeMultiplier).clamp(0.8, 1.5);

    const Color bgBlue = Color(0xFFF0F7FF);
    const Color accentBlue = Color(0xFF4A90E2);
    const Color textNavy = Color(0xFF1A2130);

    return Scaffold(
      backgroundColor: bgBlue,
      appBar: AppBar(
        title: Text(
          "App Settings",
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w700,
            color: textNavy,
            fontSize: settings.s(22.0),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: accentBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildSectionTitle("Personal Profile", settings),
          _buildSettingsCard(
            accentColor: accentBlue,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              // leading: const CircleAvatar(
              //   backgroundColor: Color(0xFFD6E4FF),
              //   child: Icon(Icons.person_rounded, color: accentBlue),
              // ),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFD6E4FF),
                child: Text(
                  settings.userName.isNotEmpty ? settings.userName[0].toUpperCase() : "U",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: accentBlue),
                ),
              ),
              title: Text(
                "Your Name",
                style: GoogleFonts.lexend(
                  fontSize: settings.s(18.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(settings.userName),
              trailing: const Icon(Icons.edit_rounded, size: 20),
              onTap: () => _showNameDialog(context, settings),
            ),
          ),
          const SizedBox(height: 32.0),
          _buildSectionTitle("Visual Comfort", settings),
          _buildSettingsCard(
            accentColor: accentBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFD6E4FF),
                    child: Icon(Icons.format_size_rounded, color: accentBlue),
                  ),
                  title: Text(
                    "Make Words Bigger",
                    style: GoogleFonts.lexend(
                      fontSize: settings.s(18.0),
                      fontWeight: FontWeight.w600,
                      color: textNavy,
                    ),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 12.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 15.0),
                    activeTrackColor: accentBlue,
                    inactiveTrackColor: accentBlue.withOpacity(0.1),
                  ),
                  child: Slider(
                    value: displayValue,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    onChanged: (val) {
                      // Update local UI immediately so it slides smoothly
                      setState(() {
                        _dragValue = val;
                      });
                      settings.updateFontSize(val);
                    },
                    onChangeEnd: (val) {
                      setState(() {
                        _dragValue = null;
                      });
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("A", style: GoogleFonts.lexend(fontSize: 14.0, fontWeight: FontWeight.bold)),
                    Text("${(displayValue * 100).toInt()}%",
                        style: GoogleFonts.lexend(color: accentBlue, fontWeight: FontWeight.bold)),
                    Text("A", style: GoogleFonts.lexend(fontSize: 24.0, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32.0),
          _buildSectionTitle("Automatic Help", settings),
          _buildSettingsCard(
            accentColor: const Color(0xFF81C784),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                "Helper Eye Nudges",
                style: GoogleFonts.lexend(
                    fontSize: settings.s(18.0),
                    fontWeight: FontWeight.w600,
                    color: textNavy),
              ),
              subtitle: Text("Remind me to check objects",
                  style: GoogleFonts.lexend(fontSize: settings.s(14.0))),
              value: settings.isMagicEyeEnabled,
              activeColor: const Color(0xFF81C784),
              onChanged: (val) => settings.toggleMagicEye(val),
            ),
          ),

          const SizedBox(height: 32.0),

          _buildSectionTitle("Reminders Fix", settings),

          FutureBuilder<bool>(
            future: Permission.ignoreBatteryOptimizations.isGranted,
            builder: (context, snapshot) {
              final isGranted = snapshot.data ?? false;

              return _buildSettingsCard(
                accentColor: isGranted ? Colors.green : Colors.orange,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isGranted
                        ? Colors.green.withOpacity(0.15)
                        : const Color(0xFFFFE0B2),
                    child: Icon(
                      isGranted ? Icons.check_circle : Icons.battery_alert,
                      color: isGranted ? Colors.green : Colors.orange,
                    ),
                  ),
                  title: Text(
                    isGranted ? "Reminders Working Perfectly" : "Fix Reminder Issues",
                    style: GoogleFonts.lexend(
                      fontSize: settings.s(18.0),
                      fontWeight: FontWeight.w600,
                      color: textNavy,
                    ),
                  ),
                  subtitle: Text(
                    isGranted
                        ? "All settings are properly enabled ✅"
                        : "Allow app to run in background",
                    style: GoogleFonts.lexend(
                      fontSize: settings.s(14.0),
                    ),
                  ),
                  onTap: _handleBatteryPermission,
                ),
              );
            },
          ),

          const SizedBox(height: 32.0),
          _buildSectionTitle("Emergency Contacts", settings),

          _buildSettingsCard(
            accentColor: Colors.red,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFE5E5),
                    child: Icon(Icons.contact_phone, color: Colors.red),
                  ),
                  title: Text(
                    "Manage Emergency Contacts",
                    style: GoogleFonts.lexend(
                      fontSize: settings.s(18.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    "Add people to contact in emergencies",
                    style: GoogleFonts.lexend(fontSize: settings.s(14.0)),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EmergencyContactsPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _showNameDialog(BuildContext context, dynamic settings) {
    final controller = TextEditingController(text: settings.userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("What should I call you?"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter your name"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                settings.updateUserName(controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, dynamic settings) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Text(title.toUpperCase(),
          style: GoogleFonts.lexend(
              fontSize: settings.s(13.0),
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey,
              letterSpacing: 1.2)),
    );
  }

  Widget _buildSettingsCard({required Widget child, required Color accentColor}) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.0),
          border: Border.all(color: accentColor.withOpacity(0.2), width: 2.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10.0,
              offset: const Offset(0, 4),
            )
          ]
      ),
      child: child,
    );
  }
}