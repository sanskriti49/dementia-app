import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'settings_provider.dart';
import 'chatbot_service.dart';
import 'assistant_orchestrator.dart';
import 'voice_service.dart';
import 'speech_service.dart';
import 'package:permission_handler/permission_handler.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final AssistantOrchestrator _orchestrator;
  final ChatbotService _service = ChatbotService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> messages = [];
  late final VoiceService _voice;
  late final SpeechService _speech;

  bool _isListening = false;
  bool _isLoading = false;

  static const Color navyText = Color(0xFF0F172A);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color softBackground = Color(0xFFF8FAFC);
  static const Color botBubbleColor = Colors.white;
  static const Color userBubbleColor = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _voice = VoiceService();
    _speech = SpeechService();

    _voice.init();
    _orchestrator = AssistantOrchestrator(_service,_voice);
    _addInitialGreeting();
  }

  void _addInitialGreeting() {
    if (messages.isEmpty) {
      messages.add({
        'sender': 'bot',
        'text': 'Hi there! I’m here to keep your thoughts safe and chat whenever you need a friend. How are you feeling in this moment?',
        'time': DateTime.now(),
        'isMem': false
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    setState(() {
      messages.add({
        'sender': 'user',
        'text': text,
        'time': DateTime.now(),
        'isMem': false
      });
      _isLoading = true;
    });
    _scrollToBottom();

    final res = await _orchestrator.handle(text);
    if (!mounted) return;

    setState(() {
      messages.add({
        'sender': 'bot',
        'text': res['text'],
        'time': DateTime.now(),
        'isMem': res['usedMemory']
      });
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future<bool> _requestMicPermission() async {
    var status = await Permission.microphone.request();
    return status.isGranted;
  }
  void _startListening() async {
    bool granted = await _requestMicPermission();
    if (!granted) return;

    bool available = await _speech.init();
    print("Speech available: $available");

    if (available) {
      setState(() => _isListening = true);

      await _speech.startListening((text) {
        setState(() {
          _controller.text = text;
        });
      });
    }
  }

  void _stopListening() async {
    await _speech.stopListening();
    setState(() => _isListening = false);

    _handleSend(); // auto send after speaking
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'clear':
        _showClearDialog();
        break;
      case 'prompt':
        _showPromptDialog();
        break;
      case 'memory':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Memory viewer coming soon!")),
        );
        break;
    }
  }

  // --- INTEGRATED: Versatile & Empathetic Prompt Dialog ---
  void _showPromptDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("About your Companion",
            style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.w800, color: navyText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "I am designed to be a versatile, helpful, all-in-one companion. Whether you need help solving a day-to-day life problem, organizing your thoughts, or just someone to listen, I am here for you.",
              style: GoogleFonts.atkinsonHyperlegible(fontSize: 16, height: 1.4, color: navyText),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.psychology_alt_rounded, color: accentBlue, size: 24),
                const SizedBox(width: 8),
                Text(
                  "Memory Feature:",
                  style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold, color: accentBlue, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "I remember key details from our past chats to provide better, more personalized help for any situation you face.",
              style: GoogleFonts.atkinsonHyperlegible(fontSize: 14, color: navyText.withOpacity(0.7), height: 1.4),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Got it", style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.w800, fontSize: 16, color: accentBlue))
            ),
          )
        ],
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Clear conversation?"),
        content: const Text("This will remove all current messages from the screen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() => messages.clear());
              _addInitialGreeting();
              Navigator.pop(context);
            },
            child: const Text("Clear", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsProvider.of(context);

    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        toolbarHeight: 85,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Container(
          padding: const EdgeInsets.only(left: 8, right: 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: navyText, size: 22),
              ),
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accentBlue.withOpacity(0.2), width: 1),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: accentBlue.withOpacity(0.1),
                      child: const Icon(Icons.face_retouching_natural_rounded, color: accentBlue, size: 24),
                    ),
                  ),
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      height: 12,
                      width: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Companion",
                        style: GoogleFonts.atkinsonHyperlegible(
                          color: navyText,
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                        )),
                    const SizedBox(height: 2),
                    Text("Here to help :)",
                        style: GoogleFonts.atkinsonHyperlegible(
                          color: Colors.green.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                icon: Icon(Icons.more_horiz_rounded, color: navyText.withOpacity(0.4), size: 28),
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'prompt',
                    child: const Row(
                      children: [Icon(Icons.info_outline, size: 20), SizedBox(width: 10), Text("Check Prompts")],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'memory',
                    child: const Row(
                      children: [Icon(Icons.psychology_outlined, size: 20), SizedBox(width: 10), Text("View Memory")],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'clear',
                    child: const Row(
                      children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 10), Text("Clear Chat", style: TextStyle(color: Colors.red))],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.black.withOpacity(0.05), height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              itemCount: messages.length,
              itemBuilder: (context, i) => _buildCleanBubble(messages[i], settings),
            ),
          ),
          _buildFloatingInput(settings),
        ],
      ),
    );
  }

  Widget _buildCleanBubble(Map<String, dynamic> m, dynamic s) {
    bool isUser = m['sender'] == 'user';
    String timeString = DateFormat('h:mm a').format(m['time'] as DateTime);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 28),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (m['isMem'] == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: accentBlue),
                    const SizedBox(width: 4),
                    Text("RECALLED FROM MEMORY",
                        style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 11, color: accentBlue, fontWeight: FontWeight.w800, letterSpacing: 0.5
                        )),
                  ],
                ),
              ),
            GestureDetector(
            onTap: () async {
                if (!isUser) {
                await _voice.stop();
                }
            },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                decoration: BoxDecoration(
                  color: isUser ? userBubbleColor : botBubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(24),
                    topRight: const Radius.circular(24),
                    bottomLeft: Radius.circular(isUser ? 24 : 6),
                    bottomRight: Radius.circular(isUser ? 6 : 24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isUser ? accentBlue.withOpacity(0.2) : Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Text(
                  m['text'],
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 18,
                    color: isUser ? Colors.white : navyText,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 6, right: 6),
              child: Text(timeString, style: GoogleFonts.atkinsonHyperlegible(fontSize: 12, color: Colors.grey.shade500)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).moveY(begin: 15, end: 0);
  }

  Widget _buildFloatingInput(dynamic s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 25, offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: softBackground,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.atkinsonHyperlegible(fontSize: 17, color: navyText),
                decoration: const InputDecoration(
                  hintText: "Talk to me...",
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // 🎤 MIC BUTTON
          GestureDetector(
            // onLongPress: _startListening,
            // onLongPressUp: _stopListening,
            onTap: () {
              if (_isListening) {
                _stopListening();
              } else {
                _startListening();
              }
            },
            child: Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                color: _isListening ? Colors.red : accentBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // SEND BUTTON
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                color: accentBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      )
      // Row(
      //   children: [
      //     Expanded(
      //       child: Container(
      //         padding: const EdgeInsets.symmetric(horizontal: 24),
      //         decoration: BoxDecoration(color: softBackground, borderRadius: BorderRadius.circular(30)),
      //         child: TextField(
      //           controller: _controller,
      //           style: GoogleFonts.atkinsonHyperlegible(fontSize: 17, color: navyText),
      //           decoration: const InputDecoration(
      //             hintText: "Talk to me...",
      //             border: InputBorder.none,
      //             contentPadding: EdgeInsets.symmetric(vertical: 20),
      //             hintStyle: TextStyle(color: Colors.black26),
      //           ),
      //           onSubmitted: (_) => _handleSend(),
      //         ),
      //       ),
      //     ),
      //     const SizedBox(width: 15),
      //     GestureDetector(
      //       onTap: _handleSend,
      //       child: Container(
      //         height: 60,
      //         width: 60,
      //         decoration: BoxDecoration(
      //           color: accentBlue,
      //           shape: BoxShape.circle,
      //           boxShadow: [
      //             BoxShadow(color: accentBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
      //           ],
      //         ),
      //         child: _isLoading
      //             ? const Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
      //             : const Icon(Icons.send_rounded, color: Colors.white, size: 28),
      //       ),
      //     ),
      //   ],
      // ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}