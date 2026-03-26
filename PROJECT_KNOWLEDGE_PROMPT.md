# Flutter Chat SDK — Complete Project Knowledge Prompt

Use this document to give any AI assistant full context of this project.  
Repository: `github.com/neerajj911/new_flutter_chat_sdk` (gh-pages branch = Maven repo)

---

## 1. WHAT THIS PROJECT IS

A Flutter Chat UI Module wrapped as a **native Android (Kotlin) SDK**, automatically built and published to **GitHub Pages as a Maven repository** using **GitHub Actions**. Any native Android app can consume it with a single Gradle dependency — no Flutter SDK needed on the consumer side.

---

## 2. REPOSITORY ROOT STRUCTURE

```
flutter_chat_sdk/
├── flutter_chat_module/          # Flutter module (chat UI source)
├── native-android-sdk/           # Kotlin Android library wrapping Flutter
├── KotlinDemoApp/                # Native Android demo app consuming the SDK
├── test_flutter_sdk_in_flutter/  # Flutter app testing the module directly (Flutter-to-Flutter)
├── .github/
│   └── workflows/
│       └── publish-native-sdk.yml  # The ONLY CI/CD workflow
├── generate_doc.py               # Python script that generates the PDF documentation
├── Flutter_Chat_SDK_Documentation.pdf  # Generated PDF documentation
└── README.md
```

---

## 3. FOLDER 1 — flutter_chat_module/ (The Flutter Module)

### What it is
A Flutter **module** (not an app or plugin). Created with `flutter create --template module`. It provides the full chat UI and communicates with the native Kotlin host via `MethodChannel`.

### pubspec.yaml
```yaml
name: flutter_chat_module
description: A Flutter module providing chat UI for native Android SDK integration.
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
flutter:
  module:
    androidPackage: com.flutterchat.module
    iosBundleIdentifier: com.flutterchat.module
  uses-material-design: true
```
Key: the `flutter > module` block is what makes it a module (not an app). The `androidPackage` becomes the Maven groupId prefix.

### lib/ file structure
```
lib/
├── main.dart                      # Entry point: runs FlutterChatApp
├── models/
│   ├── chat_message.dart          # ChatMessage data class
│   └── chat_user.dart             # ChatUser data class
├── screens/
│   └── chat_screen.dart           # Main chat UI screen
├── services/
│   └── platform_channel.dart      # MethodChannel bridge (Flutter <-> Kotlin)
└── widgets/
    ├── chat_bubble.dart            # Single message bubble widget
    └── message_input.dart          # Text input + send button widget
```

### lib/main.dart (full)
```dart
import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';
import 'services/platform_channel.dart';

void main() {
  runApp(const FlutterChatApp());
}

class FlutterChatApp extends StatelessWidget {
  const FlutterChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: ChatScreen(),
    );
  }
}
```

### lib/models/chat_user.dart (full)
```dart
class ChatUser {
  final String id;
  final String name;
  final String email;

  ChatUser({required this.id, required this.name, required this.email});

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}
```

### lib/models/chat_message.dart (full)
```dart
class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.id, required this.text, required this.senderId,
    required this.senderName, required this.timestamp, required this.isMe,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    final senderId = json['senderId'] as String? ?? '';
    return ChatMessage(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text'] as String? ?? '',
      senderId: senderId,
      senderName: json['senderName'] as String? ?? 'Unknown',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
      isMe: senderId == currentUserId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'text': text, 'senderId': senderId,
    'senderName': senderName, 'timestamp': timestamp.millisecondsSinceEpoch,
  };
}
```

### lib/services/platform_channel.dart (full) — THE CORE BRIDGE
```dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/chat_user.dart';

typedef OnUserDataReceived = void Function(ChatUser user);
typedef OnError = void Function(String error);

class PlatformChannel {
  static const MethodChannel _channel = MethodChannel('com.flutterchat.sdk/bridge');

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

  static Future<void> sendNativeEvent(String eventName, Map<String, dynamic> data) async {
    try {
      await _channel.invokeMethod('nativeEvent', {'event': eventName, 'data': jsonEncode(data)});
    } on PlatformException catch (e) {
      _onError?.call('Failed to send native event: ${e.message}');
    }
  }

  static Future<void> sendRnEvent(String eventName, Map<String, dynamic> data) async {
    try {
      await _channel.invokeMethod('rnEvent', {'event': eventName, 'data': jsonEncode(data)});
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
```

