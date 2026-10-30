import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val versionPropsFile = File(projectDir, "version.properties")
val versionProps = Properties()

if (versionPropsFile.exists()) {
    FileInputStream(versionPropsFile).use { versionProps.load(it) }
} else {
    versionProps["major"] = "0"
    versionProps["minor"] = "0"
    versionProps["versionCode"] = "1"
    FileOutputStream(versionPropsFile).use { versionProps.store(it, "Supermarket Versioning") }
}

val appMajor = versionProps.getProperty("major", "0")
val appMinor = versionProps.getProperty("minor", "0")
val appVersionCode = versionProps.getProperty("versionCode", "1").toIntOrNull() ?: 1
val appVersionName = "$appMajor.$appMinor"

android {
    namespace = "com.freshness.supermarket.supermarket_customer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.freshness.supermarket.supermarket_customer"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = appVersionCode
        versionName = appVersionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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

tasks.register("createSupermarketReleaseApk") {
    doLast {
        val buildDir = project.layout.buildDirectory.asFile.get()
        val candidateDirs = listOf(
            File(buildDir, "outputs/apk/release"),
            File(buildDir, "outputs/flutter-apk")
        )

        var foundApk: File? = null
        for (dir in candidateDirs) {
            val f = File(dir, "app-release.apk")
            if (f.exists()) {
                foundApk = f
                break
            }
        }

        if (foundApk != null) {
            val apkName = "supermarket-version-$appVersionName.apk"

            // 1. Copy into flutter-apk directory
            val flutterApkDir = File(buildDir, "outputs/flutter-apk")
            if (!flutterApkDir.exists()) flutterApkDir.mkdirs()
            val targetFlutterApk = File(flutterApkDir, apkName)
            foundApk.copyTo(targetFlutterApk, overwrite = true)

            // 2. Also copy to root project release directory
            val rootReleaseDir = File(rootDir.parentFile, "release_apks")
            if (!rootReleaseDir.exists()) rootReleaseDir.mkdirs()
            val targetRootApk = File(rootReleaseDir, apkName)
            foundApk.copyTo(targetRootApk, overwrite = true)

            println("\n========================================================")
            println("🎉 SUPERMARKET RELEASE APK CREATED SUCCESSFULLY!")
            println("📦 APK Name: $apkName")
            println("📂 Path 1: ${targetFlutterApk.absolutePath}")
            println("📂 Path 2: ${targetRootApk.absolutePath}")
            println("========================================================\n")

            // Auto-increment version for next build
            val nextMinor = (appMinor.toIntOrNull() ?: 0) + 1
            val nextCode = appVersionCode + 1
            versionProps["minor"] = nextMinor.toString()
            versionProps["versionCode"] = nextCode.toString()
            FileOutputStream(versionPropsFile).use {
                versionProps.store(it, "Supermarket Auto-Incremented Version")
            }

            val rootProps = File(rootDir.parentFile, "version.properties")
            if (rootProps.exists() && rootProps.absolutePath != versionPropsFile.absolutePath) {
                FileOutputStream(rootProps).use {
                    versionProps.store(it, "Supermarket Auto-Incremented Version")
                }
            }

            println("➡️  Next release version auto-incremented to: supermarket-version-$appMajor.$nextMinor\n")
        }
    }
}

tasks.matching { it.name == "assembleRelease" }.configureEach {
    finalizedBy("createSupermarketReleaseApk")
}
