import java.util.Properties
import java.io.FileInputStream


plugins {
    id("com.android.application")
    id("kotlin-android")
    // Push notifications: consumes google-services.json (package com.rawasi.azhar,
    // Firebase project rawasi-222fc). The build fails loudly if that file is
    // missing or names a different package, which is the behaviour we want.
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}


android {
    namespace = "com.rawasi.azhar"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications (v10+), which shows push
        // notifications as phone notifications while the app is open.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.rawasi.azhar"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val hasReleaseKeystore = keystorePropertiesFile.exists() &&
        keystoreProperties["keyAlias"] != null &&
        keystoreProperties["keyPassword"] != null &&
        keystoreProperties["storeFile"] != null &&
        keystoreProperties["storePassword"] != null

    if (hasReleaseKeystore) {
        signingConfigs {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
    buildTypes {
        release {
            // No release keystore has been provided (no android/key.properties). Falls
            // back to debug signing so `flutter build apk`/`flutter run --release` work
            // for local testing. Add android/key.properties (keyAlias, keyPassword,
            // storeFile, storePassword) to sign with a real release key.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // R8: strips unused code and resources and renames what is left,
            // so a released APK is markedly harder to read than the plain
            // bytecode it used to ship. Flutter's own Dart code is obfuscated
            // separately, by building with --obfuscate (see README).
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Desugaring, for flutter_local_notifications (see compileOptions).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // flutter_local_notifications' README: enabling desugaring has been
    // reported to crash Flutter apps on Android 12L and above, and adding the
    // WindowManager library is the documented fix. Cheaper than finding out on
    // a student's phone.
    implementation("androidx.window:window:1.0.0")
    implementation("androidx.window:window-java:1.0.0")
}
