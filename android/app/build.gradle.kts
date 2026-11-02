import java.io.FileInputStream
import java.util.Properties
import groovy.json.JsonSlurper

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val keystorePropertyNames = listOf("storePassword", "keyPassword", "keyAlias", "storeFile")

if (keystorePropertiesFile.isFile) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

fun signingProperty(name: String): String =
    keystoreProperties.getProperty(name)?.trim().orEmpty()

val releaseSigningValuesPresent =
    keystorePropertiesFile.isFile && keystorePropertyNames.all { signingProperty(it).isNotEmpty() }

val validateReleaseSigning = tasks.register("validateReleaseSigning") {
    doLast {
        val missing = keystorePropertyNames.filter { signingProperty(it).isEmpty() }
        if (!keystorePropertiesFile.isFile || missing.isNotEmpty()) {
            val details = if (missing.isEmpty()) {
                "file android/key.properties tidak ditemukan"
            } else {
                "property kosong: ${missing.joinToString(", ")}"
            }
            throw GradleException(
                "Signing release NALARA belum dikonfigurasi: $details. " +
                    "Salin android/key.properties.example menjadi android/key.properties " +
                    "dan isi dengan upload keystore lokal."
            )
        }

        val keystoreFile = file(signingProperty("storeFile"))
        if (!keystoreFile.isFile) {
            throw GradleException(
                "Keystore release tidak ditemukan di ${keystoreFile.absolutePath}. " +
                    "Periksa nilai storeFile pada android/key.properties."
            )
        }
    }
}

android {
    namespace = "id.giapp.nalara"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "id.giapp.nalara"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (releaseSigningValuesPresent) {
                keyAlias = signingProperty("keyAlias")
                keyPassword = signingProperty("keyPassword")
                storeFile = file(signingProperty("storeFile"))
                storePassword = signingProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Keep local release runs readable before credentials are configured,
            // but block actual release artifacts through validateReleaseSigning.
            signingConfig = if (releaseSigningValuesPresent) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

val googleServicesFile = layout.projectDirectory.file("google-services.json")
val releaseApplicationId = android.defaultConfig.applicationId
val validateReleaseGoogleSignIn = tasks.register("validateReleaseGoogleSignIn") {
    inputs.file(googleServicesFile).optional()
    doLast {
        val configFile = googleServicesFile.asFile
        if (!configFile.isFile) {
            throw GradleException(
                "Google login release belum dikonfigurasi: android/app/google-services.json " +
                    "tidak ditemukan. Unduh konfigurasi resmi Firebase untuk $releaseApplicationId."
            )
        }
        val config = try {
            JsonSlurper().parse(configFile) as? Map<*, *>
        } catch (_: Exception) {
            null
        } ?: throw GradleException("google-services.json bukan konfigurasi JSON Firebase yang valid.")

        val client = (config["client"] as? List<*>)
            ?.filterIsInstance<Map<*, *>>()
            ?.firstOrNull {
                val info = it["client_info"] as? Map<*, *>
                val androidInfo = info?.get("android_client_info") as? Map<*, *>
                androidInfo?.get("package_name") == releaseApplicationId
            } ?: throw GradleException(
                "google-services.json tidak memuat aplikasi Android $releaseApplicationId. " +
                    "Unduh konfigurasi aplikasi yang sesuai; jangan edit package_name secara manual."
            )

        val hasWebClient = (client["oauth_client"] as? List<*>)
            ?.filterIsInstance<Map<*, *>>()
            ?.any {
                (it["client_type"] as? Number)?.toInt() == 3 &&
                    (it["client_id"] as? String)?.endsWith(".apps.googleusercontent.com") == true
            } == true
        if (!hasWebClient) {
            throw GradleException(
                "Google login release belum siap: google-services.json untuk $releaseApplicationId " +
                    "tidak memiliki Web OAuth client (client_type: 3). Aktifkan Google di Firebase " +
                    "Authentication, daftarkan SHA-1 Play App Signing pada aplikasi Android tersebut, " +
                    "lalu unduh ulang google-services.json ke android/app/."
            )
        }
    }
}

tasks.matching {
    it.name == "preReleaseBuild" || it.name == "bundleRelease" || it.name == "assembleRelease"
}.configureEach {
    dependsOn(validateReleaseSigning, validateReleaseGoogleSignIn)
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
