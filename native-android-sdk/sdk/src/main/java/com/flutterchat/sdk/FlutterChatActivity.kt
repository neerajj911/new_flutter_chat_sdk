package com.flutterchat.sdk

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

/**
 * Activity that hosts the Flutter engine and bridges MethodChannel communication.
 * Declared in the SDK's AndroidManifest.xml — consumers do not need to declare it.
 */
class FlutterChatActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL_NAME = "com.flutterchat.sdk/bridge"
    }

    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "flutterReady" -> {
                    // Flutter is ready — send user init data
                    sendInitData()
                    result.success(null)
                }
                "nativeEvent" -> {
                    val args = call.arguments as? Map<*, *>
                    val eventName = args?.get("event") as? String ?: "unknown"
                    val data = args?.get("data") as? String ?: "{}"
                    FlutterChatSDK.callback?.onNativeEvent(eventName, data)
                    result.success(null)
                }
                "rnEvent" -> {
                    val args = call.arguments as? Map<*, *>
                    val eventName = args?.get("event") as? String ?: "unknown"
                    val data = args?.get("data") as? String ?: "{}"
                    FlutterChatSDK.callback?.onRnEvent(eventName, data)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun sendInitData() {
        val user = FlutterChatSDK.pendingUser ?: return
        val json = JSONObject().apply {
            put("id", user.id)
            put("name", user.name)
            put("email", user.email)
        }
        methodChannel?.invokeMethod("initData", json.toString())
    }

    override fun onDestroy() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        super.onDestroy()
    }
}
