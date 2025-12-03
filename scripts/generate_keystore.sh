#!/usr/bin/env bash
set -euo pipefail

# Simple helper to generate a local Android keystore and a corresponding
# android/keystore.properties file pointing to it.
#
# WARNING: This script writes a keystore file to the workspace. The repo's
# .gitignore already contains rules to avoid committing `*.jks` and
# `android/keystore.properties`. Do not commit your real keystore or
# credentials into version control.

KEYSTORE_PATH="android/release-keystore.jks"
# When writing the properties file (which lives under android/), make the
# storeFile path relative to that directory so Gradle resolves it correctly
# using rootProject.file(...)
KEYSTORE_FILE_PROPERTY="release-keystore.jks"
PROPERTIES_PATH="android/keystore.properties"

usage() {
  cat <<EOF
Usage: $0 [alias] [store-password] [key-password]

Example (interactive mode):
  $0

Example (automated mode):
  $0 myalias myStorePass myKeyPass

This will generate: $KEYSTORE_PATH and $PROPERTIES_PATH (ignored by git)

EOF
}

if ! command -v keytool >/dev/null 2>&1; then
  echo "Error: keytool not found in PATH (part of JDK). Install a JDK first." >&2
  exit 1
fi

if [ "$#" -eq 0 ]; then
  echo "Generating keystore (interactive)..."
  read -rp "Keystore alias (default: release): " KEY_ALIAS
  KEY_ALIAS=${KEY_ALIAS:-release}
  read -rp "Keystore store password: " -s STORE_PASS
  echo
  read -rp "Keystore key password (press enter to reuse store password): " -s KEY_PASS
  echo
  # PKCS12 keystores created by modern JDKs ignore a separate key password and
  # use the store password for the key; to avoid mismatches we always write the
  # keyPassword property matching the store password.
  KEY_PASS=${KEY_PASS:-$STORE_PASS}
  KEY_PASS=$STORE_PASS
else
  KEY_ALIAS=${1}
  STORE_PASS=${2:-changeme}
  KEY_PASS=${3:-$STORE_PASS}
  KEY_PASS=$STORE_PASS
fi

echo "alias=$KEY_ALIAS"
echo "keystore: $KEYSTORE_PATH"

mkdir -p android

if [ -f "$KEYSTORE_PATH" ]; then
  echo "Keystore already exists at $KEYSTORE_PATH — skipping generation." >&2
else
  keytool -genkeypair \
    -alias "$KEY_ALIAS" \
    -keyalg RSA -keysize 2048 \
    -validity 10000 \
    -dname "CN=Example, OU=Example, O=Example, L=City, ST=State, C=US" \
    -keystore "$KEYSTORE_PATH" \
    -storepass "$STORE_PASS" \
    -keypass "$KEY_PASS"
  echo "Keystore generated: $KEYSTORE_PATH"
fi

cat > "$PROPERTIES_PATH" <<EOF
# Local keystore for signing the release build (kept out of version control)
# The path for storeFile is interpreted relative to android/ (rootProject for the module),
# so we store only the filename here.
storeFile=$KEYSTORE_FILE_PROPERTY
storePassword=$STORE_PASS
keyAlias=$KEY_ALIAS
keyPassword=$KEY_PASS
EOF

chmod 600 "$KEYSTORE_PATH" || true
chmod 600 "$PROPERTIES_PATH" || true

echo "Wrote $PROPERTIES_PATH (and keystore). These files are ignored by .gitignore — do NOT commit them."
