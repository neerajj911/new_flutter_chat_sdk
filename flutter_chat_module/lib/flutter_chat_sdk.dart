import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/chat_user.dart';
import 'screens/chat_screen.dart';

/// Callback for receiving events from the chat screen.
typedef FlutterChatCallback = void Function(
    String eventName, Map<String, dynamic> data);

/// Public entry point for the Flutter Chat SDK.
///
/// The SDK communicates with the native Android layer via MethodChannel,
/// mirroring the same architecture used by the native Kotlin SDK.
///
/// Usage:
/// ```dart
/// // 1. Initialize once at app startup
/// FlutterChatSDK.init(navigatorKey: MyApp.navigatorKey);
///
/// // 2. Open chat when needed
/// FlutterChatSDK.openChat(
///   userId: 'user@example.com',
///   userName: 'John',
///   userEmail: 'user@example.com',
/// );
/// ```
class FlutterChatSDK {
  FlutterChatSDK._();

  static const MethodChannel _channel =
      MethodChannel('com.flutterchat.sdk/launcher');
  static const MethodChannel _bridge =
      MethodChannel('com.flutterchat.sdk/bridge');

  static FlutterChatCallback? _callback;
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize the SDK. Must be called once before [openChat].
  /// [navigatorKey] must be the same key passed to your [MaterialApp].
  static void init({required GlobalKey<NavigatorState> navigatorKey}) {
    _navigatorKey = navigatorKey;

    // Listen for initData sent back from native after it processes openChat
    _bridge.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'initData':
          final data = call.arguments is String
              ? jsonDecode(call.arguments as String) as Map<String, dynamic>
              : call.arguments as Map<String, dynamic>;
          final user = ChatUser.fromJson(data);
          _navigatorKey?.currentState?.push(
            MaterialPageRoute(builder: (_) => ChatScreen(user: user)),
          );
          break;
        default:
          throw MissingPluginException('Not implemented: ${call.method}');
      }
    });
  }

  /// Set a callback to receive chat events (e.g. messageSent).
  static void setCallback(FlutterChatCallback callback) {
    _callback = callback;
  }

  /// Open the chat screen for the given user.
  ///
  /// - When used in a **standalone Flutter app**, pass [context] for direct navigation.
  /// - When used **embedded in a native Android/iOS app**, omit [context] — the SDK
  ///   communicates via MethodChannel (requires [init] to have been called first).
  static void openChat({
    BuildContext? context,
    required String userId,
    required String userName,
    required String userEmail,
  }) {
    if (context != null) {
      // Flutter-to-Flutter: navigate directly without MethodChannel
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            user: ChatUser(id: userId, name: userName, email: userEmail),
          ),
        ),
      );
    } else {
      // Embedded in native: send to native layer via MethodChannel
      _channel.invokeMethod('openChat', {
        'id': userId,
        'name': userName,
        'email': userEmail,
      });
    }
  }

  /// Get the current callback (used internally by ChatScreen).
  static FlutterChatCallback? get callback => _callback;
}
