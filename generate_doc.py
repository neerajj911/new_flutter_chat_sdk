"""Generate a PDF document explaining the Flutter Chat SDK project."""

from fpdf import FPDF


class DocPDF(FPDF):
    def header(self):
        if self.page_no() == 1:
            return
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(130, 130, 130)
        self.cell(0, 8, "Flutter Chat SDK - Technical Documentation", align="C")
        self.ln(10)

    def footer(self):
        self.set_y(-15)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(130, 130, 130)
        self.cell(0, 10, f"Page {self.page_no()}/{{nb}}", align="C")

    def title_page(self):
        pass  # title page removed

    def section_title(self, num, title):
        self.ln(4)
        self.set_font("Helvetica", "B", 14)
        self.set_text_color(25, 55, 110)
        self.cell(0, 9, f"{num}. {title}", new_x="LMARGIN", new_y="NEXT")
        self.set_draw_color(25, 55, 110)
        self.set_line_width(0.3)
        self.line(self.l_margin, self.get_y(), self.w - self.r_margin, self.get_y())
        self.ln(3)

    def sub_title(self, title):
        self.ln(2)
        self.set_font("Helvetica", "B", 10.5)
        self.set_text_color(50, 50, 50)
        self.cell(0, 6, title, new_x="LMARGIN", new_y="NEXT")
        self.ln(1)

    def body_text(self, txt):
        self.set_font("Helvetica", "", 9.5)
        self.set_text_color(40, 40, 40)
        self.multi_cell(0, 5, txt)
        self.ln(1)

    def bullet(self, txt):
        self.set_font("Helvetica", "", 9.5)
        self.set_text_color(40, 40, 40)
        self.cell(5, 5, "-")
        self.multi_cell(0, 5, txt)
        self.ln(0.5)

    def code_block(self, code, lang=""):
        self.set_font("Courier", "", 8)
        self.set_fill_color(240, 240, 245)
        self.set_text_color(30, 30, 30)
        lines = code.strip().split("\n")
        for line in lines:
            self.cell(0, 4, "  " + line, fill=True, new_x="LMARGIN", new_y="NEXT")
        self.ln(2)


