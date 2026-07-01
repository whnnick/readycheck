#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WINDOWS_DIR="$ROOT_DIR/apps/windows"
DIST_DIR="$ROOT_DIR/dist/windows"

cd "$WINDOWS_DIR"
npm install
npm run check
npm run smoke
npm run smoke:ui
npm run package:win

cd "$ROOT_DIR"
VERSION="$(node -p "require('./apps/windows/package.json').version")"
ZIP_NAME="ReadyCheck-${VERSION}-windows-x64-portable.zip"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"

rm -f "$ZIP_PATH"
(
  cd "$DIST_DIR"
  zip -r -X "$ZIP_NAME" ReadyCheck-win32-x64
)

unzip -t "$ZIP_PATH" >/dev/null
if unzip -Z1 "$ZIP_PATH" | grep -Eq '(^|/)\._'; then
  echo "Unexpected macOS AppleDouble metadata found in $ZIP_PATH" >&2
  exit 1
fi

echo "Windows portable package written to $ZIP_PATH"
