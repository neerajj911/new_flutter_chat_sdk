import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/chat_user.dart';
import '../services/platform_channel.dart';
import '../version.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser? user;
  const ChatScreen({this.user, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  ChatUser? _currentUser;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _currentUser = widget.user;
      _isInitialized = true;
      _addMessage(ChatMessage(
        id: 'welcome',
        text:
            '👋 Hello ${widget.user!.name}! Welcome to FlutterChat v$sdkVersion',
        senderId: 'system',
        senderName: 'FlutterChat',
        timestamp: DateTime.now(),
        isMe: false,
      ));
    } else {
      _initPlatformChannel();
    }
  }

  void _initPlatformChannel() {
    PlatformChannel.init(
      onUserDataReceived: (user) {
        setState(() {
          _currentUser = user;
          _isInitialized = true;
        });
        // Add a welcome message
        _addMessage(ChatMessage(
          id: 'welcome',
          text: '👋 Hello ${user.name}! Welcome to FlutterChat v$sdkVersion',
          senderId: 'system',
          senderName: 'FlutterChat',
          timestamp: DateTime.now(),
          isMe: false,
        ));
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        }
      },
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
    if (_currentUser == null) return;

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      senderId: _currentUser!.id,
      senderName: _currentUser!.name,
      timestamp: DateTime.now(),
      isMe: true,
    );

    _addMessage(message);

    // Send event to native side
    PlatformChannel.sendNativeEvent('messageSent', message.toJson());

    // Simulate a reply after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _addMessage(ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_reply',
          text: '🤖 Auto-reply v$sdkVersion: Got your message!',
          senderId: 'bot',
          senderName: 'FlutterChat Bot',
          timestamp: DateTime.now(),
          isMe: false,
        ));
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    PlatformChannel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        title: _isInitialized
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💬 ${_currentUser?.name ?? ""}',
                      style: const TextStyle(fontSize: 16)),
                  Text('${_messages.length} messages',
                      style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              )
            : Text('FlutterChat v$sdkVersion'),
        elevation: 4,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFE0F2F1),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'FlutterChat SDK v$sdkVersion',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF00897B)),
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: Colors.teal),
                        SizedBox(height: 12),
                        Text(
                          'No messages yet.\nSay hello! 👋',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return ChatBubble(message: _messages[index]);
                    },
                  ),
          ),
          MessageInput(
            onSend: _handleSendMessage,
            enabled: _isInitialized,
          ),
        ],
      ),
    );
  }
}
