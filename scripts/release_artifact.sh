#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
APP_DIR="$PROJECT_DIR/outputs/Floatdoro.app"
ARTIFACTS_DIR="$PROJECT_DIR/outputs/release"

VERSION=${1:-1.0.0}
VERSION=${VERSION#v}

if [[ ! "$VERSION" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "Invalid release version: $VERSION" >&2
    exit 1
fi

"$SCRIPT_DIR/package_app.sh" "$VERSION"

if [[ "${NOTARIZE_APP:-0}" == "1" ]]; then
    "$SCRIPT_DIR/notarize_app.sh"
fi

mkdir -p "$ARTIFACTS_DIR"
ZIP_PATH="$ARTIFACTS_DIR/Floatdoro-$VERSION-macos.zip"
CHECKSUM_PATH="$ZIP_PATH.sha256"

rm -f "$ZIP_PATH" "$CHECKSUM_PATH"
ditto -c -k --keepParent --norsrc --noextattr --noqtn --noacl "$APP_DIR" "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH" > "$CHECKSUM_PATH"

echo "$ZIP_PATH"
echo "$CHECKSUM_PATH"
