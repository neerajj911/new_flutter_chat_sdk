import 'package:flutter/material.dart';
import 'models/chat_user.dart';
import 'screens/chat_screen.dart';

export 'models/chat_user.dart';
export 'models/chat_message.dart';
export 'screens/chat_screen.dart';

/// Public entry point for the Flutter Chat SDK.
///
/// Usage (Flutter app):
/// ```dart
/// FlutterChatSDK.openChat(
///   context: context,
///   userId: 'user@example.com',
///   userName: 'John',
///   userEmail: 'user@example.com',
/// );
/// ```
class FlutterChatSDK {
  FlutterChatSDK._();

  /// Open the chat screen for the given user.
  /// Pass [onMessageSent] to receive messages as they are sent.
  static void openChat({
    required BuildContext context,
    required String userId,
    required String userName,
    required String userEmail,
    OnMessageSent? onMessageSent,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          user: ChatUser(id: userId, name: userName, email: userEmail),
          onMessageSent: onMessageSent,
        ),
      ),
    );
  }
}
