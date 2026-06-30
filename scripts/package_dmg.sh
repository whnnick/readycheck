#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERSION="0.1.55"

if [[ "${REPO_ROOT}" == */.worktrees/* ]]; then
    DEFAULT_DIST_DIR="$(cd "${REPO_ROOT}/../.." && pwd)/dist"
else
    DEFAULT_DIST_DIR="${REPO_ROOT}/dist"
fi

DIST_DIR="${READYCHECK_DIST_DIR:-${DEFAULT_DIST_DIR}}"
APP_DIR="${DIST_DIR}/ReadyCheck.app"
DMG_PATH="${DIST_DIR}/ReadyCheck-${VERSION}-macos.dmg"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/readycheck-dmg.XXXXXX")"

cleanup() {
    rm -rf "${STAGING_DIR}"
}
trap cleanup EXIT

mkdir -p "${DIST_DIR}"
find "${DIST_DIR}" -maxdepth 1 -type f \( -name "ReadyCheck-*-macos.dmg" -o -name ".DS_Store" \) -delete

"${SCRIPT_DIR}/package_app.sh"

mkdir -p "${STAGING_DIR}/ReadyCheck"
cp -R "${APP_DIR}" "${STAGING_DIR}/ReadyCheck/ReadyCheck.app"

hdiutil create \
    -volname "ReadyCheck" \
    -srcfolder "${STAGING_DIR}/ReadyCheck" \
    -format UDZO \
    -ov \
    "${DMG_PATH}" >/dev/null

rm -f "${DIST_DIR}/.DS_Store"
hdiutil imageinfo "${DMG_PATH}" >/dev/null
echo "Packaged ${DMG_PATH}"
