plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "asia.sweethome"
    // Multiple plugins (image_picker_android, geolocator_android,
    // shared_preferences_android, flutter_plugin_android_lifecycle)
    // and their transitive androidx.* deps now require
    // compileSdk ≥ 36. Hardcode to 36 — Flutter's default lags
    // behind, and bumping is forward-only (backward compatible
    // with lower target/minSdk).
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "asia.sweethome"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ─── JPush (§2.7) ────────────────────────────────────────
        // Manifest placeholders read by the JPush plugin's
        // Android-side manifest merger. The plugin's own
        // AndroidManifest.xml contains
        // `${JPUSH_PKGNAGE}`, `${JPUSH_APPKEY}`, `${JPUSH_CHANNEL}`
        // and these values get substituted at build time. AppKey
        // must be the same JIGUANG console app as the backend's
        // `JPUSH_APP_KEY` (docs/API.md §2.7) or push delivery fails
        // silently.
        manifestPlaceholders["JPUSH_PKGNAME"] = "asia.sweethome"
        manifestPlaceholders["JPUSH_APPKEY"] = "fcc5dc2e3bbda150d02bdc26"
        manifestPlaceholders["JPUSH_CHANNEL"] = "developer-default"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}


dependencies{
    implementation(platform("com.google.firebase:firebase-bom:34.16.0"))
}