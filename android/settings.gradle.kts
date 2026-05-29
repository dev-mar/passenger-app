pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    plugins {
        id("com.android.settings") version "8.11.1"
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("com.android.settings")
}

// R8 en JVM propia con heap dedicado (evita OOM en :app:minifyReleaseWithR8 en Windows).
// https://developer.android.com/build/r8-execution-profiles
android {
    execution {
        profiles {
            create("texi-r8") {
                r8 {
                    runInSeparateProcess = true
                    jvmOptions += listOf(
                        "-Xms1g",
                        "-Xmx8g",
                        "-XX:+UseG1GC",
                        "-XX:+HeapDumpOnOutOfMemoryError",
                    )
                }
            }
            defaultProfile = "texi-r8"
        }
    }
}

include(":app")
