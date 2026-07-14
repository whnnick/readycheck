#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WINDOWS_DIR="$ROOT_DIR/apps/windows"
BUILD_DIST_DIR="$ROOT_DIR/dist/windows"
if [[ "${ROOT_DIR}" == */.worktrees/* ]]; then
  PUBLISH_DIST_DIR="$(cd "${ROOT_DIR}/../.." && pwd)/dist/windows"
else
  PUBLISH_DIST_DIR="${BUILD_DIST_DIR}"
fi

cd "$WINDOWS_DIR"
npm ci
npm run check
npm run smoke
npm run smoke:ui
npm run package:win

cd "$ROOT_DIR"
VERSION="$(node -p "require('./apps/windows/package.json').version")"
ZIP_NAME="ReadyCheck-${VERSION}-windows-x64-portable.zip"
ZIP_PATH="$BUILD_DIST_DIR/$ZIP_NAME"
APP_DIR="$BUILD_DIST_DIR/ReadyCheck-win32-x64"

find "$BUILD_DIST_DIR" -maxdepth 1 -type f \( -name "ReadyCheck-*-windows-x64-portable*.zip" -o -name ".DS_Store" \) -delete
(
  cd "$BUILD_DIST_DIR"
  zip -r -X "$ZIP_NAME" ReadyCheck-win32-x64
)

unzip -t "$ZIP_PATH" >/dev/null
if unzip -Z1 "$ZIP_PATH" | grep -Eq '(^|/)\._'; then
  echo "Unexpected macOS AppleDouble metadata found in $ZIP_PATH" >&2
  exit 1
fi
find "$BUILD_DIST_DIR" -maxdepth 1 -type f -name ".DS_Store" -delete
rm -rf "$APP_DIR"

if [[ "$PUBLISH_DIST_DIR" != "$BUILD_DIST_DIR" ]]; then
  mkdir -p "$PUBLISH_DIST_DIR"
  find "$PUBLISH_DIST_DIR" -maxdepth 1 -type f -name "ReadyCheck-*-windows-x64-portable*.zip" -delete
  mv "$ZIP_PATH" "$PUBLISH_DIST_DIR/$ZIP_NAME"
  rmdir "$BUILD_DIST_DIR" 2>/dev/null || true
  rmdir "$ROOT_DIR/dist" 2>/dev/null || true
  ZIP_PATH="$PUBLISH_DIST_DIR/$ZIP_NAME"
fi

echo "Windows portable package written to $ZIP_PATH"
