# gastos

**Gastos** es una aplicación de gestión financiera personal desarrollada en Flutter, diseñada para ofrecer un control detallado y flexible de tus ingresos y egresos. La aplicación utiliza Hive para el almacenamiento local, garantizando un rendimiento rápido y la persistencia de los datos directamente en el dispositivo.

## Características Principales

    - **Tipo**: Efectivo, Digital o Todos.
    - **Operación**: Ingresos, Egresos o Todos.
    - **Período**: Hoy, Este Mes, Este Año o un rango de fechas personalizado.
    - **Exportar a PDF**: Genera un reporte en PDF con el resumen de saldos y la lista de movimientos filtrados.
    - **Copia de Seguridad (Backup)**: Exporta los datos de un perfil a un archivo JSON para tener una copia de seguridad o para migración.
    - **Tema Claro y Oscuro**: Cambia entre modos de visualización para una mejor experiencia de usuario.
    - **Saldos Iniciales Ajustables**: Modifica los saldos iniciales de efectivo y digital en cualquier momento.

## Firma de lanzamiento (Android) 🔐

Para poder generar una APK/AAB firmada para distribución (release) debes proveer un keystore y un archivo de propiedades local con las credenciales. Por seguridad NO deben subirse estos archivos al control de versiones.

Pasos rápidos:

1. Copiar el ejemplo o generar uno localmente:
     - Opción manual: Duplica `android/keystore.properties.example` → `android/keystore.properties` y reemplaza los valores con tus credenciales reales.
     - Opción automática (recomendada para pruebas locales): usa el script incluido `scripts/generate_keystore.sh` para generar un keystore local y el archivo `android/keystore.properties` automáticamente.
2. Colocar tu archivo de keystore (p. ej. `release-keystore.jks`) en una ubicación local segura (por ejemplo en `android/` o en `~/.android/`).
3. Asegúrate de que `android/keystore.properties` apunte a la ruta correcta (`storeFile=...`).
4. Verifica que `.gitignore` incluye las entradas para no subir estos archivos (ej.: `android/keystore.properties`, `*.jks`).
5. Construir release:
     - `flutter build apk --release` (o `flutter build appbundle --release` para Play Store)

Si necesitas ayuda generando un keystore localmente, puedes usar:

```bash
keytool -genkeypair -v -keystore release-keystore.jks -alias <alias> -keyalg RSA -keysize 2048 -validity 10000
```

Mantén las credenciales y el archivo de keystore fuera del repositorio y comparte las instrucciones con las personas que necesiten firmar builds o configúralo en CI con variables seguras.

### Uso del script de ayuda (local)

En el workspace ejecuta (modo interactivo):

```bash
./scripts/generate_keystore.sh
```

O en modo automático (no interactivo) con alias/contras: 

```bash
./scripts/generate_keystore.sh myAlias myStorePass myKeyPass
```

El script generará `android/release-keystore.jks` y `android/keystore.properties`.

### Ejemplo para CI (GitHub Actions)

No guardes la clave en el repositorio. En CI provee valores desde secretos y escribe un archivo `keystore.properties` en tiempo de ejecución.

Un ejemplo de workflow (extracto):

```yaml
env:
     KEYSTORE_PATH: android/release-keystore.jks

jobs:
     build:
          runs-on: ubuntu-latest
          steps:
               - uses: actions/checkout@v4
               - name: Setup JDK
                    uses: actions/setup-java@v4
                    with:
                         distribution: 'temurin'
                         java-version: '17'
               - name: Restore keystore from secret
                    run: |
                         echo "$KEYSTORE_BASE64" | base64 --decode > $KEYSTORE_PATH
                    env:
                         KEYSTORE_BASE64: ${{ secrets.KEYSTORE_BASE64 }}
               - name: Write keystore.properties
                    run: |
                         cat > android/keystore.properties <<EOF
                         storeFile=$KEYSTORE_PATH
                         storePassword=${{ secrets.KEYSTORE_STORE_PASSWORD }}
                         keyAlias=${{ secrets.KEY_ALIAS }}
                         keyPassword=${{ secrets.KEY_PASSWORD }}
                         EOF
               - name: Build release
                    run: flutter build appbundle --release
```

En este flujo las credenciales y el archivo binario del keystore se mantienen en `secrets` y nunca se guardan en el repo.

---

## Arreglos recientes ✅

- Se corrigió un desbordamiento (RenderFlex overflow) en `lib/screens/movements_screen.dart` enlazando el formulario dentro de un `SingleChildScrollView`+`Flexible` para evitar overflow cuando aparece el teclado en pantallas pequeñas.
