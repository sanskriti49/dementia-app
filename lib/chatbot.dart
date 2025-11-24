import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'settings_provider.dart';
import 'chatbot_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> messages = [
    {
      'sender': 'bot',
      'text': 'Hi Sanskriti! 😊 I am your smart assistant. How can I help you today?',
      'time': DateTime.now(),
    },
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatbotService _chatbotService = ChatbotService();
  bool _isLoading = false;

  // --- WIDGETS ---

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(left: 16, bottom: 16, top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dot(0),
          const SizedBox(width: 4),
          _dot(100),
          const SizedBox(width: 4),
          _dot(200),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _dot(int delay) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(color: Color(0xFF26A69A), shape: BoxShape.circle),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scaleXY(begin: 0.8, end: 1.2, duration: 600.ms, delay: delay.ms)
        .moveY(begin: 0, end: -4, duration: 600.ms, delay: delay.ms, curve: Curves.easeInOut);
  }

  Widget _buildMessage(Map<String, dynamic> msg, bool isUser, double fontSizeMultiplier) {
    final text = msg['text'] as String;
    final time = msg['time'] != null ? DateFormat('hh:mm a').format(msg['time'] as DateTime) : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: SvgPicture.asset(
                    'assets/images/chatbot1.svg',
                    width: 24,
                    colorFilter: const ColorFilter.mode(Color(0xFF2D6A4F), BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(colors: [Color(0xFF2D6A4F), Color(0xFF26A69A)])
                        : null,
                    color: isUser ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(24),
                      topRight: const Radius.circular(24),
                      bottomLeft: Radius.circular(isUser ? 24 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isUser ? 0.15 : 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        text,
                        style: TextStyle(
                          color: isUser ? Colors.white : const Color(0xFF1F2937),
                          fontSize: 16 * fontSizeMultiplier,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (isUser) ...[
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFE0F2F1),
                  child: Icon(Icons.person, color: Color(0xFF004D40), size: 20),
                ),
              ],
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
                top: 6,
                left: isUser ? 0 : 50,
                right: isUser ? 50 : 0
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 10 * fontSizeMultiplier,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOut);
  }

  // --- LOGIC ---

  Future<void> _sendMessage() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty || _isLoading) return;

    _controller.clear();

    setState(() {
      messages.add({
        'sender': 'user',
        'text': userInput,
        'time': DateTime.now(),
      });
      _isLoading = true;
    });
    _scrollToBottom();

    final botResponse = await _chatbotService.sendMessage(userInput);

    if (!mounted) return;

    setState(() {
      messages.add({
        'sender': 'bot',
        'text': botResponse,
        'time': DateTime.now(),
      });
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100, // Scroll a bit extra
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsProvider.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        titleSpacing: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2D6A4F), Color(0xFF26A69A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                'assets/images/chatt.svg',
                height: 24,
                width: 24,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Your Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'Always here for you',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // 1. Background Doodle Pattern (Optional, adds polish)
          Positioned(
            top: 20,
            right: -50,
            child: Icon(Icons.favorite, size: 200, color: Colors.teal.withOpacity(0.03)),
          ),
          Positioned(
            bottom: 100,
            left: -30,
            child: Icon(Icons.chat_bubble, size: 150, color: Colors.teal.withOpacity(0.03)),
          ),

          // 2. Chat List
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessage(msg, msg['sender'] == 'user', settings.fontSizeMultiplier);
                  },
                ),
              ),

              // 3. Typing Indicator
              if (_isLoading) _buildTypingIndicator(),

              // 4. Input Area
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7F6),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (_) => _sendMessage(),
                          cursorColor: const Color(0xFF2D6A4F),
                          style: TextStyle(fontSize: 16 * settings.fontSizeMultiplier),
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Send Button with Animation
                    GestureDetector(
                      onTap: _isLoading ? null : _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2D6A4F), Color(0xFF26A69A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2D6A4F).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}