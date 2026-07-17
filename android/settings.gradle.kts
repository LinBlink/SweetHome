pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // Pinned to the last AGP 8.x release (rather than AGP 9.0.1) so
    // Gradle can stay on 8.13 — jpush_flutter's own android/build.gradle
    // still calls the deprecated `jcenter()` repository, which Gradle 9
    // removed outright but Gradle 8.x still resolves (with a warning).
    // AGP 8.13.0 is the first 8.x release whose max supported API level
    // (36.1) covers this project's compileSdk 36 requirement.
    id("com.android.application") version "8.13.0" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
