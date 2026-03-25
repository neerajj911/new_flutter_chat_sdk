# Flutter Chat SDK

A Flutter module providing chat UI, wrapped in a native Android (Kotlin) SDK library, published via GitHub Pages Maven repository.

## Repository Structure

```
├── flutter_chat_module/          # Flutter module with chat UI
├── native-android-sdk/           # Kotlin library wrapping the Flutter module
├── KotlinDemoApp/                # Demo app consuming the published SDK
└── .github/workflows/            # CI/CD for building & publishing
```

## How It Works

1. **Flutter module** provides the chat UI and communicates with native Android via `MethodChannel`
2. **Native Android SDK** wraps the Flutter module, exposing a simple Kotlin API (`FlutterChatSDK`)
3. **CI/CD** builds the Flutter AAR, packages the Kotlin SDK, and publishes to GitHub Pages Maven
4. **Consumers** add the Maven URL and dependency — no Flutter setup required on their end

## Publishing

Run the **Publish Native SDK** workflow from GitHub Actions with a version number (e.g. `1.0.0`).

## Consumer Integration

### 1. Add repositories (root `build.gradle`)

```groovy
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url "https://<username>.github.io/flutter-chat-sdk/maven" }
        maven { url "https://storage.googleapis.com/download.flutter.io" }
    }
}
```

### 2. Add dependency (app `build.gradle`)

```groovy
implementation 'com.flutterchat:chat-sdk:<VERSION>'
```

### 3. Use in your Activity

```kotlin
// Set callback for events from Flutter
FlutterChatSDK.setCallback(object : FlutterChatCallback {
    override fun onNativeEvent(eventName: String, data: String) {
        Log.d("Chat", "Event: $eventName — $data")
    }
    override fun onRnEvent(eventName: String, data: String) {
        Log.d("Chat", "RN Event: $eventName — $data")
    }
})

// Open the chat
FlutterChatSDK.openChat(this, ChatUser("user-id", "Name", "email@example.com"))
```

## Technical Details

- **MethodChannel**: `com.flutterchat.sdk/bridge`
- **Gradle**: 8.6  |  **AGP**: 8.3.0  |  **Kotlin**: 1.9.22
- **minSdk**: 24  |  **compileSdk/targetSdk**: 34
- **Java**: 17 source/target compatibility
- Zero authentication required for consumers (public GitHub Pages)
