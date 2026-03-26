import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';
import 'services/platform_channel.dart';

void main() {
  runApp(const FlutterChatApp());
}

class FlutterChatApp extends StatelessWidget {
  const FlutterChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const ChatScreen(),
    );
  }
}