**MethodChannel name**: `com.flutterchat.sdk/bridge`

**Messages Flutter → Kotlin:**
- `flutterReady` (null args) — "I am loaded, send me user data"
- `nativeEvent` (args: `{event: String, data: JSON-String}`) — user sent a message, etc.
- `rnEvent` (args: `{event: String, data: JSON-String}`) — RN-style event

**Messages Kotlin → Flutter:**
- `initData` (args: JSON string OR Map with `id`, `name`, `email`) — sends user data to Flutter

### lib/screens/chat_screen.dart (summary + key logic)
- `StatefulWidget` that holds a `List<ChatMessage>` and a `ChatUser?`
- On `initState` calls `PlatformChannel.init()` with callbacks
- `onUserDataReceived`: sets `_currentUser`, sets `_isInitialized = true`, adds welcome message
- `_handleSendMessage(text)`: creates a `ChatMessage`, calls `PlatformChannel.sendNativeEvent('messageSent', message.toJson())`, simulates auto-reply after 1 second
- AppBar title: "Chat - {userName}" once initialized, "Flutter Chat" before
- Body: ListView of ChatBubble widgets + MessageInput at bottom
- MessageInput is disabled (`enabled: false`) until `_isInitialized` is true

### lib/widgets/chat_bubble.dart (summary)
- Renders a chat message bubble
- System messages (senderId == 'system'): centered grey italic text
- User messages: right-aligned blue bubble (Material primary color)
- Other messages: left-aligned grey bubble, shows sender name above text
- Timestamp shown at bottom of each bubble (HH:mm format)

### lib/widgets/message_input.dart (summary)
- TextField + send IconButton in a Row
- `enabled` prop controls whether input is active
- Calls parent's `onSend(text)` callback; clears field after send
- Has shadow elevation at top

### .android/ directory (auto-generated, do not manually edit)
Flutter generates this when you run `flutter build aar`. Contains:
- `settings.gradle` — pluginManagement for flutter tools, includes flutter.groovy
- `build.gradle` — library config for `com.flutterchat.module`, compileSdk 36
- `Flutter/build.gradle` — Flutter plugin loader, sets group = `com.flutterchat.module`, version = `1.0`
- `app/build.gradle` — host app for standalone testing, buildDir = `../build/host`
- Multiple `AndroidManifest.xml` files — module manifest, host app manifest

### How to build the AAR
```bash
cd flutter_chat_module
flutter build aar --no-profile --no-debug --build-number 1
```
Output: `flutter_chat_module/build/host/outputs/repo/` — a local Maven repo with:
- `com/flutterchat/module/flutter_release/<version>/flutter_release-<version>.aar`
- `com/flutterchat/module/flutter_release/<version>/flutter_release-<version>.pom`
- Flutter engine JARs and AARs as transitive dependencies

---

## 4. FOLDER 2 — native-android-sdk/ (The Kotlin Wrapper Library)

### Purpose
Standard Android library project. Depends on the Flutter module AAR. Exposes a simple Kotlin API. Consumers of this library never write any Flutter code.

### Project structure
```
native-android-sdk/
├── build.gradle          # Top-level: buildscript (AGP 8.3.0, Kotlin 1.9.22), repos
├── settings.gradle       # rootProject.name = 'native-android-sdk'; include ':sdk'
├── gradle.properties     # android.useAndroidX=true, enableJetifier=true, Xmx2048m
├── gradle/wrapper/
│   └── gradle-wrapper.properties   # distributionUrl = gradle-8.6-bin.zip
└── sdk/
    ├── build.gradle      # Library config + maven-publish
    ├── consumer-rules.pro
    ├── proguard-rules.pro
    └── src/main/
        ├── AndroidManifest.xml
        └── java/com/flutterchat/sdk/
            ├── ChatUser.kt
            ├── FlutterChatCallback.kt
            ├── FlutterChatSDK.kt
            └── FlutterChatActivity.kt
```

