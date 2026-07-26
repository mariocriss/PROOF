import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists().also { exists ->
    if (exists) {
        keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
    }
}

fun missingReleaseSigningMessage(): String {
    return """
        Release signing is not configured.
        Create android/key.properties from android/key.properties.example
        and point storeFile at your upload keystore (.jks).
        See docs/ANDROID_SIGNING.md.
        Debug builds do not require this file.
    """.trimIndent()
}

android {
    namespace = "com.proof.proof"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.proof.proof"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (!hasReleaseKeystore) {
                // Fail clearly instead of silently signing with the debug key.
                logger.error(missingReleaseSigningMessage())
            }
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                null
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// Hard-fail release assemble/bundle tasks when signing config is missing.
afterEvaluate {
    if (!hasReleaseKeystore) {
        tasks.matching {
            it.name.startsWith("assembleRelease") ||
                it.name.startsWith("bundleRelease") ||
                it.name == "assembleRelease" ||
                it.name == "bundleRelease"
        }.configureEach {
            doFirst {
                throw GradleException(missingReleaseSigningMessage())
            }
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
