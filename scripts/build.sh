#!/usr/bin/env bash
# Build Ease Mirror.app — SwiftPM + .app bundle + optional codesign.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Ease Mirror"
BUNDLE="${ROOT}/${APP_NAME}.app"
BUILD_CFG="release"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug) BUILD_CFG="debug" ;;
    --release) BUILD_CFG="release" ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
  shift
done

cd "$ROOT"

echo "=== Ease Mirror build ($BUILD_CFG) ==="

chmod +x scripts/*.sh 2>/dev/null || true
mkdir -p "${ROOT}/Resources"
bash "${ROOT}/scripts/make-app-icon.sh" 2>/dev/null || echo "Icon generation skipped"

if [[ "$BUILD_CFG" == "release" ]]; then
  swift build -c release
  BIN="${ROOT}/.build/release/EaseMirror"
  CLI="${ROOT}/.build/release/ease-mirror-cli"
else
  swift build
  BIN="${ROOT}/.build/debug/EaseMirror"
  CLI="${ROOT}/.build/debug/ease-mirror-cli"
fi

rm -rf "$BUNDLE"
mkdir -p "${BUNDLE}/Contents/MacOS"
mkdir -p "${BUNDLE}/Contents/Resources"
mkdir -p "${BUNDLE}/Contents/Resources/scripts"
if [[ -f "${ROOT}/Resources/AppIcon.icns" ]]; then
  cp "${ROOT}/Resources/AppIcon.icns" "${BUNDLE}/Contents/Resources/AppIcon.icns"
fi
if [[ -f "${ROOT}/Resources/ghost-mirror-logo-replica.png" ]]; then
  cp "${ROOT}/Resources/ghost-mirror-logo-replica.png" \
    "${BUNDLE}/Contents/Resources/ghost-mirror-logo-replica.png"
fi

cp "$BIN" "${BUNDLE}/Contents/MacOS/EaseMirror"
cp "$CLI" "${BUNDLE}/Contents/MacOS/ease-mirror-cli"
cp -R "${ROOT}/scripts/." "${BUNDLE}/Contents/Resources/scripts/"
chmod +x "${BUNDLE}/Contents/Resources/scripts/"*.sh
chmod +x "${BUNDLE}/Contents/MacOS/"*

cat >"${BUNDLE}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>EaseMirror</string>
  <key>CFBundleIdentifier</key>
  <string>com.easeaudio.easemirror</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Ease Mirror</string>
  <key>CFBundleDisplayName</key>
  <string>Ease Mirror</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

cp "${ROOT}/EaseMirror.entitlements" "${BUNDLE}/Contents/Resources/EaseMirror.entitlements"

if [[ -n "$CODESIGN_IDENTITY" ]]; then
  echo "Signing with: $CODESIGN_IDENTITY"
  codesign --force --options runtime \
    --entitlements "${ROOT}/EaseMirror.entitlements" \
    --sign "$CODESIGN_IDENTITY" \
    "${BUNDLE}/Contents/MacOS/EaseMirror" \
    "${BUNDLE}/Contents/MacOS/ease-mirror-cli"
  codesign --force --options runtime \
    --entitlements "${ROOT}/EaseMirror.entitlements" \
    --sign "$CODESIGN_IDENTITY" \
    "$BUNDLE"
  echo "Notarize manually: xcrun notarytool submit …"
else
  echo "Ad-hoc sign (dev only — set CODESIGN_IDENTITY for release)"
  codesign --force -s - \
    --entitlements "${ROOT}/EaseMirror.entitlements" \
    "${BUNDLE}/Contents/MacOS/EaseMirror" \
    "${BUNDLE}/Contents/MacOS/ease-mirror-cli"
  codesign --force -s - \
    --entitlements "${ROOT}/EaseMirror.entitlements" \
    "$BUNDLE"
fi

echo ""
echo "Built: $BUNDLE"
echo "Run:   open \"$BUNDLE\""
