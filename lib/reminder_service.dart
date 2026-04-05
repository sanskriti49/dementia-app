import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'reminders_screen.dart';

class ReminderService {
  static const String _storageKey = 'saved_reminders';

  /// Get all reminders
  static Future<List<Reminder>> getReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);

    if (data == null) return [];

    final List<dynamic> jsonData = jsonDecode(data);
    return jsonData.map((item) => Reminder.fromJson(item)).toList();
  }

  /// Save all reminders
  static Future<void> _saveReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData =
    jsonEncode(reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, encodedData);
  }

  /// Create reminder
  static Future<void> createReminder(Reminder r) async {
    final reminders = await getReminders();
    reminders.add(r);
    await _saveReminders(reminders);
  }

  /// Get next reminder by keyword
  static Future<Reminder?> getNextReminderFor(String keyword) async {
    final reminders = await getReminders();

    try {
      return reminders.firstWhere(
            (r) => r.title.toLowerCase().contains(keyword.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateReminder(Reminder updated) async {
    final reminders = await getReminders();

    final index = reminders.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      reminders[index] = updated;
      await _saveReminders(reminders);
    }
  }

  static Future<void> deleteReminder(String id) async {
    final reminders = await getReminders();
    reminders.removeWhere((r) => r.id == id);
    await _saveReminders(reminders);
  }

  static Future<void> cleanupOldReminders() async {
    final reminders = await getReminders();
    final now = DateTime.now();

    // Keep reminders from the last 7 days only if they are 'once' and 'completed'
    reminders.removeWhere((r) =>
    r.repeat == RepeatType.once &&
        r.isCompleted &&
        r.time.isBefore(now.subtract(const Duration(days: 7)))
    );

    await _saveReminders(reminders);
  }
}