package com.flutterchat.sdk

/**
 * Callback interface for receiving events from the Flutter chat module.
 */
interface FlutterChatCallback {
    /**
     * Called when a native event is received from Flutter.
     * @param eventName The name of the event
     * @param data JSON string containing event data
     */
    fun onNativeEvent(eventName: String, data: String)

    /**
     * Called when an RN-style event is received from Flutter.
     * @param eventName The name of the event
     * @param data JSON string containing event data
     */
    fun onRnEvent(eventName: String, data: String)

    /**
     * Called when the Flutter chat module encounters an error.
     * @param error Description of the error
     */
    fun onError(error: String) {}
}
