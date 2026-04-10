plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ecodex"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.ecodex"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 21
        
        // Conditional check for targetSdk - works with both property and method access
        targetSdk = if (flutter.hasProperty("targetSdkVersion")) {
            flutter.targetSdkVersion
        } else {
            flutter.targetSdkVersion()
        }
        
        // Conditional check for versionCode
        versionCode = if (flutter.hasProperty("versionCode")) {
            flutter.versionCode
        } else {
            flutter.versionCode()
        }
        
        // Conditional check for versionName
        versionName = if (flutter.hasProperty("versionName")) {
            flutter.versionName
        } else {
            flutter.versionName()
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}