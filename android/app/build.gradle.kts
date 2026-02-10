plugins {
    id("com.android.application")

    // Kotlin Android plugin (version controlled in settings.gradle)
    id("org.jetbrains.kotlin.android")

    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration

    // Flutter Gradle Plugin (must be last)
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.future_you"

    // Flutter-managed SDK / NDK versions
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.future_you"

        // Flutter-managed values
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Optional but recommended for modern Android builds
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    buildTypes {
        debug {
            // Default debug config
            isMinifyEnabled = false
            isShrinkResources = false
        }

        release {
            // Hackathon/dev-friendly: allows release build without keystore
            signingConfig = signingConfigs.getByName("debug")

            // Keep off for now (turn on later for Play Store)
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // Prevent duplicate META-INF conflicts (common with newer deps)
    packaging {
        resources {
            excludes += setOf(
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt"
            )
        }
    }
}

flutter {
    source = "../.."
}
