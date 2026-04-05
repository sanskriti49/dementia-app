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
        data.isMagicEyeEnabled != oldWidget.data.isMagicEyeEnabled ||
        data.userName != oldWidget.data.userName;
  }
}

class SettingsProvider extends StatefulWidget {
  const SettingsProvider({required this.child, super.key});
  final Widget child;

  static SettingsProviderState of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<_SettingsInherited>();
    if (result == null) {
      throw FlutterError('SettingsProvider not found in widget tree.');
    }
    return result.data;
  }

  @override
  State<SettingsProvider> createState() => SettingsProviderState();
}

class SettingsProviderState extends State<SettingsProvider> {
  double _fontSizeMultiplier = 1.0;
  bool _isMagicEyeEnabled = false;
  String _userName = "User";

  String get userName => _userName;
  double get fontSizeMultiplier => _fontSizeMultiplier;
  bool get isMagicEyeEnabled => _isMagicEyeEnabled;

  double s(num size) => (size * _fontSizeMultiplier).toDouble();

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        double savedSize = prefs.getDouble('font_size') ?? 1.0;
        _fontSizeMultiplier = savedSize.clamp(0.8, 1.5);
        _isMagicEyeEnabled = prefs.getBool('magic_eye_enabled') ?? false;

        _userName = prefs.getString('user_name') ?? "User";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void updateUserName(String newName) async {
    setState(() => _userName = newName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newName);
  }

  void updateFontSize(double newMultiplier) async {
    double safeValue = newMultiplier.clamp(0.8, 1.5);
    setState(() => _fontSizeMultiplier = safeValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', safeValue);
  }

  void toggleMagicEye(bool enabled) async {
    setState(() => _isMagicEyeEnabled = enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('magic_eye_enabled', enabled);

    if (enabled) {
      await Workmanager().registerPeriodicTask(
        "1", "checkInactivityTask",
        frequency: const Duration(hours: 4),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
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