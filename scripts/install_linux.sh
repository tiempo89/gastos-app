#!/bin/bash

# Este script instala la aplicación Gastos para el usuario actual en Linux

APP_NAME="Gastos"
EXECUTABLE_NAME="gastos"
INSTALL_DIR="$HOME/.local/share/gastos"
DESKTOP_FILE="$HOME/.local/share/applications/gastos.desktop"
BUILD_DIR="build/linux/x64/release/bundle"
ICON_SOURCE="assets/icon/icon.png"

echo "📦 Instalando $APP_NAME..."

# 1. Verificar si existe la build
if [ ! -d "$BUILD_DIR" ]; then
    echo "❌ Error: No se encontró la versión compilada en $BUILD_DIR"
    echo "   Por favor ejecuta primero: flutter build linux --release"
    exit 1
fi

# 2. Crear directorios necesarios
mkdir -p "$INSTALL_DIR"
mkdir -p "$(dirname "$DESKTOP_FILE")"

# 3. Copiar los archivos de la aplicación (sobrescribiendo si existen)
echo "📂 Copiando archivos a $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"/*
cp -r "$BUILD_DIR"/* "$INSTALL_DIR/"

# 4. Copiar el icono si existe
if [ -f "$ICON_SOURCE" ]; then
    mkdir -p "$INSTALL_DIR/assets"
    cp "$ICON_SOURCE" "$INSTALL_DIR/assets/icon.png"
    ICON_PATH="$INSTALL_DIR/assets/icon.png"
else
    echo "⚠️ Advertencia: No se encontró icono en $ICON_SOURCE, usando icono por defecto"
    ICON_PATH="utilities-terminal" # Fallback icon
fi

# 5. Crear el archivo .desktop
echo "📝 Creando acceso directo en el menú..."
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Name=$APP_NAME
Comment=Aplicación de gestión de gastos personales
Exec=$INSTALL_DIR/$EXECUTABLE_NAME
Icon=$ICON_PATH
Terminal=false
Type=Application
Categories=Utility;Finance;
EOF

# 6. Dar permisos de ejecución
chmod +x "$INSTALL_DIR/$EXECUTABLE_NAME"
chmod +x "$DESKTOP_FILE"

echo "✅ ¡Instalación completada con éxito!"
echo "   Ahora deberías ver '$APP_NAME' en tu menú de aplicaciones."
echo "   Si no aparece inmediatamente, intenta cerrar e iniciar sesión."