### Top-level build.gradle
```groovy
buildscript {
    ext.kotlin_version = '1.9.22'
    repositories { google(); mavenCentral() }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.3.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
allprojects {
    repositories {
        google(); mavenCentral()
        maven { url "https://storage.googleapis.com/download.flutter.io" }
        maven { url file("$rootDir/flutter-repo") }  // local Flutter AAR from CI
    }
}
```
Note: `flutter-repo/` is a directory copied by CI from the Flutter build output. It is NOT committed to git.

### sdk/build.gradle (full — important)
```groovy
apply plugin: 'com.android.library'
apply plugin: 'kotlin-android'
apply plugin: 'maven-publish'

android {
    namespace 'com.flutterchat.sdk'
    compileSdk 34
    defaultConfig {
        minSdk 24
        targetSdk 34
        consumerProguardFiles 'consumer-rules.pro'
    }
    buildTypes {
        release { minifyEnabled false }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = '17' }
}

def flutterModuleVersion = project.hasProperty('FLUTTER_MODULE_VERSION')
        ? project.property('FLUTTER_MODULE_VERSION') : '1.0.0'

dependencies {
    implementation "com.flutterchat.module:flutter_release:${flutterModuleVersion}"
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
}

// Pin Flutter engine transitive deps to exact hash version
if (project.hasProperty('FLUTTER_ENGINE_VERSION')) {
    def engineVer = project.property('FLUTTER_ENGINE_VERSION').toString()
    configurations.all {
        resolutionStrategy.eachDependency { DependencyResolveDetails details ->
            if (details.requested.group == 'io.flutter') {
                details.useVersion(engineVer)
                details.because('Pin to exact Flutter engine version')
            }
        }
    }
}

def mavenRepoUrl = project.hasProperty('MAVEN_REPO_URL')
        ? project.property('MAVEN_REPO_URL') : "file://${buildDir}/maven-repo"
def sdkVersion = project.hasProperty('SDK_VERSION')
        ? project.property('SDK_VERSION') : '0.0.1-SNAPSHOT'

afterEvaluate {
    publishing {
        publications {
            release(MavenPublication) {
                from components.release
                groupId = 'com.flutterchat'
                artifactId = 'chat-sdk'
                version = sdkVersion
            }
        }
        repositories {
            maven { url = mavenRepoUrl }
        }
    }
}
```

**Gradle command to publish (used by CI):**
```bash
gradle :sdk:publish \
  -PMAVEN_REPO_URL="file://$PWD/build/maven-repo" \
  -PSDK_VERSION=1.0.4 \
  -PFLUTTER_ENGINE_VERSION="1.0.0-<engineHash>" \
  -PFLUTTER_MODULE_VERSION="1.0.0"
```

### sdk/src/main/AndroidManifest.xml (full)
```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <activity
            android:name="com.flutterchat.sdk.FlutterChatActivity"
            android:exported="false"
            android:theme="@style/Theme.AppCompat.Light.NoActionBar"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize" />
    </application>
</manifest>
```
This manifest is bundled in the AAR and **auto-merged** into the consumer app's final manifest. Consumers do NOT need to declare this activity themselves.

### ChatUser.kt (full)
```kotlin
package com.flutterchat.sdk

data class ChatUser(
    val id: String,
    val name: String,
    val email: String
)
```

### FlutterChatCallback.kt (full)
```kotlin
package com.flutterchat.sdk

interface FlutterChatCallback {
    fun onNativeEvent(eventName: String, data: String)
    fun onRnEvent(eventName: String, data: String)
    fun onError(error: String) {}   // has default empty implementation
}
```

