import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> messages = [
    {
      'sender': 'bot',
      'text':
          'Hi Sanskriti! 😊 Good to see you. Would you like to check your reminders or talk to me?',
    },
    {'sender': 'user', 'text': 'Where did I keep my Aadhar card?'},
    {
      'sender': 'bot',
      'text': 'You placed it in the top right corner of the top shelf.',
    },
  ];

  final TextEditingController _controller = TextEditingController();

  Widget _buildMessage(String text, bool isUser) {
    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(!isUser) ...[
          Container(
            width: 36,
            height: 56,
            margin: const EdgeInsets.only(right: 2),
            child: SvgPicture.asset(
              'assets/images/chatbot1.svg',
              color: Color(0xFF2D6A4F),
            ),
          ),
          //const SizedBox(width: 1),
        ],
        // : Icon(Icons.account_circle, color:Color(0xFF2D6A4F)),


        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal:7),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isUser
                      ? const Color(0xFF2D6A4F)
                      : const Color(0xFFA6C6B7),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 18),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),

            ),
          ),
        ),

        if (isUser)
          Container(
            width: 36,
            height: 50,
            margin: const EdgeInsets.only(left: 0, right: 5),
            child: const Icon(
              Icons.account_circle,
              color: Color(0xFF2D6A4F),
              size: 36,
            ),
          ),
        const SizedBox(width: 3),
      ],
    );
  }

  void _sendMessage() {
    String userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    setState(() {
      messages.add({'sender': 'user', 'text': userInput});
      messages.add({'sender': 'bot', 'text': "Let me check that for you..."});
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7F0ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D6A4F),
        automaticallyImplyLeading: true, // this ensures the back arrow appears
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 3,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.chat_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Your assistant',
              style: TextStyle(color: Colors.white, fontFamily: 'Inter'),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _buildMessage(msg['text']!, msg['sender'] == 'user');
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    cursorColor: Color(0xFF2D6A4F),
                    decoration: const InputDecoration(
                      hintText: 'Ask anything...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  //color:Color(0xFF2D6A4F),
                  icon: const Icon(Icons.mic, color: Color(0xFF2D6A4F)),
                  onPressed: () {
                    // voice input logic
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF2D6A4F)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
