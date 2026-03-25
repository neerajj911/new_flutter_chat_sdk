import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/chat_user.dart';

typedef OnUserDataReceived = void Function(ChatUser user);
typedef OnError = void Function(String error);

class PlatformChannel {
  static const MethodChannel _channel = MethodChannel(
    'com.flutterchat.sdk/bridge',
  );

  static OnUserDataReceived? _onUserDataReceived;
  static OnError? _onError;

  static void init({OnUserDataReceived? onUserDataReceived, OnError? onError}) {
    _onUserDataReceived = onUserDataReceived;
    _onError = onError;

    _channel.setMethodCallHandler(_handleMethodCall);

    // Signal to Kotlin that Flutter is ready
    _channel.invokeMethod('flutterReady', null);
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'initData':
        try {
          final data = call.arguments is String
              ? jsonDecode(call.arguments as String) as Map<String, dynamic>
              : call.arguments as Map<String, dynamic>;
          final user = ChatUser.fromJson(data);
          _onUserDataReceived?.call(user);
        } catch (e) {
          _onError?.call('Failed to parse init data: $e');
        }
        break;
      default:
        throw MissingPluginException('Not implemented: ${call.method}');
    }
  }

  /// Send a native event back to Kotlin
  static Future<void> sendNativeEvent(
    String eventName,
    Map<String, dynamic> data,
  ) async {
    try {
      await _channel.invokeMethod('nativeEvent', {
        'event': eventName,
        'data': jsonEncode(data),
      });
    } on PlatformException catch (e) {
      _onError?.call('Failed to send native event: ${e.message}');
    }
  }

  /// Send an RN-style event back to Kotlin
  static Future<void> sendRnEvent(
    String eventName,
    Map<String, dynamic> data,
  ) async {
    try {
      await _channel.invokeMethod('rnEvent', {
        'event': eventName,
        'data': jsonEncode(data),
      });
    } on PlatformException catch (e) {
      _onError?.call('Failed to send RN event: ${e.message}');
    }
  }

  static void dispose() {
    _channel.setMethodCallHandler(null);
    _onUserDataReceived = null;
    _onError = null;
  }
}
