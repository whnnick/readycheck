#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERSION="0.1.77"

if [[ "${REPO_ROOT}" == */.worktrees/* ]]; then
    DEFAULT_DIST_DIR="$(cd "${REPO_ROOT}/../.." && pwd)/dist"
else
    DEFAULT_DIST_DIR="${REPO_ROOT}/dist"
fi

DIST_DIR="${READYCHECK_DIST_DIR:-${DEFAULT_DIST_DIR}}"
DMG_PATH="${DIST_DIR}/ReadyCheck-${VERSION}-macos.dmg"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/readycheck-dmg.XXXXXX")"
BUILD_DIST_DIR="${STAGING_DIR}/build"
SIGNED_APP_DIR="${BUILD_DIST_DIR}/ReadyCheck.app"
STAGED_DMG_PATH="${STAGING_DIR}/ReadyCheck-${VERSION}-macos.dmg"

cleanup() {
    rm -rf "${STAGING_DIR}"
}
trap cleanup EXIT

mkdir -p "${DIST_DIR}"
find "${DIST_DIR}" -maxdepth 1 -type f \( -name "ReadyCheck-*-macos*.dmg" -o -name ".DS_Store" \) -delete
find "${DIST_DIR}" -maxdepth 1 -type d -name "ReadyCheck*.app" -exec rm -rf {} +

READYCHECK_DIST_DIR="${BUILD_DIST_DIR}" \
READYCHECK_REQUIRE_STABLE_SIGNING=1 \
    "${SCRIPT_DIR}/package_app.sh"

mkdir -p "${STAGING_DIR}/ReadyCheck"
cp -R "${SIGNED_APP_DIR}" "${STAGING_DIR}/ReadyCheck/ReadyCheck.app"

hdiutil create \
    -volname "ReadyCheck" \
    -srcfolder "${STAGING_DIR}/ReadyCheck" \
    -format UDZO \
    -ov \
    "${STAGED_DMG_PATH}" >/dev/null

hdiutil imageinfo "${STAGED_DMG_PATH}" >/dev/null
find "${DIST_DIR}" -maxdepth 1 -type d -name "ReadyCheck*.app" -exec rm -rf {} +
find "${DIST_DIR}" -maxdepth 1 -type f -name "ReadyCheck-*-macos*.dmg" -delete
mv "${STAGED_DMG_PATH}" "${DMG_PATH}"
rm -f "${DIST_DIR}/.DS_Store"
echo "Packaged ${DMG_PATH}"
