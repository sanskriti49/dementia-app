import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'settings_provider.dart';
import 'notification_service.dart';
import 'reminder_service.dart';
import 'voice_service.dart';

enum RepeatType { once, daily, weekly }
enum Priority { low, medium, high }

class Reminder {
  final Priority priority;
  final String id;
  final String title;
  DateTime time;
  final String category;
  final RepeatType repeat;
  final List<int>? daysOfWeek;
  bool isCompleted;

  Reminder({
    this.priority = Priority.medium,
    required this.id,
    required this.title,
    required this.time,
    required this.category,
    this.repeat = RepeatType.once,
    this.daysOfWeek,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'priority': priority.index,
    'id': id,
    'title': title,
    'time': time.toIso8601String(),
    'category': category,
    'repeat': repeat.index,
    'daysOfWeek': daysOfWeek,
    'isCompleted': isCompleted,
  };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    priority: Priority.values[json['priority'] ?? 1],
    id: json['id'],
    title: json['title'],
    time: DateTime.parse(json['time']),
    category: json['category'],
    repeat: RepeatType.values[json['repeat'] ?? 0],
    daysOfWeek: json['daysOfWeek'] != null ? List<int>.from(json['daysOfWeek']) : null,
    isCompleted: json['isCompleted'] ?? false,
  );
  String get timeString {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  static const Color navyText = Color(0xFF0F172A);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color softBackground = Color(0xFFF8FAFC);
  static const Color greenDone = Color(0xFF10B981);
  late final VoiceService _voice;

  List<Reminder> _reminders = [];
  bool _isLoading = true;
  int _missedCount=0;

  @override
  void initState() {
    super.initState();
    _voice = VoiceService();
    _voice.init();
    _loadReminders();
    Future.delayed(const Duration(seconds: 1), () {
      checkMissedReminders();
    });

    // checks back every 60 minutes
    Timer.periodic(const Duration(minutes: 60), (_) {
      checkMissedReminders();
    });


    NotificationService.onNotificationClick = (String? payload) {
      if (payload != null && payload != 'magic_eye_screen') {
        _handleNotificationTap(payload);
      }
    };
  }

  void _handleNotificationTap(String reminderId) async {
    final index = _reminders.indexWhere((r) => r.id == reminderId);

    if (index != -1) {
      final r = _reminders[index];

      r.isCompleted = true;

      _handleAutoRepeat(r);

      // SAVE using service
      await ReminderService.updateReminder(r);

      // Refresh UI from source of truth
      await _loadReminders();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Marked '${r.title}' as done! ✨")),
      );
    }
  }

  void snoozeReminder(Reminder r) {
    final newTime = DateTime.now().add(Duration(minutes: 10));

    NotificationService.scheduleReminder(
      id: r.id.hashCode,
      title: "Snoozed: ${r.title}",
      body: "Reminder again 😊",
      scheduledDate: newTime,
      reminderId: r.id,
    );
  }

  Future<void> _loadReminders() async {
    final reminders = await ReminderService.getReminders();

    setState(() {
      _reminders = reminders;
      _isLoading = false;
    });
  }
  void _handleAutoRepeat(Reminder reminder) {
    DateTime nextTime;

    if (reminder.repeat == RepeatType.daily) {
      nextTime = reminder.time.add(const Duration(days: 1));
    }
    else if (reminder.repeat == RepeatType.weekly && reminder.daysOfWeek != null) {
      final now = DateTime.now();

      // Find next selected weekday
      int today = now.weekday; // 1 = Monday
      int? nextDay;

      for (int i = 1; i <= 7; i++) {
        int checkDay = ((today + i - 1) % 7) + 1;
        if (reminder.daysOfWeek!.contains(checkDay)) {
          nextDay = checkDay;
          break;
        }
      }

      if (nextDay == null) return;

      int diff = nextDay - today;
      if (diff <= 0) diff += 7;

      nextTime = DateTime(
        now.year,
        now.month,
        now.day + diff,
        reminder.time.hour,
        reminder.time.minute,
      );
    }
    else {
      return;
    }

    // 🔁 update reminder time
    reminder.time = nextTime;

    // 🔔 schedule again
    NotificationService.scheduleReminder(
      id: reminder.id.hashCode,
      title: "Reminder: ${reminder.title}",
      body: "It's time for your ${reminder.category} task 😊",
      scheduledDate: nextTime,
      reminderId: reminder.id,
    );
  }

