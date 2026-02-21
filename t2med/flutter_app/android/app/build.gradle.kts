plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.t2med"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.t2med"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ ACTUALIZAR A VERSIÓN 2.1.4 O SUPERIOR
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // O prueba con:
    // coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    // coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.6")
    // coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.7")
}
