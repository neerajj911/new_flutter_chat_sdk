import 'package:flutter/material.dart';
import 'models/chat_user.dart';
import 'screens/chat_screen.dart';

/// Callback for receiving events from the chat screen.
typedef FlutterChatCallback = void Function(
    String eventName, Map<String, dynamic> data);

/// Public entry point for the Flutter Chat SDK.
/// Consumers use this class to configure and launch the chat.
///
/// Usage:
/// ```dart
/// FlutterChatSDK.setCallback((event, data) {
///   print('Event: $event, Data: $data');
/// });
///
/// FlutterChatSDK.openChat(
///   context: context,
///   userId: 'user@example.com',
///   userName: 'John',
///   userEmail: 'user@example.com',
/// );
/// ```
class FlutterChatSDK {
  FlutterChatSDK._();

  static FlutterChatCallback? _callback;

  /// Set a callback to receive chat events (e.g. messageSent).
  static void setCallback(FlutterChatCallback callback) {
    _callback = callback;
  }

  /// Open the chat screen for the given user.
  static void openChat({
    required BuildContext context,
    required String userId,
    required String userName,
    required String userEmail,
  }) {
    final user = ChatUser(id: userId, name: userName, email: userEmail);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(user: user),
      ),
    );
  }

  /// Get the current callback (used internally by ChatScreen).
  static FlutterChatCallback? get callback => _callback;
}
