#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
APP_DIR="$PROJECT_DIR/outputs/Floatdoro.app"

: "${APPLE_API_KEY_ID:?APPLE_API_KEY_ID is required}"
: "${APPLE_API_ISSUER_ID:?APPLE_API_ISSUER_ID is required}"
: "${APPLE_API_PRIVATE_KEY_PATH:?APPLE_API_PRIVATE_KEY_PATH is required}"

if [[ ! -d "$APP_DIR" ]]; then
    echo "Application bundle not found: $APP_DIR" >&2
    exit 1
fi

if [[ ! -f "$APPLE_API_PRIVATE_KEY_PATH" ]]; then
    echo "App Store Connect API private key not found: $APPLE_API_PRIVATE_KEY_PATH" >&2
    exit 1
fi

TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/floatdoro-notarize.XXXXXX")
trap 'rm -rf "$TEMP_DIR"' EXIT
SUBMISSION_ZIP="$TEMP_DIR/Floatdoro.zip"

ditto -c -k --keepParent --norsrc --noextattr --noqtn --noacl \
    "$APP_DIR" \
    "$SUBMISSION_ZIP"

xcrun notarytool submit "$SUBMISSION_ZIP" \
    --key "$APPLE_API_PRIVATE_KEY_PATH" \
    --key-id "$APPLE_API_KEY_ID" \
    --issuer "$APPLE_API_ISSUER_ID" \
    --wait

xcrun stapler staple "$APP_DIR"
xcrun stapler validate "$APP_DIR"
spctl --assess --type execute --verbose=4 "$APP_DIR"

echo "$APP_DIR"
