import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/chat_user.dart';
import '../version.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';

/// Callback when user sends a message.
typedef OnMessageSent = void Function(ChatMessage message);

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  final OnMessageSent? onMessageSent;

  const ChatScreen({required this.user, this.onMessageSent, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _addMessage(
      ChatMessage(
        id: 'welcome',
        text:
            '👋 Hello ${widget.user.name}! Welcome to FlutterChat v$sdkVersion',
        senderId: 'system',
        senderName: 'FlutterChat',
        timestamp: DateTime.now(),
        isMe: false,
      ),
    );
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage(String text) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      senderId: widget.user.id,
      senderName: widget.user.name,
      timestamp: DateTime.now(),
      isMe: true,
    );

    _addMessage(message);

    // Notify the caller (SDK layer handles sending to native if needed)
    widget.onMessageSent?.call(message);

    // Simulate a reply after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _addMessage(
          ChatMessage(
            id: '${DateTime.now().millisecondsSinceEpoch}_reply',
            text:
                '💬 Thanks for your message! This is an automated reply from FlutterChat v$sdkVersion.',
            senderId: 'bot',
            senderName: 'FlutterChat Bot',
            timestamp: DateTime.now(),
            isMe: false,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFBF360C), Color(0xFFE65100), Color(0xFFFF6D00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white38, width: 2),
              ),
              child: const CircleAvatar(
                radius: 17,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.person_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Row(
                  children: const [
                    CircleAvatar(radius: 4, backgroundColor: Color(0xFF69F0AE)),
                    SizedBox(width: 4),
                    Text(
                      'Online',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFCCBC), Color(0xFFFBE9E7)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  size: 13,
                  color: Color(0xFFE65100),
                ),
                const SizedBox(width: 4),
                Text(
                  'FlutterChat SDK v$sdkVersion',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFBF360C),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFCCBC), Color(0xFFFFAB91)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: Color(0xFFE65100),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE65100),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Say hello and start chatting! 👋',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return ChatBubble(message: _messages[index]);
                    },
                  ),
          ),
          MessageInput(onSend: _handleSendMessage, enabled: true),
        ],
      ),
    );
  }
}
