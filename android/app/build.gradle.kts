plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.puremd.app"
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
        applicationId = "com.puremd.app"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Release signing: read key.properties if it exists
    val keyFile = rootProject.file("key.properties")
    if (keyFile.exists()) {
        val props = mutableMapOf<String, String>()
        keyFile.readLines().forEach { line ->
            val idx = line.indexOf('=')
            if (idx > 0) {
                props[line.substring(0, idx).trim()] = line.substring(idx + 1).trim()
            }
        }

        signingConfigs {
            create("release") {
                storeFile = file(props["storeFile"] ?: "")
                storePassword = props["storePassword"] ?: ""
                keyAlias = props["keyAlias"] ?: ""
                keyPassword = props["keyPassword"] ?: ""
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
