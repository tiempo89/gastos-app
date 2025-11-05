plugins {
    id("com.android.application") // ID del complemento para una aplicación Android
    id("kotlin-android") // ID del complemento para usar Kotlin en Android
    // El complemento de Gradle de Flutter debe aplicarse después de los complementos de Gradle de Android y Kotlin.
    id("dev.flutter.flutter-gradle-plugin") // ID del complemento de Gradle de Flutter
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
        release { // Tipo de construcción de lanzamiento (release)
            // TODO: Agrega tu propia configuración de firma para la construcción de lanzamiento.
            // Firmando con las claves de depuración por ahora, para que `flutter run --release` funcione.
            signingConfig = signingConfigs.getByName("prueba") // Configuración de firma. Nota: "prueba" es un nombre no estándar, generalmente es "debug" o un nombre personalizado para release.
        }
    }
}

flutter {
    source = "../.." // Ruta al proyecto Flutter
}