### FlutterChatSDK.kt (full) — PUBLIC API
```kotlin
package com.flutterchat.sdk

import android.content.Context
import android.content.Intent

object FlutterChatSDK {
    internal var callback: FlutterChatCallback? = null
    internal var pendingUser: ChatUser? = null

    fun setCallback(callback: FlutterChatCallback) {
        this.callback = callback
    }

    fun openChat(context: Context, user: ChatUser) {
        pendingUser = user
        val intent = Intent(context, FlutterChatActivity::class.java)
        context.startActivity(intent)
    }
}
```
- `pendingUser` is `internal` — used by `FlutterChatActivity` to send user data to Flutter
- `callback` is `internal` — used by `FlutterChatActivity` to fire events back to consumer

### FlutterChatActivity.kt (full) — THE BRIDGE HOST
```kotlin
package com.flutterchat.sdk

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

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
                    sendInitData()    // Flutter is loaded → send user JSON
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
                else -> result.notImplemented()
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
```

**MethodChannel flow summary:**
1. Flutter engine starts inside `FlutterChatActivity`
2. Flutter calls `flutterReady` → Kotlin calls `sendInitData()` → invokes `initData` on Flutter with user JSON
3. Flutter parses JSON → calls `_onUserDataReceived` callback → shows welcome message
4. User types and sends message → Flutter calls `nativeEvent` with `{event:"messageSent", data:"{...}"}`
5. Kotlin fires `FlutterChatSDK.callback?.onNativeEvent(eventName, data)` → consumer's callback runs

---

## 5. FOLDER 3 — KotlinDemoApp/ (The Consumer Demo App)

### Purpose
A plain native Android (Kotlin) app that demonstrates how to consume the published `com.flutterchat:chat-sdk` Maven artifact. It has NO Flutter code.

### Project structure
```
KotlinDemoApp/
├── build.gradle          # Top-level: buildscript + allprojects with Maven repos
├── settings.gradle       # rootProject.name = 'KotlinDemoApp'; include ':app'
├── gradle.properties     # android.useAndroidX=true
└── app/
    ├── build.gradle      # App config + dependency on chat-sdk:1.0.4
    └── src/main/
        ├── AndroidManifest.xml
        ├── java/com/flutterchat/demo/
        │   └── MainActivity.kt
        └── res/
            ├── layout/activity_main.xml
            └── values/strings.xml
```

### Root build.gradle (full) — CRITICAL: repo configuration
```groovy
buildscript {
    ext.kotlin_version = '1.9.22'
    repositories { google(); mavenCentral() }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.3.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url "https://neerajj911.github.io/new_flutter_chat_sdk/maven" }
        maven { url "https://storage.googleapis.com/download.flutter.io" }
    }
}
task clean(type: Delete) { delete rootProject.buildDir }
```
**Two extra Maven repos required:**
1. `https://neerajj911.github.io/new_flutter_chat_sdk/maven` — GitHub Pages hosting the SDK
2. `https://storage.googleapis.com/download.flutter.io` — Flutter engine AARs (transitive)

### app/build.gradle (full)
```groovy
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'

android {
    namespace 'com.flutterchat.demo'
    compileSdk 34
    defaultConfig {
        applicationId 'com.flutterchat.demo'
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName '1.0'
    }
    buildTypes { release { minifyEnabled false } }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = '17' }
}

dependencies {
    implementation 'com.flutterchat:chat-sdk:1.0.4'   // <-- THE SDK
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
}
```
**To update SDK version**: change `1.0.4` to the latest published version.

### app/src/main/AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application
        android:allowBackup="true"
        android:icon="@android:drawable/ic_dialog_info"
        android:label="@string/app_name"
        android:theme="@style/Theme.KotlinDemoApp">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <!-- FlutterChatActivity is NOT declared here; it comes from the SDK AAR manifest merge -->
    </application>
