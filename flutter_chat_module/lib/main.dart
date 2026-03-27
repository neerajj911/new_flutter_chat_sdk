import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/chat_user.dart';
import 'models/chat_message.dart';
import 'screens/chat_screen.dart';

/// Entry point when this module is hosted by a native Android/iOS app.
/// The native SDK (Kotlin) launches FlutterActivity which runs this main().
/// All MethodChannel bridge logic lives here — NOT in the UI layer.
void main() {
  runApp(const NativeBridgeApp());
}

class NativeBridgeApp extends StatefulWidget {
  const NativeBridgeApp({super.key});

  @override
  State<NativeBridgeApp> createState() => _NativeBridgeAppState();
}

class _NativeBridgeAppState extends State<NativeBridgeApp> {
  static const _bridge = MethodChannel('com.flutterchat.sdk/bridge');

  ChatUser? _user;

  @override
  void initState() {
    super.initState();
    _bridge.setMethodCallHandler(_handleMethodCall);
    // Tell native side that Flutter is ready to receive data
    _bridge.invokeMethod('flutterReady', null);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'initData':
        final data = call.arguments is String
            ? jsonDecode(call.arguments as String) as Map<String, dynamic>
            : call.arguments as Map<String, dynamic>;
        setState(() {
          _user = ChatUser.fromJson(data);
        });
        break;
      default:
        throw MissingPluginException('Not implemented: ${call.method}');
    }
  }

  void _onMessageSent(ChatMessage message) {
    _bridge.invokeMethod('nativeEvent', {
      'event': 'messageSent',
      'data': jsonEncode(message.toJson()),
    });
  }

  @override
  void dispose() {
    _bridge.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: _user != null
          ? ChatScreen(user: _user!, onMessageSent: _onMessageSent)
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
