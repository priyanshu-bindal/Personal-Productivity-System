import java.io.File
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// ---------------------------------------------------------------------------
// Release Signing Configuration Loader
// Priority:
// 1. Environment variables: KEYSTORE_PATH, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD
// 2. Local properties file: mobile/android/key.properties
// ---------------------------------------------------------------------------
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties").takeIf { it.exists() }
    ?: project.file("key.properties").takeIf { it.exists() }

if (keystorePropertiesFile != null && keystorePropertiesFile.isFile) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun resolveKeystoreFile(pathString: String?): File? {
    if (pathString.isNullOrBlank()) return null
    val expandedPath = if (pathString.startsWith("~/") || pathString.startsWith("~\\")) {
        File(System.getProperty("user.home"), pathString.substring(2)).absolutePath
    } else {
        pathString
    }
    val candidate = File(expandedPath)
    return if (candidate.isAbsolute) {
        candidate
    } else {
        val fromRoot = rootProject.file(expandedPath)
        if (fromRoot.exists()) fromRoot else project.file(expandedPath)
    }
}

val envKeystorePath = System.getenv("KEYSTORE_PATH")
val envKeystorePassword = System.getenv("KEYSTORE_PASSWORD")
val envKeyAlias = System.getenv("KEY_ALIAS")
val envKeyPassword = System.getenv("KEY_PASSWORD")

val keystorePath: String? = envKeystorePath?.takeIf { it.isNotBlank() } ?: keystoreProperties.getProperty("storeFile")?.trim()
val keystorePassword: String? = envKeystorePassword?.takeIf { it.isNotBlank() } ?: keystoreProperties.getProperty("storePassword")?.trim()
val keyAliasValue: String? = envKeyAlias?.takeIf { it.isNotBlank() } ?: keystoreProperties.getProperty("keyAlias")?.trim()
val keyPasswordValue: String? = envKeyPassword?.takeIf { it.isNotBlank() } ?: keystoreProperties.getProperty("keyPassword")?.trim()

val resolvedKeystoreFile = resolveKeystoreFile(keystorePath)

val isReleaseSigningConfigured = !keystorePath.isNullOrBlank() &&
    !keystorePassword.isNullOrBlank() &&
    !keyAliasValue.isNullOrBlank() &&
    !keyPasswordValue.isNullOrBlank() &&
    resolvedKeystoreFile != null &&
    resolvedKeystoreFile.exists()

android {
    namespace = "com.focusflow.focus_flow"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.focusflow.focus_flow"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (isReleaseSigningConfigured) {
            create("release") {
                storeFile = resolvedKeystoreFile
                storePassword = keystorePassword
                keyAlias = keyAliasValue
                keyPassword = keyPasswordValue
                enableV1Signing = true
                enableV2Signing = true
            }
        }
    }

    buildTypes {
        release {
            if (isReleaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // NEVER fall back to the debug key for release builds
                signingConfig = null
            }

            // Minification/shrinking is disabled to prevent breaking Flutter platform channels & plugins
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    applicationVariants.all {
        outputs.all {
            val output = this as? com.android.build.gradle.internal.api.BaseVariantOutputImpl
            output?.outputFileName = "FocusFlow.apk"
        }
    }
}

// Guard release tasks: Fail fast with clear error instructions if release signing is not configured
gradle.taskGraph.whenReady {
    val isReleaseRequested = allTasks.any { task ->
        val name = task.name.lowercase()
        name.contains("release") &&
            !name.contains("test") &&
            !name.contains("lint")
    }

    if (isReleaseRequested && !isReleaseSigningConfigured) {
        val missing = mutableListOf<String>()
        if (keystorePath.isNullOrBlank()) {
            missing.add("Keystore path (KEYSTORE_PATH env var or 'storeFile' in key.properties)")
        } else if (resolvedKeystoreFile == null || !resolvedKeystoreFile.exists()) {
            missing.add("Keystore file not found at: ${resolvedKeystoreFile?.absolutePath ?: keystorePath}")
        }
        if (keystorePassword.isNullOrBlank()) {
            missing.add("Keystore password (KEYSTORE_PASSWORD env var or 'storePassword' in key.properties)")
        }
        if (keyAliasValue.isNullOrBlank()) {
            missing.add("Key alias (KEY_ALIAS env var or 'keyAlias' in key.properties)")
        }
        if (keyPasswordValue.isNullOrBlank()) {
            missing.add("Key password (KEY_PASSWORD env var or 'keyPassword' in key.properties)")
        }

        throw GradleException(
            """
            ======================================================================
            FocusFlow Release Signing Configuration Error!
            ======================================================================
            Cannot build release binary because release signing is not configured:
            ${missing.joinToString("\n") { "  * $it" }}

            HOW TO CONFIGURE SIGNING:
            1. For Local Builds:
               - Copy mobile/android/key.properties.example to mobile/android/key.properties
               - Fill in your local keystore path, alias, and passwords.
               (key.properties is git-ignored and safe for local credentials)

            2. For CI Builds (GitHub Actions):
               - Set the following environment variables:
                 KEYSTORE_PATH, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD

            Security Note: Release builds deliberately fail rather than falling back to debug keys.
            ======================================================================
            """.trimIndent()
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required for flutter_local_notifications core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