</manifest>
```

### MainActivity.kt (full)
```kotlin
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
            FlutterChatSDK.openChat(this, ChatUser(id = email, name = name, email = email))
        }
    }
}
```

### activity_main.xml (summary)
ConstraintLayout with:
- `tvTitle` (TextView) — "Flutter Chat SDK Demo", 24sp bold
- `tvDescription` (TextView) — "Enter your details and open chat powered by Flutter."
- `etName` (EditText) — id: `etName`, hint: "Enter Name"
- `etEmail` (EditText) — id: `etEmail`, hint: "Enter Email", inputType: textEmailAddress
- `btnOpenChat` (Button) — id: `btnOpenChat`, text: "Open Chat"

---

## 6. FOLDER 4 — test_flutter_sdk_in_flutter/ (Flutter-to-Flutter Test App)

### Purpose
A standard Flutter app that tests consuming the `flutter_chat_module` directly as a Flutter Git dependency (not via the Kotlin SDK). Currently the integration is **commented out** — the navigation to the chat screen is not active.

### pubspec.yaml (key parts)
```yaml
name: test_flutter_sdk_in_flutter
version: 1.0.0+1
environment:
  sdk: ^3.10.7
dependencies:
  flutter:
    sdk: flutter
  flutter_chat_module:
    git:
      url: https://github.com/neerajj911/new_flutter_chat_sdk.git
      path: flutter_chat_module
      ref: main
```
It pulls `flutter_chat_module` directly from the GitHub repo's `main` branch via Git dependency.

### lib/main.dart (summary)
- Shows a form with Name and Email fields
- "Start Chat" button — the navigation to chat is **commented out**
- All SDK integration code is commented: `// FlutterChatModule.openChat(...)`
- This app is a work-in-progress / test bed

---

## 7. .github/workflows/publish-native-sdk.yml (THE CI/CD PIPELINE — Full)

### Trigger
Manual only: `workflow_dispatch` with one required input:
```yaml
inputs:
  version:
    description: 'SDK version to publish (e.g. 1.2.0)'
    required: true
    type: string
```

### Permissions
```yaml
permissions:
  contents: write   # needed to push to gh-pages and create releases
  pages: write
```

### Job: build-and-publish (runs on ubuntu-latest)

**Step 1: Checkout**
```yaml
- uses: actions/checkout@v4
```

**Step 2: Java 17**
```yaml
- uses: actions/setup-java@v4
  with:
    distribution: 'temurin'
    java-version: '17'
```

**Step 3: Flutter (stable)**
```yaml
- uses: subosito/flutter-action@v2
  with:
    channel: stable
```

**Step 4: Strip version prefix + set env**
```bash
VERSION="${{ github.event.inputs.version }}"
VERSION="${VERSION#v}"           # removes leading 'v' if present
echo "VERSION=$VERSION" >> $GITHUB_ENV
```

**Step 5: Build Flutter AAR**
```bash
cd flutter_chat_module
flutter build aar --no-profile --no-debug --build-number 1
```
Output: `flutter_chat_module/build/host/outputs/repo/` (local Maven)

**Step 6: Get exact Flutter engine version**
```bash
ENGINE_REV=$(flutter --version --machine | python3 -c "import sys,json; v=json.load(sys.stdin); print(v['engineRevision'])")
FLUTTER_ENGINE_VERSION="1.0.0-${ENGINE_REV}"
echo "FLUTTER_ENGINE_VERSION=$FLUTTER_ENGINE_VERSION" >> $GITHUB_ENV
```
Why: Google's Flutter storage has no `maven-metadata.xml` so `+` wildcards fail. Must pin to exact hash like `1.0.0-abcdef1234`.

**Step 7: Copy Flutter repo to native SDK**
```bash
cp -r flutter_chat_module/build/host/outputs/repo native-android-sdk/flutter-repo
```
Now `native-android-sdk/flutter-repo/` exists as a local Maven repo for the SDK build.

**Step 8: Detect Flutter module AAR version**
```bash
FLUTTER_MODULE_VERSION=$(ls flutter_chat_module/build/host/outputs/repo/com/flutterchat/module/flutter_release/ | head -1)
echo "FLUTTER_MODULE_VERSION=$FLUTTER_MODULE_VERSION" >> $GITHUB_ENV
```
Reads the actual folder name (matches pubspec version, currently `1.0.0`).

