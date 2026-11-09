import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Assinatura de release (Task 10.1). O build-apk.yml gera android/key.properties
// a partir dos secrets do GitHub. Sem o arquivo (build local), o release usa a
// chave de debug, então o APK local não atualiza por cima do APK do CI.
val keystorePropertiesFile = rootProject.file("key.properties")
val temKeystoreDeRelease = keystorePropertiesFile.exists()
val keystoreProperties = Properties().apply {
    if (temKeystoreDeRelease) FileInputStream(keystorePropertiesFile).use { load(it) }
}
fun propriedadeKeystore(nome: String): String =
    requireNotNull(keystoreProperties.getProperty(nome)) { "key.properties sem \"$nome\"" }

android {
    namespace = "com.pesqueefale.pesque_fale_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.pesqueefale.pesque_fale_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (temKeystoreDeRelease) {
            create("release") {
                keyAlias = propriedadeKeystore("keyAlias")
                keyPassword = propriedadeKeystore("keyPassword")
                storeFile = file(propriedadeKeystore("storeFile"))
                storePassword = propriedadeKeystore("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (temKeystoreDeRelease) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
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
