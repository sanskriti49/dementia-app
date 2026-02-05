import 'package:flutter/material.dart';
import 'settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsProvider.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle("Accessibility"),
          _buildSettingsCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.format_size, color: Color(0xFF2D6A4F)),
                  title: const Text("Text Size"),
                  subtitle: Text("${(settings.fontSizeMultiplier * 100).toInt()}%"),
                ),
                Slider(
                  value: settings.fontSizeMultiplier,
                  min: 0.8,
                  max: 1.5,
                  activeColor: const Color(0xFF2D6A4F),
                  onChanged: (val) => settings.updateFontSize(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          _buildSectionTitle("Reminders"),
          _buildSettingsCard(
            child: SwitchListTile(
              secondary: const Icon(Icons.remove_red_eye, color: Color(0xFF2D6A4F)),
              title: const Text("Magic Eye Reminder"),
              subtitle: const Text("Receive a nudge to identify objects every 4 hours"),
              value: settings.isMagicEyeEnabled,
              activeColor: const Color(0xFF2D6A4F),
              onChanged: (val) => settings.toggleMagicEye(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(title.toUpperCase(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(8), child: child),
    );
  }
}