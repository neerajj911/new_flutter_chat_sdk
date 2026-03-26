import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/chat_user.dart';
import '../services/platform_channel.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';

class ChatScreen extends StatefulWidget {
  // final ChatUser? user;
  // const ChatScreen(this.user, {super.key});

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
    _initPlatformChannel();
  }

  // @override
  // void initState() {
  //   super.initState();

  //   if (widget.user != null) {
  //     // ✅ Flutter direct usage
  //     _currentUser = widget.user;
  //     _isInitialized = true;

  //     _addMessage(ChatMessage(
  //       id: 'welcome',
  //       text: 'Welcome, ${widget.user!.name}!',
  //       senderId: 'system',
  //       senderName: 'System',
  //       timestamp: DateTime.now(),
  //       isMe: false,
  //     ));
  //   } else {
  //     // ✅ Kotlin / Native flow
  //     _initPlatformChannel();
  //   }
  // }

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
          text: 'Welcome, ${user.name}! Start chatting.',
          senderId: 'system',
          senderName: 'System',
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
          text: 'Thanks for your message! This is an auto-reply.',
          senderId: 'bot',
          senderName: 'Chat Bot here',
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
        title: Text(_isInitialized
            ? 'Chatting with username - ${_currentUser?.name ?? ""}'
            : 'Flutter Chat'),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet.\nWaiting for initialization...',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
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
