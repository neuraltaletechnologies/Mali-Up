plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugin.
    // Kotlin support is now built into the Flutter Gradle Plugin — do NOT apply kotlin-android here.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePassword = System.getenv("KEYSTORE_PASSWORD")
val isReleaseBuildRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

if (isReleaseBuildRequested && keystorePassword.isNullOrBlank()) {
    throw GradleException(
        "KEYSTORE_PASSWORD is required for release builds. " +
            "Refusing to create a bundle with an invalid signing configuration.",
    )
}

android {
    namespace = "com.neuraltale.maliup"
    // Google Play requires Android 16 / API 36 for new apps and updates from
    // 31 August 2026. Keep this explicit so compliance does not depend on the
    // Flutter SDK version installed on a release machine.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
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
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Only populate when set so normal debug builds do not require
            // access to the release keystore.
            if (!keystorePassword.isNullOrBlank()) {
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

            // Never fall back to the debug key: Google Play rejects bundles
            // signed by any certificate other than the registered upload key.
            // Without KEYSTORE_PASSWORD, release signing validation must fail.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    implementation("com.google.android.play:integrity:1.4.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
