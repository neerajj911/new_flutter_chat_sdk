package com.flutterchat.demo

import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.flutterchat.sdk.ChatUser
import com.flutterchat.sdk.FlutterChatCallback
import com.flutterchat.sdk.FlutterChatSDK

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val etName = findViewById<EditText>(R.id.etName)
        val etEmail = findViewById<EditText>(R.id.etEmail)
        val btnOpenChat = findViewById<Button>(R.id.btnOpenChat)

        // Callback from Flutter
        FlutterChatSDK.setCallback(object : FlutterChatCallback {
            override fun onNativeEvent(eventName: String, data: String) {
                Toast.makeText(this@MainActivity, "Event: $eventName", Toast.LENGTH_SHORT).show()
            }

            override fun onRnEvent(eventName: String, data: String) {}

            override fun onError(error: String) {
                Toast.makeText(this@MainActivity, error, Toast.LENGTH_SHORT).show()
            }
        })

        btnOpenChat.setOnClickListener {

            val name = etName.text.toString().trim()
            val email = etEmail.text.toString().trim()

            if (name.isEmpty() || email.isEmpty()) {
                Toast.makeText(this, "Please enter name & email", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            val user = ChatUser(
                id = email,
                name = name,
                email = email
            )

            FlutterChatSDK.openChat(this, user)
        }
    }
}