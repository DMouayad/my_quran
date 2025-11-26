import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.dmouayad.my_quran"
    compileSdkVersion = "android-36"
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.dmouayad.my_quran"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
    buildTypes {
        getByName("release") {
            // 4. Apply Signing Config
            signingConfig = signingConfigs.getByName("release")
            
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
            
            // F-droid splits APKs by ABI, and requires different versionCode for each ABI.
            // For each version X.Y.Z+A in pubspec where A is the version code,
            // the versionCode must be A*10+abi_version_code.
            // See:
            // * https://developer.android.com/build/gradle-tips
            // * https://developer.android.com/studio/build/configure-apk-splits

            val flutterVersionCode = flutter.versionCode ?: 1
    
            val abiVersionCodes = mapOf(
                "x86_64" to 0,
                "armeabi-v7a" to 1,
                "arm64-v8a" to 2
            )
            applicationVariants.all {
                outputs.configureEach {
                    val abi = filters.find { it.filterType == com.android.build.OutputFile.ABI }?.identifier

                    if (abi != null && abiVersionCodes.containsKey(abi)) {
                        (this as com.android.build.gradle.internal.api.ApkVariantOutputImpl).versionCodeOverride =
                            flutterVersionCode * 10 + abiVersionCodes[abi]!!
                    }
                }
            }
        }
    }
}

flutter {
    source = "../.."
}
