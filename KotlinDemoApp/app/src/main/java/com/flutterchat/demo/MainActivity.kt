package com.flutterchat.demo

import android.os.Bundle
import android.util.Log
import android.widget.Button
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.flutterchat.sdk.ChatUser
import com.flutterchat.sdk.FlutterChatCallback
import com.flutterchat.sdk.FlutterChatSDK

class MainActivity : AppCompatActivity() {

    companion object {
        private const val TAG = "FlutterChatDemo"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Set up the callback to receive events from Flutter
        FlutterChatSDK.setCallback(object : FlutterChatCallback {
            override fun onNativeEvent(eventName: String, data: String) {
                Log.d(TAG, "Native event: $eventName — $data")
                runOnUiThread {
                    Toast.makeText(
                        this@MainActivity,
                        "Event: $eventName",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }

            override fun onRnEvent(eventName: String, data: String) {
                Log.d(TAG, "RN event: $eventName — $data")
            }

            override fun onError(error: String) {
                Log.e(TAG, "Chat error: $error")
            }
        })

        // Open chat button
        findViewById<Button>(R.id.btnOpenChat).setOnClickListener {
            val user = ChatUser(
                id = "user-123",
                name = "Demo User",
                email = "demo@example.com"
            )
            FlutterChatSDK.openChat(this, user)
        }
    }
}
