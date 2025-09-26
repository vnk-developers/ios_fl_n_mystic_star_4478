
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter plugin має бути після Android та Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

// Завантаження секретів з android/key.properties (за наявності)
val keystoreProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) {
        f.inputStream().use { load(it) }
    }
}

android {
    namespace = "com.kostya.mystic_star_journey"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.game.mystic.star.journey"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Створюємо release signingConfig лише якщо key.properties існує
        if (keystoreProps.isNotEmpty()) {
            create("release") {
                keyAlias = keystoreProps["keyAlias"] as String
                keyPassword = keystoreProps["keyPassword"] as String
                storeFile = file(keystoreProps["storeFile"] as String)
                storePassword = keystoreProps["storePassword"] as String
                // enableV1Signing = true
                // enableV2Signing = true
                // enableV3Signing = true
            }
        }
    }

    buildTypes {
        getByName("release") {
            // підключаємо підписання, якщо сконфігуровано
            if (signingConfigs.findByName("release") != null) {
                signingConfig = signingConfigs.getByName("release")
            }
            // Увімкнути мінімізатор за бажанням:
            // isMinifyEnabled = true
            // isShrinkResources = true
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
        getByName("debug") {
            // debug підписується стандартним debug-ключем
        }
    }
}

flutter {
    source = "../.."
}
