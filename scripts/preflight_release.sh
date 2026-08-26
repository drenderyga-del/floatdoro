#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
PROJECT_PATH="$PROJECT_DIR/Floatdoro.xcodeproj"
SCHEME="Floatdoro"
VERSION=${1:-}
BUILD_NUMBER=${2:-}

cd "$PROJECT_DIR"

if [[ -z "$VERSION" || -z "$BUILD_NUMBER" ]]; then
    echo "Usage: $0 <marketing-version> <build-number>" >&2
    exit 2
fi

if [[ ! "$VERSION" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]]; then
    echo "Invalid marketing version: $VERSION" >&2
    exit 2
fi

if [[ ! "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
    echo "Invalid build number: $BUILD_NUMBER" >&2
    exit 2
fi

for required in project.yml Resources/Info.plist Resources/PrivacyInfo.xcprivacy Resources/Floatdoro.entitlements; do
    [[ -f "$required" ]] || { echo "Missing required file: $required" >&2; exit 1; }
done

plutil -lint Resources/Info.plist Resources/PrivacyInfo.xcprivacy Resources/Floatdoro.entitlements Resources/ExportOptions-AppStore.plist

echo "Running Swift Package tests..."
swift test

echo "Regenerating Xcode project..."
xcodegen generate

echo "Running Xcode tests..."
xcodebuild test \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination 'platform=macOS' \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER"

echo "Release preflight passed for Floatdoro $VERSION ($BUILD_NUMBER)."
