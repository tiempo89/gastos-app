# 💰 Gastos App

**Gastos** es una aplicación de gestión financiera personal moderna, rápida y segura, desarrollada en **Flutter**. Diseñada para ofrecer un control total sobre tus finanzas personales sin depender de servicios en la nube, garantizando que tus datos permanezcan siempre en tu dispositivo.

## ✨ Características Principales

### 📊 Gestión de Finanzas
- **Movimientos Detallados**: Registra ingresos y egresos especificando fecha, concepto, monto y medio de pago (Efectivo o Digital).
- **Saldos Independientes**: Controla tus saldos de **Efectivo** y **Cuentas Digitales** por separado, con ajuste de saldos iniciales en cualquier momento.
- **Resumen en Tiempo Real**: Visualización inmediata del saldo total y el desglose por tipo de cuenta.

### 👤 Multi-Perfil
- **Perfiles Ilimitados**: Crea múltiples perfiles para gestionar diferentes aspectos de tu vida (ej. Personal, Trabajo, Viaje, Casa) o para múltiples usuarios en el mismo dispositivo.
- **Aislamiento de Datos**: Cada perfil mantiene sus propios movimientos, saldos y configuraciones de forma independiente mediante cajas de Hive separadas.
- **Gestión Completa**: Crea, edita, cambia y elimina perfiles fácilmente desde el menú lateral.

### 🔍 Filtrado y Ordenamiento Avanzado
Organiza y analiza tus movimientos con potentes herramientas:
- **Periodo**: Filtra por Hoy, Este Mes, Este Año o un rango de fechas personalizado.
- **Tipo de Operación**: Visualiza solo Ingresos, Egresos o Todos.
- **Medio de Pago**: Filtra por movimientos en Efectivo o Digital.
- **Ordenamiento**: Ordena tus transacciones por Fecha (asc/desc), Monto o Alfabéticamente.

### 📤 Exportación y Respaldos
- **Reportes PDF Editables**: Genera reportes profesionales en PDF que incluyen un resumen de saldos y el listado de movimientos filtrados. ¡Incluye opciones para editar el contenido antes de guardar!
- **Backups JSON**: Exporta e importa los datos completos de un perfil en formato JSON para copias de seguridad o migración entre dispositivos.

### 🎨 Experiencia de Usuario (UX)
- **Tema Claro y Oscuro**: Interfaz adaptable a tus preferencias visuales.
- **Diseño Responsivo**: Optimizada para diferentes tamaños de pantalla.
- **Interfaz Intuitiva**: Formularios sencillos, validaciones en tiempo real y feedback visual.

---

## 🛠️ Tecnologías Utilizadas

- **Framework**: [Flutter](https://flutter.dev/) (SDK >=3.0.0)
- **Lenguaje**: Dart
- **Gestión de Estado**: `provider` para una arquitectura reactiva y desacoplada.
- **Base de Datos Local**: `hive` y `hive_flutter` para almacenamiento NoSQL rápido y ligero.
- **Internacionalización**: `intl` para formateo de monedas y fechas.
- **PDF**: `pdf`, `printing` y `flutter_pdfview` para generación y visualización de reportes.
- **Archivos**: `file_picker` y `open_file` para gestión de backups y archivos exportados.

---

## 📂 Estructura del Proyecto

```
lib/
├── models/         # Modelos de datos (Movement, Hive Adapters)
├── providers/      # Lógica de negocio y estado (BalanceProvider)
├── screens/        # Pantallas de la aplicación (Movements, Filters)
├── widgets/        # Componentes reutilizables de UI
├── utils/          # Utilidades y formateadores
└── main.dart       # Punto de entrada
```

---

## 🚀 Instalación y Ejecución

1.  **Clonar el repositorio**:
    ```bash
    git clone <url-del-repo>
    cd gastos
    ```

2.  **Instalar dependencias**:
    ```bash
    flutter pub get
    ```

3.  **Ejecutar la aplicación**:
    ```bash
    flutter run
    ```

4.  **Generar adaptadores de Hive** (solo si modificas los modelos):
    ```bash
    flutter pub run build_runner build
    ```

---

## 🔐 Generación de Builds (Android)

Para generar una APK/AAB firmada para distribución (release), es necesario configurar el keystore.

### Configuración Rápida

1.  Ejecuta el script incluido para generar un keystore local automáticamente:
    ```bash
    ./scripts/generate_keystore.sh
    ```
    Esto creará `android/release-keystore.jks` y `android/keystore.properties`.

2.  Verifica que estos archivos estén en `.gitignore` para no subirlos al repositorio.

3.  Construye la versión de release:
    ```bash
    flutter build apk --release
    # O para Play Store
    flutter build appbundle --release
    ```

### Configuración Manual

1.  Crea una copia de `android/keystore.properties.example` llamada `android/keystore.properties`.
2.  Genera tu keystore (`.jks`) y actualiza el archivo de propiedades con la ruta y credenciales.

> **Nota para CI/CD**: Nunca subas el keystore ni las contraseñas al repositorio. Usa "Secretos" en tu plataforma de CI para inyectar estos archivos durante el proceso de build.

---

## 🤝 Contribución

Las contribuciones son bienvenidas. Por favor, abre un issue o envía un pull request para mejoras y correcciones.
