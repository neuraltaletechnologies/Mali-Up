plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugin.
    // Kotlin support is now built into the Flutter Gradle Plugin — do NOT apply kotlin-android here.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.neuraltale.maliup"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.neuraltale.maliup"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Only populate when set, so debug builds (which configure this
            // block too, even though they never use it) don't fail without it.
            val keystorePassword = System.getenv("KEYSTORE_PASSWORD")
            if (keystorePassword != null) {
                keyAlias = "mali-up-key"
                keyPassword = keystorePassword
                storeFile = file("keystore/mali-up-release.jks")
                storePassword = keystorePassword
            }
        }
    }

    buildTypes {
        release {
            // Enable code obfuscation and resource shrinking
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")

            // Use release signing config for Google Play; fall back to the
            // debug key locally so `flutter run --release` works without the
            // real secret. CI always sets KEYSTORE_PASSWORD.
            signingConfig = if (System.getenv("KEYSTORE_PASSWORD") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    implementation("com.google.android.play:integrity:1.4.0")
}

flutter {
    source = "../.."
}