**Step 9: Setup Gradle**
```yaml
- uses: gradle/actions/setup-gradle@v4
  with:
    gradle-version: '8.6'
```

**Step 10: Build and Publish SDK**
```bash
cd native-android-sdk
gradle :sdk:publish \
  -PMAVEN_REPO_URL="file://$PWD/build/maven-repo" \
  -PSDK_VERSION=${{ env.VERSION }} \
  -PFLUTTER_ENGINE_VERSION="${{ env.FLUTTER_ENGINE_VERSION }}" \
  -PFLUTTER_MODULE_VERSION="${{ env.FLUTTER_MODULE_VERSION }}"
```
Output: `native-android-sdk/build/maven-repo/com/flutterchat/chat-sdk/<VERSION>/`

**Step 11: Deploy to GitHub Pages (gh-pages branch)**
```bash
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git remote set-url origin "https://x-access-token:${{ secrets.GITHUB_TOKEN }}@github.com/${{ github.repository }}.git"

git fetch origin gh-pages || true
git checkout gh-pages || git checkout --orphan gh-pages

git rm -rf . || true
mkdir -p maven

# Copy Flutter module Maven artifacts (for transitive resolution)
cp -r flutter_chat_module/build/host/outputs/repo/* maven/
# Copy native SDK Maven artifacts
cp -r native-android-sdk/build/maven-repo/* maven/

git add maven/
git commit -m "Publish SDK v${{ env.VERSION }}" || echo "No changes to commit"
git push --force origin gh-pages
```
The `gh-pages` branch becomes a static site. GitHub Pages serves it at `https://neerajj911.github.io/new_flutter_chat_sdk/`. The Maven repo is at `/maven` path.

**Step 12: Create GitHub Release**
```yaml
- uses: softprops/action-gh-release@v2
  with:
    tag_name: "v${{ env.VERSION }}"
    name: "Flutter Chat SDK v${{ env.VERSION }}"
    body: |
      ## Flutter Chat SDK v${{ env.VERSION }}
      maven { url "https://neerajj911.github.io/new_flutter_chat_sdk/maven" }
      implementation 'com.flutterchat:chat-sdk:${{ env.VERSION }}'
    generate_release_notes: true
```
Creates a Git tag `v1.0.4` and a GitHub Release with consumer instructions.

---

## 8. VERSIONING SYSTEM

| What | Value |
|------|-------|
| SDK Maven artifact | `com.flutterchat:chat-sdk:<VERSION>` |
| Flutter module Maven artifact | `com.flutterchat.module:flutter_release:<FLUTTER_MODULE_VERSION>` |
| Flutter engine artifacts | `io.flutter:*:<1.0.0-engineHash>` |
| Git tag format | `v<VERSION>` (e.g. `v1.0.4`) |
| Current published SDK version | `1.0.4` |
| Flutter module pubspec version | `1.0.0` |

**Version is NOT in any file** — it is provided at workflow run time as a manual input. The workflow sets it as a `$GITHUB_ENV` variable and passes it to Gradle as `-PSDK_VERSION=`.

**To release a new version:**
1. Push code changes to `main`
2. GitHub → Actions → "Publish Native SDK" → Run workflow → enter version (e.g. `1.0.5`)
3. Workflow builds, publishes to `gh-pages`, creates release
4. Consumer updates: `implementation 'com.flutterchat:chat-sdk:1.0.5'`

---

## 9. MAVEN REPOSITORY STRUCTURE (on gh-pages branch)

```
gh-pages branch root/
└── maven/
    ├── com/flutterchat/module/flutter_release/   # Flutter module AAR
    │   └── 1.0.0/
    │       ├── flutter_release-1.0.0.aar
    │       └── flutter_release-1.0.0.pom
    ├── com/flutterchat/chat-sdk/                 # Native SDK AAR
    │   └── 1.0.4/
    │       ├── chat-sdk-1.0.4.aar
    │       └── chat-sdk-1.0.4.pom
    └── io/flutter/                               # Flutter engine JARs/AARs
        └── ...
```