  // Future<void> _saveReminders() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final String encodedData = jsonEncode(_reminders.map((r) => r.toJson()).toList());
  //   await prefs.setString('saved_reminders', encodedData);
  // }

  double _calculateProgress() {
    if (_reminders.isEmpty) return 0.0;
    return _reminders.where((r) => r.isCompleted).length / _reminders.length;
  }

  @override
  Widget build(BuildContext context) {
    _reminders.sort((a, b) => a.time.compareTo(b.time));

    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: navyText, size: 28),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: const Icon(Icons.volume_up_rounded, color: accentBlue, size: 32),
              onPressed: () {
                final pending = _reminders.where((r) => !r.isCompleted).toList();

                if (pending.isEmpty) {
                  _voice.speak("Hey there, you've finished all your tasks for today. Great job!");
                } else {
                  String schedule = pending
                      .map((r) => "${r.title} at ${DateFormat('h:mm a').format(r.time)}")
                      .join(", then ");
                  _voice.speak("Hi there, you have $schedule remaining today.");
                }
              },
            ),
          ),
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Daily Schedule", style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.w800, color: navyText, fontSize: 26)),
            Text("I'll help you remember :)", style: GoogleFonts.atkinsonHyperlegible(color: accentBlue, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReminderDialog,
        backgroundColor: navyText,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        label: Text("Add Reminder", style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildProgressCard(),
          Expanded(
            child: _reminders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              itemCount: _reminders.length,
              itemBuilder: (context, index) => _buildReminderCard(_reminders[index]),
            ),
          ),
        ],
      ),
    );
  }
  Color _getAdaptiveColor() {
    final hour = DateTime.now().hour;
    if (hour < 12) return const Color(0xFF3B82F6); // Morning Blue
    if (hour < 17) return Colors.orange.shade400;  // Afternoon Gold
    return const Color(0xFF1E293B);               // Evening Navy (matches your navyText)
  }

  Widget _buildProgressCard() {
    double progress = _calculateProgress();
    final dynamicColor = _getAdaptiveColor();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: dynamicColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: accentBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress == 1.0 && _reminders.isNotEmpty ? "All done! ✨" : "You're doing great!",
                  style: GoogleFonts.atkinsonHyperlegible(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                ),
                Text(
                  "Finished ${(_reminders.where((r) => r.isCompleted).length)} of ${_reminders.length} tasks.",
                  style: GoogleFonts.atkinsonHyperlegible(color: Colors.white.withOpacity(0.9), fontSize: 18),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 60,
            width: 60,
            child: CircularProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              color: Colors.white,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildReminderCard(Reminder reminder) {
    IconData icon;
    Color color;
    switch (reminder.category) {
      case 'meds': icon = Icons.medication_rounded; color = Colors.orange; break;
      case 'meals': icon = Icons.restaurant_rounded; color = Colors.teal; break;
      case 'health': icon = Icons.favorite_rounded; color = Colors.redAccent; break;
      case 'social': icon = Icons.people_rounded; color = Colors.purple; break;
      default: icon = Icons.notifications_active_rounded; color = accentBlue;
    }

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.delete_outline, color: Colors.red, size: 30),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Reminder?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        // setState(() => _reminders.remove(reminder));
        // _saveReminders();
        // NotificationService.cancelReminder(reminder.id.hashCode);
        await ReminderService.deleteReminder(reminder.id);
        _loadReminders();
        NotificationService.cancelReminder(reminder.id.hashCode);
      },
      child: GestureDetector(
        onTap: () async {
          reminder.isCompleted = !reminder.isCompleted;
          await ReminderService.updateReminder(reminder);
          _loadReminders();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: reminder.isCompleted ? Colors.white.withOpacity(0.6) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: reminder.isCompleted ? greenDone.withOpacity(0.3) : Colors.transparent, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                height: 55,
                width: 55,
                decoration: BoxDecoration(color: (reminder.isCompleted ? Colors.grey : color).withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: reminder.isCompleted ? Colors.grey : color, size: 30),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reminder.title,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: reminder.isCompleted ? Colors.grey : navyText,
                          decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                        )),
                    Text(DateFormat('hh:mm a').format(reminder.time),
                        style: GoogleFonts.atkinsonHyperlegible(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Transform.scale(
                scale: 1.4,
                child: Checkbox(
                  value: reminder.isCompleted,
                  activeColor: greenDone,
                  shape: const CircleBorder(),
                  onChanged: (val) async {
                    // setState(() => reminder.isCompleted = val!);
                    // _saveReminders();
                    reminder.isCompleted = val!;
                    await ReminderService.updateReminder(reminder);
                    _loadReminders();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().moveX(begin: 10);
  }

  void _showAddReminderDialog() {
    final titleController = TextEditingController();
    DateTime pickedTime = DateTime.now();
    String selectedCat = 'meds';
    RepeatType selectedRepeat = RepeatType.once;
    List<int> selectedDays = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          title: Text("Create Reminder", style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.w900, color: navyText, fontSize: 24)),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.atkinsonHyperlegible(fontSize: 18),
                    decoration: InputDecoration(
                      hintText: "E.g. Breakfast or Evening Tea",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: softBackground,
                      contentPadding: const EdgeInsets.all(20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text("What kind of reminder?", style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold, color: navyText, fontSize: 18)),
                  const SizedBox(height: 12),
                  _buildCategoryTile(setDialogState, 'meds', 'Medicine', 'Take your tablets or drops', Icons.medication, selectedCat, (val) => selectedCat = val),
                  _buildCategoryTile(setDialogState, 'meals', 'Meals & Nutrition', 'Breakfast, lunch, or dinner', Icons.restaurant_rounded, selectedCat, (val) => selectedCat = val),
                  _buildCategoryTile(setDialogState, 'health', 'Health & Wellness', 'Exercise, water, or rest', Icons.favorite, selectedCat, (val) => selectedCat = val),
                  _buildCategoryTile(setDialogState, 'social', 'Social & Family', 'Call family or meet friends', Icons.people, selectedCat, (val) => selectedCat = val),
                  const SizedBox(height: 25),
                  Text("How often?", style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold, fontSize: 18, color: navyText)),
                  const SizedBox(height: 10),
                  _buildRepeatOption("Remind me once", RepeatType.once, selectedRepeat, (val) => setDialogState(() => selectedRepeat = val)),
                  _buildRepeatOption("Every day", RepeatType.daily, selectedRepeat, (val) => setDialogState(() => selectedRepeat = val)),
                  _buildRepeatOption("Some days", RepeatType.weekly, selectedRepeat, (val) => setDialogState(() => selectedRepeat = val)),
                  if (selectedRepeat == RepeatType.weekly)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Wrap(
                        spacing: 8,
                        children: List.generate(7, (index) {
                          final day = index + 1;
                          final isSelected = selectedDays.contains(day);
                          return ChoiceChip(
                            label: Text(["M", "T", "W", "T", "F", "S", "S"][index]),
                            selected: isSelected,
                            onSelected: (_) {
                              setDialogState(() {
                                isSelected ? selectedDays.remove(day) : selectedDays.add(day);
                              });
                            },
                          );
                        }),
                      ),
                    ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(pickedTime));
                      if (time != null) {
                        setDialogState(() => pickedTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, time.hour, time.minute));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: accentBlue, width: 2)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time_filled, color: accentBlue, size: 28),
                          const SizedBox(width: 12),
                          Text(DateFormat('hh:mm a').format(pickedTime), style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.w900, fontSize: 22, color: accentBlue)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(0, 0, 20, 20),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.atkinsonHyperlegible(fontSize: 18, color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: navyText, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () async {
                if (titleController.text.isEmpty) return;

                // Show Battery Optimization Warning
                await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Battery Settings"),
                    content: const Text("To ensure reminders arrive on time, please allow this app to run in the background."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Skip")),
                      TextButton(onPressed: () async {
                        await NotificationService.requestBatteryOptimization();
                        Navigator.pop(context);
                      }, child: const Text("Open Settings")),
                    ],
                  ),
                );

                final newRem = Reminder(
                  priority: Priority.medium,
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text,
                  time: pickedTime,
                  category: selectedCat,
                  repeat: selectedRepeat,
                  daysOfWeek: selectedRepeat == RepeatType.weekly ? selectedDays : null,
                );

                await ReminderService.createReminder(newRem);
                _loadReminders();

                NotificationService.scheduleReminder(
                  id: newRem.id.hashCode,
                  title: "Reminder: ${newRem.title}",
                  body: "It's time for your ${newRem.category} task! 😊",
                  scheduledDate: newRem.time,
                  reminderId: newRem.id,
                );
                Navigator.pop(context);
              },
              child: Text("Save", style: GoogleFonts.atkinsonHyperlegible(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  void checkMissedReminders() {
    final now = DateTime.now();
    _missedCount = 0;

    for (var r in _reminders) {
      if(!r.isCompleted && r.time.isBefore(now)) {
        _missedCount++;
        NotificationService.showInstantReminder(
          title: "You may have missed this",
          body: r.title,
        );
      }
    }
    if(_missedCount>=3){
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCareDialog();
      });
    }
  }
  void _showCareDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Just checking ❤️"),
        content: const Text("You missed a few reminders. Are you okay?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("I'm okay"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _offerHelp();
            },
            child: const Text("Need help"),
          ),
        ],
      ),
    );
  }

  void _offerHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("I'm here for you ❤️")),
    );
    //  connect to chatbot later on
  }

  Widget _buildCategoryTile(StateSetter setDialogState, String val, String title, String subtitle, IconData icon, String current, Function(String) onSelect) {
    bool isSel = val == current;
    Color catColor;
    if (val == 'meds') catColor = Colors.orange;
    else if (val == 'meals') catColor = Colors.teal;
    else if (val == 'health') catColor = Colors.redAccent;
    else catColor = Colors.purple;

    return GestureDetector(
      onTap: () => setDialogState(() => onSelect(val)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSel ? catColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? catColor : Colors.grey.shade300, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSel ? Colors.white : catColor, size: 30),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.atkinsonHyperlegible(fontSize: 18, fontWeight: FontWeight.bold, color: isSel ? Colors.white : navyText)),
                  Text(subtitle, style: GoogleFonts.atkinsonHyperlegible(fontSize: 13, color: isSel ? Colors.white.withOpacity(0.8) : Colors.grey)),
                ],
              ),
            ),
            if (isSel) const Icon(Icons.check_circle, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatOption(String text, RepeatType value, RepeatType groupValue, Function(RepeatType) onTap) {
    final isSelected = value == groupValue;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(text, style: GoogleFonts.atkinsonHyperlegible(fontSize: 16)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: greenDone) : const Icon(Icons.circle_outlined),
      onTap: () => onTap(value),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wb_sunny_rounded, size: 100, color: Colors.orange.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text("No reminders for now!", style: GoogleFonts.atkinsonHyperlegible(fontSize: 22, color: navyText, fontWeight: FontWeight.bold)),
          Text("Tap the button below to add one.", style: GoogleFonts.atkinsonHyperlegible(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}