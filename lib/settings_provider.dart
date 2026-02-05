import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SettingsInherited extends InheritedWidget {
  const _SettingsInherited({
    required this.data,
    required super.child,
  });

  final SettingsProviderState data;

  @override
  bool updateShouldNotify(_SettingsInherited oldWidget) {
    return data.fontSizeMultiplier != oldWidget.data.fontSizeMultiplier ||
        data.isMagicEyeEnabled != oldWidget.data.isMagicEyeEnabled;
  }
}

class SettingsProvider extends StatefulWidget {
  const SettingsProvider({required this.child, super.key});
  final Widget child;

  static SettingsProviderState of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<_SettingsInherited>();
    assert(result != null, 'No SettingsProvider found in context');
    return result!.data;
  }

  @override
  State<SettingsProvider> createState() => SettingsProviderState();
}

class SettingsProviderState extends State<SettingsProvider> {
  double _fontSizeMultiplier = 1.0;
  bool _isMagicEyeEnabled = false;

  double get fontSizeMultiplier => _fontSizeMultiplier;
  bool get isMagicEyeEnabled => _isMagicEyeEnabled;

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Initialize data from disk on startup
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSizeMultiplier = prefs.getDouble('font_size') ?? 1.0;
      _isMagicEyeEnabled = prefs.getBool('magic_eye_enabled') ?? false;
    });
  }

  void updateFontSize(double newMultiplier) async {
    setState(() => _fontSizeMultiplier = newMultiplier);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', newMultiplier); // Save it so it persists!
  }

  void toggleMagicEye(bool enabled) async {
    setState(() => _isMagicEyeEnabled = enabled);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('magic_eye_enabled', enabled);

    if (enabled) {
      await Workmanager().registerPeriodicTask(
        "1",
        "checkInactivityTask",
        frequency: const Duration(hours: 4),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
        ),
      );
    } else {
      await Workmanager().cancelByUniqueName("1");
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsInherited(data: this, child: widget.child);
  }
}