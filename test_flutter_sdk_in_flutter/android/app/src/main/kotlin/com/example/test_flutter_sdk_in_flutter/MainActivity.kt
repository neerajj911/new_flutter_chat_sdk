package com.example.test_flutter_sdk_in_flutter

import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.flutterchat.sdk.ChatUser
import com.flutterchat.sdk.FlutterChatCallback
import com.flutterchat.sdk.FlutterChatSDK

class MainActivity : FlutterActivity() {

    companion object {
        private const val LAUNCHER_CHANNEL = "com.flutterchat.sdk/launcher"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set callback to receive events from Flutter chat SDK
        FlutterChatSDK.setCallback(object : FlutterChatCallback {
            override fun onNativeEvent(eventName: String, data: String) {
                runOnUiThread {
                    Toast.makeText(this@MainActivity, "Event: $eventName", Toast.LENGTH_SHORT).show()
                }
            }
            override fun onRnEvent(eventName: String, data: String) {}
            override fun onError(error: String) {
                runOnUiThread {
                    Toast.makeText(this@MainActivity, "Error: $error", Toast.LENGTH_SHORT).show()
                }
            }
        })

        // Handle openChat from Flutter Dart side → launch native SDK's FlutterChatActivity
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LAUNCHER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openChat" -> {
                        val args = call.arguments as? Map<*, *>
                        if (args == null) {
                            result.error("INVALID_ARGS", "Expected map", null)
                            return@setMethodCallHandler
                        }
                        val user = ChatUser(
                            id = args["id"] as? String ?: "",
                            name = args["name"] as? String ?: "",
                            email = args["email"] as? String ?: ""
                        )
                        // Launch the Flutter Chat SDK's activity (separate Flutter engine)
                        FlutterChatSDK.openChat(this@MainActivity, user)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
