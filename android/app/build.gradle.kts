import java.util.Properties
import java.io.FileInputStream

import com.android.build.gradle.api.ApplicationVariant
import com.android.build.gradle.api.BaseVariantOutput
import com.android.build.gradle.internal.api.ApkVariantOutputImpl

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
    ndkVersion = "29.0.14206865"

    compileOptions {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
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

    dependenciesInfo {
        // Disables dependency metadata when building APKs.
        includeInApk = false
        // Disables dependency metadata when building Android App Bundles.
        includeInBundle = false
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }

    applicationVariants.all(ApplicationVariantAction())
}


flutter {
    source = "../.."
}

class ApplicationVariantAction : Action<ApplicationVariant> {
    override fun execute(variant: ApplicationVariant) {
        variant.outputs.all(VariantOutputAction(variant))
    }

    class VariantOutputAction(private val variant: ApplicationVariant) : Action<BaseVariantOutput> {
        override fun execute(output: BaseVariantOutput) {

            if (output is ApkVariantOutputImpl) {
                val abi =
                    output.getFilter(com.android.build.api.variant.FilterConfiguration.FilterType.ABI.name)
                val abiVersionCode =
                    when (abi) {
                        "x86_64" -> 1
                        "armeabi-v7a" -> 2
                        "arm64-v8a" -> 3
                        else -> 0
                    }
                val versionCode = variant.versionCode * 10 + abiVersionCode
                output.versionCodeOverride = versionCode

                val flavor = variant.flavorName
                val builtType = variant.buildType.name
                val versionName = variant.versionName
                val architecture = abi ?: "universal"

                output.outputFileName =
                    "MyQuran-v${versionName}-${architecture}-${versionCode}-${builtType}.apk"
            }
        }
    }
}
