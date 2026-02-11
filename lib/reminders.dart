import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'settings_provider.dart';

class Reminder {
  final String id;
  final String title;
  final DateTime time;
  bool isCompleted;

  Reminder({
    required this.id,
    required this.title,
    required this.time,
    this.isCompleted = false,
  });
}

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final List<Reminder> _reminders = [
    Reminder(
        id: '1',
        title: 'Take morning medication',
        time: DateTime.now().add(const Duration(hours: 1))),
    Reminder(
        id: '2',
        title: 'Call the doctor',
        time: DateTime.now().add(const Duration(hours: 4))),
    Reminder(
        id: '3',
        title: 'Water the plants',
        time: DateTime.now().add(const Duration(hours: 2)),
        isCompleted: true),
    Reminder(
        id: '4',
        title: 'Read a book',
        time: DateTime.now().add(const Duration(hours: 6)),
        isCompleted: true),
  ];

  double _calculateProgress() {
    if (_reminders.isEmpty) return 0.0;
    final completedCount = _reminders.where((r) => r.isCompleted).length;
    return completedCount / _reminders.length;
  }

  Future<void> _showAddReminderDialog() async {
    final titleController = TextEditingController();
    DateTime? pickedTime;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('New Reminder', style: TextStyle(color: Color(0xFF004D40))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'What do you need to do?',
                  filled: true,
                  fillColor: const Color(0xFFF5F7F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setDialogState(() {
                          pickedTime = DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF26A69A)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time, color: Color(0xFF004D40)),
                          const SizedBox(width: 8),
                          Text(
                            pickedTime == null
                                ? 'Pick a Time'
                                : DateFormat('hh:mm a').format(pickedTime!),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26A69A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (titleController.text.isNotEmpty && pickedTime != null) {
                  setState(() {
                    _reminders.add(
                      Reminder(
                        id: DateTime.now().toString(),
                        title: titleController.text,
                        time: pickedTime!,
                      ),
                    );
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // --- TIMELINE CARD WIDGET ---
  Widget _buildTimelineCard(Reminder reminder, BuildContext context, {bool isLast = false}) {
    final settings = SettingsProvider.of(context);
    final timeFormat = DateFormat('hh:mm');
    final amPmFormat = DateFormat('a');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TIME COLUMN
          SizedBox(
            width: 70,
            child: Column(
              children: [
                Text(
                  timeFormat.format(reminder.time),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18 * settings.fontSizeMultiplier,
                    color: reminder.isCompleted ? Colors.grey : const Color(0xFF004D40),
                  ),
                ),
                Text(
                  amPmFormat.format(reminder.time),
                  style: TextStyle(
                    fontSize: 12 * settings.fontSizeMultiplier,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // 2. TIMELINE LINE
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: reminder.isCompleted ? Colors.grey.shade300 : const Color(0xFF26A69A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4)
                    ]
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade200,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // 3. TASK CARD
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Dismissible(
                key: Key(reminder.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  setState(() {
                    _reminders.removeWhere((r) => r.id == reminder.id);
                  });
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      reminder.isCompleted = !reminder.isCompleted;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: reminder.isCompleted ? Colors.grey.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: reminder.isCompleted ? Colors.transparent : Colors.grey.shade100,
                      ),
                      boxShadow: reminder.isCompleted
                          ? []
                          : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            reminder.title,
                            style: TextStyle(
                              fontSize: 16 * settings.fontSizeMultiplier,
                              fontWeight: FontWeight.w600,
                              color: reminder.isCompleted ? Colors.grey : Colors.black87,
                              decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: reminder.isCompleted ? const Color(0xFF26A69A) : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: reminder.isCompleted ? const Color(0xFF26A69A) : Colors.grey.shade400,
                                width: 2
                            ),
                          ),
                          child: reminder.isCompleted
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsProvider.of(context);

    // Sort reminders by time
    _reminders.sort((a, b) => a.time.compareTo(b.time));

    final progress = _calculateProgress();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReminderDialog,
        backgroundColor: const Color(0xFF26A69A),
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Reminder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            backgroundColor: const Color(0xFFF8F9FA),
            elevation: 0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Daily Schedule',
                style: TextStyle(
                  color: const Color(0xFF004D40),
                  fontWeight: FontWeight.bold,
                  fontSize: 22 * settings.fontSizeMultiplier,
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 20),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Color(0xFF26A69A)),
                    const SizedBox(width: 4),
                    Text(
                      "${(progress * 100).toInt()}% Done",
                      style: const TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              )
            ],
          ),

          if (_reminders.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.spa_outlined, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      "Relax! Nothing scheduled.",
                      style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return _buildTimelineCard(
                        _reminders[index],
                        context,
                        isLast: index == _reminders.length - 1
                    );
                  },
                  childCount: _reminders.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _showFontSizeSlider() {
    // Placeholder if needed, but accessible via Home usually
  }
}