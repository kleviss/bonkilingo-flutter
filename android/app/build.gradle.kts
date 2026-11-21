import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing (Google Play upload key). android/key.properties and the
// keystore are gitignored and never committed; see android/key.properties.example.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKey = keystorePropertiesFile.exists()
if (hasReleaseKey) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// The keyboard calls the backend itself (it has no Flutter engine), so it
// gets the URL from env.json at build time, like the app's --dart-define-from-file.
val keyboardApiBaseUrl: String = rootProject.file("../env.json").takeIf { it.exists() }
    ?.readText()
    ?.let { Regex("\"API_BASE_URL\"\\s*:\\s*\"(https://[^\"]+)\"").find(it)?.groupValues?.get(1) }
    ?: "https://bonkilingo-backend.vercel.app"

android {
    namespace = "com.bonkilingo.app"
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
        // Permanent once the app is on Google Play.
        applicationId = "com.bonkilingo.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "bonkilingo_api_base_url", keyboardApiBaseUrl)
    }

    signingConfigs {
        if (hasReleaseKey) {
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
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                // Lets `flutter run --release` work without the upload key.
                // Google Play rejects bundles signed this way.
                logger.warn("android/key.properties not found: release build is signed with the DEBUG key")
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Keyboard logic tests (app/src/test). org.json is a stub in local unit tests.
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20240303")
}
