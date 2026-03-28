#!/usr/bin/env bash
# Prints the key hash Meta expects under Facebook Login → Settings → Android.
# Add every hash for keystores you use: debug (this script’s default) + release.
#
# Meta Developer → Your app → Use cases → Facebook Login → Settings → Android
# (or Settings → Basic → scroll to Android / add platform Android).
#
# Usage:
#   ./tools/facebook_android_keyhash.sh
#   ./tools/facebook_android_keyhash.sh /path/to/release.keystore myAlias
#   # then enter store password when prompted, or:
#   STORE_PASS=secret ./tools/facebook_android_keyhash.sh /path/to/release.keystore myAlias

set -euo pipefail

KEYTOOL="${KEYTOOL:-}"
if [[ -z "$KEYTOOL" ]]; then
  if [[ -x "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" ]]; then
    KEYTOOL="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"
  elif command -v keytool >/dev/null 2>&1; then
    KEYTOOL="$(command -v keytool)"
  else
    echo "keytool not found. Set KEYTOOL=/path/to/keytool or install a JDK." >&2
    exit 1
  fi
fi

if [[ "${1:-}" == "" ]]; then
  KS="${HOME}/.android/debug.keystore"
  ALIAS="androiddebugkey"
  SP="${STORE_PASS:-android}"
  echo "# Debug keystore: $KS" >&2
  "$KEYTOOL" -exportcert -alias "$ALIAS" -keystore "$KS" -storepass "$SP" 2>/dev/null \
    | openssl sha1 -binary | openssl base64
else
  KS="$1"
  ALIAS="${2:-upload}"
  if [[ -z "${STORE_PASS:-}" ]]; then
    echo "Enter keystore password (or set STORE_PASS):" >&2
    read -rs SP
  else
    SP="$STORE_PASS"
  fi
  "$KEYTOOL" -exportcert -alias "$ALIAS" -keystore "$KS" -storepass "$SP" 2>/dev/null \
    | openssl sha1 -binary | openssl base64
fi

echo