GitHub Pages URL: `https://neerajj911.github.io/new_flutter_chat_sdk/maven`

---

## 10. KEY TECHNICAL FACTS

- **MethodChannel name**: `com.flutterchat.sdk/bridge` (used on BOTH Flutter and Kotlin sides — must match exactly)
- **Flutter module package**: `com.flutterchat.module`
- **SDK package**: `com.flutterchat.sdk`
- **Demo app package**: `com.flutterchat.demo`
- **Gradle version**: 8.6
- **AGP**: 8.3.0
- **Kotlin**: 1.9.22
- **minSdk**: 24
- **compileSdk / targetSdk**: 34
- **Java compatibility**: VERSION_17
- **Flutter channel**: stable
- **Auth required for consumers**: None (public GitHub Pages)
- **Consumer needs Flutter SDK installed**: No
- **`FlutterChatActivity` declared by consumer**: No (auto-merge from SDK AAR manifest)
- **ProGuard/R8**: disabled (`minifyEnabled false`) in all modules
- **`flutter-repo/` directory**: NOT in git, created by CI at build time
- **`gh-pages` branch content**: ONLY the `maven/` directory, overwritten on each publish

---

## 11. COMMON QUESTIONS & ANSWERS

**Q: How does the consumer app get the Flutter engine without installing Flutter?**
A: The `com.flutterchat:chat-sdk` POM declares transitive dependencies on `io.flutter:*` artifacts. These are hosted on `https://storage.googleapis.com/download.flutter.io` and automatically downloaded by Gradle.

**Q: Why is there a second Maven URL `storage.googleapis.com/download.flutter.io`?**
A: Flutter engine artifacts (ARM, x86, embedding AARs) are hosted on Google's storage, not Maven Central. Consumer apps must add this URL so Gradle can resolve Flutter transitive deps.

**Q: Why pin the Flutter engine version to `1.0.0-<hash>` instead of using `+`?**
A: Google's Flutter storage doesn't have a `maven-metadata.xml` file. Without it, Gradle can't resolve `+` wildcards and fails. The exact version hash is extracted from `flutter --version --machine` at build time.

**Q: Why does `flutter build aar` produce artifacts in `build/host/outputs/repo/`?**
A: Flutter modules use a special `.android/` Gradle project where `buildDir` is set to `../build/host`. The AAR task publishes to a local Maven repo inside that buildDir.

**Q: Can this SDK be used in iOS?**
A: The current implementation only wraps for Android. The Flutter module has `iosBundleIdentifier` set in pubspec, but no iOS native SDK wrapper exists in this repo yet.

**Q: What happens if `openChat()` is called before `setCallback()`?**
A: Works fine — `callback` is nullable. Events from Flutter will be silently dropped if callback is null. No crash.

**Q: What is `test_flutter_sdk_in_flutter` for?**
A: Testing the Flutter module directly in a Flutter app (bypassing the Kotlin SDK). Currently the navigation integration is commented out — it's a development/testing workspace.

**Q: How do I add a new feature to the chat UI?**
A: Edit files in `flutter_chat_module/lib/`. Then run the GitHub Actions workflow with a new version number (e.g. `1.0.5`). Consumers bump their version.

**Q: How do I add a new native API method (e.g., close chat programmatically)?**
1. Add `invokeMethod('closeChat', null)` call in Flutter's `platform_channel.dart`
2. Handle `case "closeChat"` in `FlutterChatActivity.configureFlutterEngine`
3. Add a public fun `closeChat()` to `FlutterChatSDK` singleton
4. Publish new version

**Q: What Gradle build system style does KotlinDemoApp use?**
A: Legacy `buildscript {}` + `allprojects {}` style (NOT the newer `dependencyResolutionManagement` / `settings.gradle` plugins block style). This is important because the newer style doesn't allow adding repos in `allprojects {}`.
