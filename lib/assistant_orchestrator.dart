import 'chatbot_service.dart';
import 'reminder_service.dart';
import 'notification_service.dart';
import 'reminders_screen.dart';
import 'voice_service.dart';

class AssistantOrchestrator {
  final ChatbotService bot;
  final VoiceService voice;

  AssistantOrchestrator(this.bot,this.voice);

  Future<Map<String, dynamic>> handle(String input) async {
    final res = await bot.getSmartResponse(input);

    if (res['action'] == 'CREATE_REMINDER') {
      final reminderId = DateTime.now().millisecondsSinceEpoch.toString();
      final reminder = Reminder(
        id: reminderId,
        title: res['title'],
        time: res['time'],
        category: 'general',
      );

      await ReminderService.createReminder(reminder);

      await NotificationService.scheduleReminder(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: reminder.title,
        body: "It's time 😊",
        scheduledDate: reminder.time,
        reminderId: reminderId,
      );

      await voice.speak(
        res['text'],
        isEmotional: res['intent'] == "EMOTIONAL",
      );
    }

    return res;
  }
}