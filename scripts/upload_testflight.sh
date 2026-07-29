#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
PROJECT_PATH="$PROJECT_DIR/Floatdoro.xcodeproj"
EXPORT_OPTIONS="$PROJECT_DIR/Resources/ExportOptions-AppStore.plist"

VERSION=${1:-1.0.0}
BUILD_NUMBER=${2:-1}

if [[ ! "$VERSION" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]]; then
    echo "Invalid marketing version: $VERSION" >&2
    exit 1
fi

if [[ ! "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
    echo "Invalid build number: $BUILD_NUMBER" >&2
    exit 1
fi

cd "$PROJECT_DIR"
xcodegen generate

mkdir -p "$PROJECT_DIR/outputs/store"
RUN_DIR=$(mktemp -d "$PROJECT_DIR/outputs/store/Floatdoro-${VERSION}-${BUILD_NUMBER}.XXXXXX")
ARCHIVE_PATH="$RUN_DIR/Floatdoro.xcarchive"
EXPORT_PATH="$RUN_DIR/export"

xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme Floatdoro \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    archive

xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -allowProvisioningUpdates

echo "$ARCHIVE_PATH"
