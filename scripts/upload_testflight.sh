#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
PROJECT_PATH="$PROJECT_DIR/Floatdoro.xcodeproj"
EXPORT_OPTIONS="$PROJECT_DIR/Resources/ExportOptions-AppStore.plist"

usage() {
    cat <<'EOF'
Usage:
  upload_testflight.sh [--xcode-session] <marketing-version> <build-number>
  upload_testflight.sh --auth-check

API key authentication is the default and requires:
  APPLE_API_KEY_ID
  APPLE_API_ISSUER_ID
  APPLE_API_PRIVATE_KEY_PATH

Use --xcode-session only for an intentional interactive fallback to the Apple
Account saved in Xcode. --auth-check validates the API key without archiving or
uploading a build.
EOF
}

AUTH_CHECK_ONLY=0
USE_XCODE_SESSION=0

while (( $# > 0 )); do
    case "$1" in
        --auth-check)
            AUTH_CHECK_ONLY=1
            shift
            ;;
        --xcode-session)
            USE_XCODE_SESSION=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --*)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
        *)
            break
            ;;
    esac
done

if (( AUTH_CHECK_ONLY && USE_XCODE_SESSION )); then
    echo "--auth-check requires App Store Connect API key authentication." >&2
    exit 2
fi

if (( AUTH_CHECK_ONLY )); then
    if (( $# != 0 )); then
        usage >&2
        exit 2
    fi
else
    if (( $# != 2 )); then
        usage >&2
        exit 2
    fi
fi

VERSION=${1:-}
BUILD_NUMBER=${2:-}

AUTH_ARGS=()
ALTOOL_AUTH_ARGS=()
APPLE_API_AUTH_VALUES=(
    "${APPLE_API_KEY_ID:-}"
    "${APPLE_API_ISSUER_ID:-}"
    "${APPLE_API_PRIVATE_KEY_PATH:-}"
)

set_auth_value_count=0
for auth_value in "${APPLE_API_AUTH_VALUES[@]}"; do
    [[ -n "$auth_value" ]] && ((set_auth_value_count += 1))
done

if ((set_auth_value_count > 0 && set_auth_value_count < 3)); then
    echo "Set APPLE_API_KEY_ID, APPLE_API_ISSUER_ID, and APPLE_API_PRIVATE_KEY_PATH together." >&2
    exit 1
fi

if (( USE_XCODE_SESSION && set_auth_value_count > 0 )); then
    echo "Do not combine --xcode-session with App Store Connect API key variables." >&2
    exit 2
fi

if (( !USE_XCODE_SESSION && set_auth_value_count == 0 )); then
    echo "App Store Connect API key is not configured." >&2
    echo "Set APPLE_API_KEY_ID, APPLE_API_ISSUER_ID, and APPLE_API_PRIVATE_KEY_PATH," >&2
    echo "or pass --xcode-session for an intentional interactive fallback." >&2
    exit 2
fi

if ((set_auth_value_count == 3)); then
    if [[ ! -f "$APPLE_API_PRIVATE_KEY_PATH" ]]; then
        echo "App Store Connect API private key not found: $APPLE_API_PRIVATE_KEY_PATH" >&2
        exit 1
    fi

    private_key_mode=$(stat -f '%Lp' "$APPLE_API_PRIVATE_KEY_PATH")
    if [[ "$private_key_mode" != "600" && "$private_key_mode" != "400" ]]; then
        echo "App Store Connect API private key must be owner-readable only (mode 600 or 400): $APPLE_API_PRIVATE_KEY_PATH" >&2
        exit 1
    fi

    private_key_owner=$(stat -f '%Su' "$APPLE_API_PRIVATE_KEY_PATH")
    if [[ "$private_key_owner" != "$(id -un)" ]]; then
        echo "App Store Connect API private key must be owned by the current user: $APPLE_API_PRIVATE_KEY_PATH" >&2
        exit 1
    fi

    AUTH_ARGS=(
        -authenticationKeyPath "$APPLE_API_PRIVATE_KEY_PATH"
        -authenticationKeyID "$APPLE_API_KEY_ID"
        -authenticationKeyIssuerID "$APPLE_API_ISSUER_ID"
    )
    ALTOOL_AUTH_ARGS=(
        --api-key "$APPLE_API_KEY_ID"
        --api-issuer "$APPLE_API_ISSUER_ID"
        --p8-file-path "$APPLE_API_PRIVATE_KEY_PATH"
    )
    echo "Using App Store Connect API key authentication."
else
    echo "Using the Apple Account session saved in Xcode."
fi

if (( AUTH_CHECK_ONLY )); then
    echo "Checking App Store Connect API key authentication..."
    xcrun altool --list-providers "${ALTOOL_AUTH_ARGS[@]}" >/dev/null
    echo "App Store Connect API key authentication succeeded."
    exit 0
fi

if [[ ! "$VERSION" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]]; then
    echo "Invalid marketing version: $VERSION" >&2
    exit 1
fi

if [[ ! "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
    echo "Invalid build number: $BUILD_NUMBER" >&2
    exit 1
fi

cd "$PROJECT_DIR"
"$SCRIPT_DIR/preflight_release.sh" "$VERSION" "$BUILD_NUMBER"

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
    "${AUTH_ARGS[@]}" \
    -allowProvisioningUpdates \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    archive

xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    "${AUTH_ARGS[@]}" \
    -allowProvisioningUpdates

echo "$ARCHIVE_PATH"
