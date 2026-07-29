#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
APP_DIR="$PROJECT_DIR/outputs/Pomo.app"
CONTENTS_DIR="$APP_DIR/Contents"

cd "$PROJECT_DIR"
swift build -c release

if [[ -d "$APP_DIR" ]]; then
    rm -rf "$APP_DIR"
fi

mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources"
cp "$PROJECT_DIR/.build/release/Pomo" "$CONTENTS_DIR/MacOS/Pomo"
cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

swift "$PROJECT_DIR/scripts/render_icon.swift" "$CONTENTS_DIR/Resources/AppIcon.icns"

chmod +x "$CONTENTS_DIR/MacOS/Pomo"
codesign --force --deep --sign - "$APP_DIR"

echo "$APP_DIR"
