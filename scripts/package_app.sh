#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
APP_DIR="$PROJECT_DIR/outputs/Floatdoro.app"
CONTENTS_DIR="$APP_DIR/Contents"
VERSION=${1:-1.0.0}
BUILD_NUMBER=${MACOS_BUILD_NUMBER:-1}

cd "$PROJECT_DIR"
swift build -c release

if [[ -d "$APP_DIR" ]]; then
    rm -rf "$APP_DIR"
fi

mkdir -p "$PROJECT_DIR/outputs"
mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources"
cp "$PROJECT_DIR/.build/release/Floatdoro" "$CONTENTS_DIR/MacOS/Floatdoro"
cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$PROJECT_DIR/Resources/PrivacyInfo.xcprivacy" "$CONTENTS_DIR/Resources/PrivacyInfo.xcprivacy"

/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable Floatdoro" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier io.github.drenderyga-del.floatdoro" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName Floatdoro" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :LSMinimumSystemVersion 14.0" "$CONTENTS_DIR/Info.plist"

swift "$PROJECT_DIR/scripts/render_icon.swift" \
    "$PROJECT_DIR/Resources/AppIcon.png" \
    "$CONTENTS_DIR/Resources/AppIcon.icns"

chmod +x "$CONTENTS_DIR/MacOS/Floatdoro"

if [[ -n "${MACOS_SIGNING_IDENTITY:-}" ]]; then
    codesign \
        --force \
        --options runtime \
        --timestamp \
        --sign "$MACOS_SIGNING_IDENTITY" \
        "$APP_DIR"
else
    codesign --force --sign - "$APP_DIR"
fi

codesign --verify --deep --strict --verbose=2 "$APP_DIR"

echo "$APP_DIR"
