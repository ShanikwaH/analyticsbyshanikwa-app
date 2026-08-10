#!/usr/bin/env bash
# Who signed the app bundle? Run this before every Play upload.
#
#   bash tools/check_signing.sh
#
# "Android Debug" means Play will reject it. You want your own CN.
set -uo pipefail

AAB="build/app/outputs/bundle/release/app-release.aab"
JAVA_HOME="${JAVA_HOME:-C:/Users/nikki/jdk-17}"
KEYTOOL="$JAVA_HOME/bin/keytool"

[ -f "$AAB" ] || { echo "No bundle at $AAB — run: flutter build appbundle"; exit 1; }

echo "bundle : $AAB  ($(du -h "$AAB" | cut -f1))"
echo

cert=$(unzip -p "$AAB" 'META-INF/*.RSA' 2>/dev/null | "$KEYTOOL" -printcert 2>/dev/null)
if [ -z "$cert" ]; then
  echo "Could not read a signing certificate. The bundle may be unsigned."
  exit 1
fi

echo "$cert" | grep -E "Owner:|Valid from:|SHA256:" | sed 's/^/  /'
echo

if echo "$cert" | grep -q "CN=Android Debug"; then
  cat <<'EOF'
DEBUG SIGNED — Google Play will reject this.

  android/key.properties is missing or incomplete. Copy
  android/key.properties.example to android/key.properties, fill it in, then
  rebuild with: flutter build appbundle
EOF
  exit 1
fi

echo "Signed with a real key. Check the Owner line above is you before uploading."

# Play requires the key to outlive 22 Oct 2033.
if echo "$cert" | grep -qE "Valid from:.*until: [A-Za-z]{3} [A-Za-z]{3} [0-9 ]{2} [0-9:]{8} [A-Z]{3,4} (20[0-2][0-9]|203[0-2])"; then
  echo "WARNING: this certificate may expire before Play's 2033 minimum. Check the Valid line."
fi
