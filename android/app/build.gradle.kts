plugins {
    id("com.android.application") // ID del complemento para una aplicación Android
    id("kotlin-android") // ID del complemento para usar Kotlin en Android
    // El complemento de Gradle de Flutter debe aplicarse después de los complementos de Gradle de Android y Kotlin.
    id("dev.flutter.flutter-gradle-plugin") // ID del complemento de Gradle de Flutter
}

import java.util.Properties

// Cargamos propiedades del keystore si están disponibles en android/keystore.properties
val keystorePropertiesFile = rootProject.file("keystore.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.example.gastos" // Espacio de nombres del paquete
    compileSdk = flutter.compileSdkVersion // Versión del SDK con la que compilar (tomada de la configuración de Flutter)
    ndkVersion = "27.0.12077973" // Versión del Kit de Desarrollo Nativo (NDK)

    compileOptions { // Opciones de compilación
        sourceCompatibility = JavaVersion.VERSION_17 // Compatibilidad de la fuente Java
        targetCompatibility = JavaVersion.VERSION_17 // Compatibilidad del destino Java
    }

    kotlinOptions { // Opciones de Kotlin
        jvmTarget = JavaVersion.VERSION_17.toString() // Versión de la máquina virtual Java (JVM) a la que se dirige
    }

    defaultConfig { // Configuración por defecto
        // TODO: Especifica tu propio ID de aplicación único (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.gastos" // ID de la aplicación
        // Puedes actualizar los siguientes valores para que coincidan con las necesidades de tu aplicación.
        // Para más información, consulta: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion // SDK Mínimo (tomado de la configuración de Flutter)
        targetSdk = flutter.targetSdkVersion // SDK Objetivo (tomado de la configuración de Flutter)
        versionCode = flutter.versionCode // Código de versión de la aplicación (proporcionado por Flutter)
        versionName = flutter.versionName // Nombre de la versión de la aplicación (proporcionado por Flutter)
    }

    buildTypes { // Tipos de construcción
        // Si el archivo keystore.properties existe, registramos una signingConfig 'release'
        // usando sus valores. Si no existe, usamos debug como fallback para seguir
        // permitiendo builds locales.
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfigs.create("release") {
                    keyAlias = keystoreProperties.getProperty("keyAlias")
                    keyPassword = keystoreProperties.getProperty("keyPassword")
                    // Resolve file path relative to the Android project root (android/)
                    storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                    storePassword = keystoreProperties.getProperty("storePassword")
                }
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Fallback temporal a `debug` para evitar errores durante la evaluación
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.." // Ruta al proyecto Flutter
}
