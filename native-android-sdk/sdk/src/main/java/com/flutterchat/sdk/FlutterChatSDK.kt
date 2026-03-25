package com.flutterchat.sdk

import android.content.Context
import android.content.Intent

/**
 * Public singleton entry point for the Flutter Chat SDK.
 * Consumers use this to configure callbacks and launch the chat.
 */
object FlutterChatSDK {

    internal var callback: FlutterChatCallback? = null
    internal var pendingUser: ChatUser? = null

    /**
     * Set the callback to receive events from the Flutter chat module.
     */
    fun setCallback(callback: FlutterChatCallback) {
        this.callback = callback
    }

    /**
     * Open the chat screen for the given user.
     * @param context Android context (typically an Activity)
     * @param user The chat user whose data will be sent to Flutter
     */
    fun openChat(context: Context, user: ChatUser) {
        pendingUser = user
        val intent = Intent(context, FlutterChatActivity::class.java)
        context.startActivity(intent)
    }
}
