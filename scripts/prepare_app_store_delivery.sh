#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
VERSION=${1:-}
OUTPUT_DIR=${2:-}

if [[ -z "$VERSION" || -z "$OUTPUT_DIR" ]]; then
    echo "Usage: $0 <marketing-version> <empty-output-directory>" >&2
    exit 2
fi

if [[ ! "$VERSION" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]]; then
    echo "Invalid marketing version: $VERSION" >&2
    exit 2
fi

if [[ -e "$OUTPUT_DIR" ]] && [[ -n "$(find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
    echo "Output directory must be empty: $OUTPUT_DIR" >&2
    exit 1
fi

METADATA_SOURCE="$PROJECT_DIR/app-store/metadata"
RELEASE_NOTES_SOURCE="$PROJECT_DIR/app-store/release-notes/$VERSION"
METADATA_OUTPUT="$OUTPUT_DIR/metadata"

for locale in en-US ru; do
    for filename in name subtitle description keywords; do
        source_path="$METADATA_SOURCE/$locale/$filename.txt"
        [[ -s "$source_path" ]] || {
            echo "Missing App Store metadata: $source_path" >&2
            exit 1
        }
    done

    [[ -s "$METADATA_SOURCE/$locale/promotional-text.txt" ]] || {
        echo "Missing App Store promotional text for $locale." >&2
        exit 1
    }
    [[ -s "$RELEASE_NOTES_SOURCE/$locale.txt" ]] || {
        echo "Missing App Store release notes for $locale: $VERSION" >&2
        exit 1
    }
done

[[ -s "$METADATA_SOURCE/en-US/review-notes.txt" ]] || {
    echo "Missing App Store review notes." >&2
    exit 1
}

mkdir -p "$METADATA_OUTPUT/review_information"

for locale in en-US ru; do
    locale_output="$METADATA_OUTPUT/$locale"
    mkdir -p "$locale_output"

    cp "$METADATA_SOURCE/$locale/name.txt" "$locale_output/name.txt"
    cp "$METADATA_SOURCE/$locale/subtitle.txt" "$locale_output/subtitle.txt"
    cp "$METADATA_SOURCE/$locale/description.txt" "$locale_output/description.txt"
    cp "$METADATA_SOURCE/$locale/keywords.txt" "$locale_output/keywords.txt"
    cp "$METADATA_SOURCE/$locale/promotional-text.txt" "$locale_output/promotional_text.txt"
    cp "$RELEASE_NOTES_SOURCE/$locale.txt" "$locale_output/release_notes.txt"

    print -r -- "https://drenderyga-del.github.io/floatdoro/privacy.html" > "$locale_output/privacy_url.txt"
    print -r -- "https://drenderyga-del.github.io/floatdoro/support.html" > "$locale_output/support_url.txt"
    print -r -- "https://drenderyga-del.github.io/floatdoro/" > "$locale_output/marketing_url.txt"
done

cp "$METADATA_SOURCE/en-US/review-notes.txt" "$METADATA_OUTPUT/review_information/notes.txt"
print -r -- "2026 drenderyga-del" > "$METADATA_OUTPUT/copyright.txt"
print -r -- "Productivity" > "$METADATA_OUTPUT/primary_category.txt"
print -r -- "Utilities" > "$METADATA_OUTPUT/secondary_category.txt"

echo "$METADATA_OUTPUT"