def build_pdf():
    pdf = DocPDF()
    pdf.alias_nb_pages()
    pdf.set_auto_page_break(auto=True, margin=20)
    pdf.set_left_margin(18)
    pdf.set_right_margin(18)

    # ── Title Page ──
    pdf.title_page()

    # ── Page 2: Table of Contents + Overview ──
    pdf.add_page()
    pdf.section_title("1", "Project Overview")
    pdf.body_text(
        "This project demonstrates how to build a reusable Flutter Chat UI module, wrap it inside a "
        "native Android (Kotlin) SDK library, and publish it automatically using GitHub Actions to a "
        "GitHub Pages-hosted Maven repository. Any native Android app can then consume this SDK by "
        "adding a single Gradle dependency - no Flutter installation required on the consumer's side."
    )
    pdf.sub_title("Repository Structure")
    pdf.code_block(
        "flutter_chat_sdk/\n"
        "+-- flutter_chat_module/     # Flutter module (chat UI)\n"
        "+-- native-android-sdk/      # Kotlin library wrapping Flutter\n"
        "+-- KotlinDemoApp/           # Demo app consuming the SDK\n"
        "+-- .github/workflows/       # CI/CD pipeline\n"
        "+-- test_flutter_sdk_in_flutter/  # Flutter-to-Flutter test app"
    )
    pdf.sub_title("High-Level Flow")
    pdf.bullet("Flutter module provides the chat UI (screens, widgets, models).")
    pdf.bullet("Native Android SDK wraps the Flutter module and exposes a simple Kotlin API (FlutterChatSDK).")
    pdf.bullet("GitHub Actions CI/CD builds the Flutter AAR, packages the Kotlin SDK, and publishes to GitHub Pages Maven.")
    pdf.bullet("Consumer apps add the Maven URL and dependency - zero Flutter setup required.")
    pdf.sub_title("Technology Stack")
    pdf.bullet("Flutter 3.x (stable channel), Dart SDK >=3.0.0")
    pdf.bullet("Kotlin 1.9.22, AGP 8.3.0, Gradle 8.6")
    pdf.bullet("Java 17 source/target compatibility")
    pdf.bullet("minSdk 24, compileSdk/targetSdk 34")
    pdf.bullet("GitHub Actions + GitHub Pages (public Maven repo)")

    # ── Page 3: Flutter Module ──
    pdf.add_page()
    pdf.section_title("2", "Building the Flutter Module")
    pdf.sub_title("Step 1: Create a Flutter Module")
    pdf.body_text(
        "A Flutter module (as opposed to a regular app or plugin) is specifically designed for "
        "embedding into existing native apps. It is created with 'flutter create --template module' "
        "and produces a .android/ directory with Gradle build files that can generate an AAR."
    )
    pdf.sub_title("pubspec.yaml Configuration")
    pdf.body_text(
        "The pubspec.yaml declares the module metadata. The key section is the 'flutter > module' "
        "block which sets the Android package name and iOS bundle identifier:"
    )
    pdf.code_block(
        "name: flutter_chat_module\n"
        "version: 1.0.0\n"
        "environment:\n"
        "  sdk: '>=3.0.0 <4.0.0'\n"
        "flutter:\n"
        "  module:\n"
        "    androidPackage: com.flutterchat.module\n"
        "    iosBundleIdentifier: com.flutterchat.module\n"
        "  uses-material-design: true"
    )
    pdf.sub_title("Step 2: Code Structure")
    pdf.body_text(
        "The module follows clean architecture with models, services, screens, and widgets:"
    )
    pdf.bullet("models/chat_message.dart - ChatMessage data class with JSON serialization")
    pdf.bullet("models/chat_user.dart - ChatUser data class (id, name, email)")
    pdf.bullet("services/platform_channel.dart - MethodChannel bridge to native Kotlin")
    pdf.bullet("screens/chat_screen.dart - Main chat UI with message list and input")
    pdf.bullet("widgets/chat_bubble.dart - Individual message bubble widget")
    pdf.bullet("widgets/message_input.dart - Text input bar with send button")

    pdf.sub_title("Step 3: Platform Channel (Flutter <-> Kotlin Bridge)")
    pdf.body_text(
        "The PlatformChannel class creates a MethodChannel named 'com.flutterchat.sdk/bridge'. "
        "When Flutter is ready, it sends a 'flutterReady' signal to Kotlin. Kotlin responds with "
        "'initData' containing user info (JSON). Flutter can send events back via 'nativeEvent' and "
        "'rnEvent' methods. This bidirectional communication is the core of the SDK."
    )
    pdf.code_block(
        "// Channel definition\n"
        "static const MethodChannel _channel =\n"
        "    MethodChannel('com.flutterchat.sdk/bridge');\n\n"
        "// Flutter signals readiness\n"
        "_channel.invokeMethod('flutterReady', null);\n\n"
        "// Kotlin sends user data -> Flutter handles it\n"
        "case 'initData':\n"
        "  final user = ChatUser.fromJson(data);\n"
        "  _onUserDataReceived?.call(user);"
    )

    pdf.sub_title("Step 4: Build the Flutter AAR")
    pdf.body_text(
        "The Flutter module is compiled into an AAR (Android Archive) using the command below. "
        "This produces a local Maven repository under build/host/outputs/repo/ containing the "
        "flutter_release AAR and all transitive Flutter engine dependencies."
    )
    pdf.code_block(
        "cd flutter_chat_module\n"
        "flutter build aar --no-profile --no-debug --build-number 1"
    )

    # ── Native Android SDK ──
    pdf.section_title("3", "Native Android SDK (Kotlin Wrapper)")
    pdf.body_text(
        "The native-android-sdk project is a standard Android library that depends on the Flutter "
        "module AAR and exposes a clean, simple Kotlin API. Consumers never interact with Flutter directly."
    )
    pdf.sub_title("Key Classes")

    pdf.body_text("ChatUser.kt - A simple data class mirroring the Flutter side:")
    pdf.code_block(
        "data class ChatUser(\n"
        "    val id: String,\n"
        "    val name: String,\n"
        "    val email: String\n"
        ")"
    )

    pdf.body_text("FlutterChatCallback.kt - Interface for receiving events from Flutter:")
    pdf.code_block(
        "interface FlutterChatCallback {\n"
        "    fun onNativeEvent(eventName: String, data: String)\n"
        "    fun onRnEvent(eventName: String, data: String)\n"
        "    fun onError(error: String) {}\n"
        "}"
    )

    pdf.body_text("FlutterChatSDK.kt - The public singleton entry point (2 methods):")
    pdf.code_block(
        "object FlutterChatSDK {\n"
        "    fun setCallback(callback: FlutterChatCallback) { ... }\n"
        "    fun openChat(context: Context, user: ChatUser) {\n"
        "        pendingUser = user\n"
        "        val intent = Intent(context, FlutterChatActivity::class.java)\n"
        "        context.startActivity(intent)\n"
        "    }\n"
        "}"
    )

    pdf.body_text(
        "FlutterChatActivity.kt - Hosts the Flutter engine and handles MethodChannel communication. "
        "When Flutter sends 'flutterReady', the Activity responds with 'initData' containing user JSON. "
        "When Flutter sends 'nativeEvent' or 'rnEvent', the Activity forwards them to the callback."
    )

    pdf.sub_title("SDK build.gradle (Maven Publishing)")
    pdf.body_text(
        "The SDK's build.gradle applies 'maven-publish' plugin. It depends on the Flutter module AAR "
        "('com.flutterchat.module:flutter_release') and pins the Flutter engine version to the exact "
        "build hash to avoid resolution failures on Google's Maven. CI passes version parameters:"
    )
    pdf.code_block(
        "gradle :sdk:publish \\\n"
        "  -PMAVEN_REPO_URL=\"file://$PWD/build/maven-repo\" \\\n"
        "  -PSDK_VERSION=1.0.4 \\\n"
        "  -PFLUTTER_ENGINE_VERSION=\"1.0.0-<hash>\" \\\n"
        "  -PFLUTTER_MODULE_VERSION=\"1.0.0\""
    )

    pdf.sub_title("AndroidManifest.xml")
    pdf.body_text(
        "The SDK declares FlutterChatActivity in its own manifest. Since it's bundled in the AAR, "
        "consumers don't need to add any activity declarations:"
    )
    pdf.code_block(
        "<activity\n"
        "    android:name=\"com.flutterchat.sdk.FlutterChatActivity\"\n"
        "    android:exported=\"false\"\n"
        "    android:theme=\"@style/Theme.AppCompat.Light.NoActionBar\"\n"
        "    android:hardwareAccelerated=\"true\"\n"
        "    android:windowSoftInputMode=\"adjustResize\" />"
    )

    # ── GitHub Actions & Pages ──
    pdf.section_title("4", "GitHub Actions CI/CD & GitHub Pages Publishing")
    pdf.body_text(
        "The entire build-and-publish pipeline is automated via a single GitHub Actions workflow file: "
        ".github/workflows/publish-native-sdk.yml. It is triggered manually (workflow_dispatch) and "
        "accepts a version number as input."
    )
    pdf.sub_title("Workflow Steps (Step-by-Step)")

    steps = [
        ("Checkout Repository", "Uses actions/checkout@v4 to clone the repo."),
        ("Set up Java 17", "Uses actions/setup-java@v4 with Temurin distribution."),
        ("Set up Flutter", "Uses subosito/flutter-action@v2 on the stable channel."),
        ("Strip Version Prefix", "Removes any leading 'v' from the input version (e.g., v1.0.4 -> 1.0.4)."),
        ("Build Flutter AAR", "Runs 'flutter build aar --no-profile --no-debug' in flutter_chat_module/. "
         "This generates the AAR and a local Maven repo at build/host/outputs/repo/."),
        ("Get Flutter Engine Version", "Extracts the exact engine revision from 'flutter --version --machine'. "
         "This hash is critical for pinning transitive io.flutter dependencies."),
        ("Copy Flutter Maven Repo", "Copies the Flutter AAR repo into native-android-sdk/flutter-repo/ "
         "so the Kotlin SDK build can resolve the Flutter module dependency locally."),
        ("Detect Flutter Module Version", "Reads the actual directory name from the Flutter build output to "
         "get the published version string (matches pubspec.yaml version)."),
        ("Build & Publish SDK", "Runs 'gradle :sdk:publish' with Maven URL, SDK version, engine version, "
         "and module version passed as -P parameters. Output goes to build/maven-repo/."),
        ("Deploy to GitHub Pages", "Checks out or creates the gh-pages branch. Copies all Maven artifacts "
         "(Flutter module + native SDK) into a maven/ directory. Commits and force-pushes."),
        ("Create GitHub Release", "Uses softprops/action-gh-release@v2 to create a tagged release with "
         "installation instructions in the release notes."),
    ]
    for i, (name, desc) in enumerate(steps, 1):
        pdf.set_font("Helvetica", "B", 9.5)
        pdf.set_text_color(40, 40, 40)
        pdf.cell(0, 5, f"  {i}. {name}", new_x="LMARGIN", new_y="NEXT")
        pdf.set_font("Helvetica", "", 9)
        pdf.set_text_color(60, 60, 60)
        pdf.multi_cell(0, 4.5, f"      {desc}")
        pdf.ln(0.5)

    pdf.sub_title("GitHub Pages as Maven Repository")
    pdf.body_text(
        "GitHub Pages serves the gh-pages branch as a static website. Since Maven repositories are "
        "just a directory structure of POM and AAR/JAR files, GitHub Pages works perfectly as a free, "
        "public Maven host. The URL pattern is:\n\n"
        "  https://<username>.github.io/<repo>/maven\n\n"
        "No authentication is required for consumers. Each publish overwrites the gh-pages branch with "
        "all accumulated versions."
    )

    # ── Versioning & Pushing ──
    pdf.section_title("5", "Versioning & Pushing Code to GitHub")
    pdf.sub_title("How Versioning Works")
    pdf.body_text(
        "The SDK uses a manual versioning approach via the GitHub Actions workflow_dispatch input. "
        "When you trigger the 'Publish Native SDK' workflow, you provide a version string (e.g., 1.0.4). "
        "This version flows through the pipeline as follows:"
    )
    pdf.bullet("The input version becomes the SDK_VERSION Gradle property, which sets the Maven artifact version (com.flutterchat:chat-sdk:<VERSION>).")
    pdf.bullet("The Flutter module version comes from pubspec.yaml (currently 1.0.0) and is auto-detected from the build output.")
    pdf.bullet("The Flutter engine version is extracted at build time from 'flutter --version --machine' and pinned in the POM.")
    pdf.bullet("A Git tag (v<VERSION>) and GitHub Release are created automatically.")
    pdf.bullet("Consumers update their dependency: implementation 'com.flutterchat:chat-sdk:1.0.4'")

    pdf.sub_title("Pushing Code (Development Workflow)")
    pdf.body_text(
        "1. Make changes to Flutter module code or Kotlin SDK code locally.\n"
        "2. Commit and push to the main branch:\n"
        "     git add . && git commit -m \"feat: add feature X\" && git push origin main\n"
        "3. Go to GitHub > Actions > 'Publish Native SDK' > Run workflow.\n"
        "4. Enter the new version number (e.g., 1.0.5) and click 'Run workflow'.\n"
        "5. The pipeline builds, publishes to GitHub Pages, and creates a release.\n"
        "6. Consumers update their version in build.gradle to use the new version."
    )

    pdf.sub_title("Version History Example")
    pdf.code_block(
        "v1.0.0 - Initial release\n"
        "v1.0.1 - Bug fixes\n"
        "v1.0.2 - UI improvements\n"
        "v1.0.3 - Added RN event support\n"
        "v1.0.4 - Current latest"
    )

    # ── Consumer Integration ──
    pdf.section_title("6", "Consuming the SDK in a Native Kotlin App")
    pdf.body_text(
        "The KotlinDemoApp in the repository demonstrates how a native Android app consumes the SDK. "
        "Here are all the steps a consumer needs to follow:"
    )
    pdf.sub_title("Step 1: Add Maven Repositories (root build.gradle)")
    pdf.body_text("Add the GitHub Pages Maven URL and Flutter engine repository:")
    pdf.code_block(
        "allprojects {\n"
        "    repositories {\n"
        "        google()\n"
        "        mavenCentral()\n"
        "        maven { url \"https://neerajj911.github.io/\n"
        "            new_flutter_chat_sdk/maven\" }\n"
        "        maven { url \"https://storage.googleapis.com/\n"
        "            download.flutter.io\" }\n"
        "    }\n"
        "}"
    )
    pdf.sub_title("Step 2: Add SDK Dependency (app build.gradle)")
    pdf.code_block(
        "dependencies {\n"
        "    implementation 'com.flutterchat:chat-sdk:1.0.4'\n"
        "}"
    )
    pdf.sub_title("Step 3: Set Up Callback (MainActivity.kt)")
    pdf.body_text("Register a callback to receive events from the Flutter chat module:")
    pdf.code_block(
        "FlutterChatSDK.setCallback(object : FlutterChatCallback {\n"
        "    override fun onNativeEvent(\n"
        "        eventName: String, data: String) {\n"
        "        Toast.makeText(this@MainActivity,\n"
        "            \"Event: $eventName\", Toast.LENGTH_SHORT).show()\n"
        "    }\n"
        "    override fun onRnEvent(\n"
        "        eventName: String, data: String) {}\n"
        "    override fun onError(error: String) {\n"
        "        Toast.makeText(this@MainActivity,\n"
        "            error, Toast.LENGTH_SHORT).show()\n"
        "    }\n"
        "})"
    )
    pdf.sub_title("Step 4: Open Chat Screen")
    pdf.body_text("Create a ChatUser and call openChat - the SDK handles everything else:")
    pdf.code_block(
        "val user = ChatUser(\n"
        "    id = email,\n"
        "    name = name,\n"
        "    email = email\n"
        ")\n"
        "FlutterChatSDK.openChat(this, user)"
    )
    pdf.sub_title("What Happens Internally")
    pdf.bullet("FlutterChatSDK.openChat() stores the user and launches FlutterChatActivity.")
    pdf.bullet("FlutterChatActivity starts the Flutter engine and sets up the MethodChannel.")
    pdf.bullet("Flutter sends 'flutterReady' -> Kotlin responds with 'initData' (user JSON).")
    pdf.bullet("Flutter parses the user data and shows the chat screen with a welcome message.")
    pdf.bullet("User sends a message -> Flutter sends 'nativeEvent' -> Kotlin callback fires.")
    pdf.sub_title("Consumer Requirements")
    pdf.bullet("minSdk 24 or higher")
    pdf.bullet("Java 17 source/target compatibility")
    pdf.bullet("Internet permission (for Flutter engine to load)")
    pdf.bullet("No Flutter SDK installation needed!")

    # ── Page 8: Summary ──
    pdf.ln(4)
    pdf.section_title("7", "Summary & Architecture Diagram")
    pdf.body_text(
        "The complete flow can be summarized as:\n\n"
        "  [Flutter Module] --(AAR)--> [Kotlin SDK] --(Maven/GitHub Pages)--> [Consumer App]\n\n"
        "Key architectural decisions:\n"
    )
    pdf.bullet("Flutter module pattern allows embedding Flutter UI in native apps without requiring Flutter on the consumer side.")
    pdf.bullet("MethodChannel provides type-safe bidirectional communication between Dart and Kotlin.")
    pdf.bullet("GitHub Pages as a Maven repo eliminates the need for Sonatype/Maven Central setup.")
    pdf.bullet("Manual workflow_dispatch versioning gives full control over releases.")
    pdf.bullet("Engine version pinning prevents Gradle resolution failures on Google's storage.")
    pdf.bullet("SDK's AndroidManifest auto-merges into the consumer app - zero configuration needed.")

    # Output
    output_path = r"c:\Users\neeraj.mehta\StudioProjects\flutter_chat_sdk\Flutter_Chat_SDK_Documentation.pdf"
    pdf.output(output_path)
    print(f"PDF generated: {output_path}")


if __name__ == "__main__":
    build_pdf()
