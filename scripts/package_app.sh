#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${READYCHECK_BUILD_DIR:-${REPO_ROOT}/.build}"
if [[ "${REPO_ROOT}" == */.worktrees/* ]]; then
    DEFAULT_DIST_DIR="$(cd "${REPO_ROOT}/../.." && pwd)/dist"
else
    DEFAULT_DIST_DIR="${REPO_ROOT}/dist"
fi
DIST_DIR="${READYCHECK_DIST_DIR:-${DEFAULT_DIST_DIR}}"
APP_DIR="${DIST_DIR}/ReadyCheck.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
EXECUTABLE_SOURCE="${BUILD_DIR}/release/ReadyCheckApp"
EXECUTABLE_TARGET="${MACOS_DIR}/ReadyCheckApp"
ICONSET_DIR="${BUILD_DIR}/ReadyCheck.iconset"
ICON_SOURCE="${BUILD_DIR}/ReadyCheckIcon1024.png"
ICON_TARGET="${RESOURCES_DIR}/ReadyCheck.icns"
VERSION="0.1.132"
PREVIEW_SIGNING_IDENTITY="ReadyCheck Preview Signing"

resolve_signing_identity() {
    if [[ -n "${READYCHECK_SIGNING_IDENTITY:-}" ]]; then
        printf '%s' "${READYCHECK_SIGNING_IDENTITY}"
        return
    fi

    if security find-identity -p codesigning -v 2>/dev/null | grep -Fq "\"${PREVIEW_SIGNING_IDENTITY}\""; then
        printf '%s' "${PREVIEW_SIGNING_IDENTITY}"
        return
    fi

    printf '%s' "-"
}

cd "${REPO_ROOT}"
mkdir -p "${BUILD_DIR}/module-cache"
export CLANG_MODULE_CACHE_PATH="${BUILD_DIR}/module-cache"
export SWIFTPM_MODULECACHE_PATH="${BUILD_DIR}/module-cache"

mkdir -p "${DIST_DIR}"
find "${DIST_DIR}" -maxdepth 1 -type d -name "ReadyCheck*.app" -exec rm -rf {} +

swift build --disable-sandbox --scratch-path "${BUILD_DIR}" -c release \
    -debug-info-format none --product ReadyCheckApp

mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"
cp "${EXECUTABLE_SOURCE}" "${EXECUTABLE_TARGET}"
chmod +x "${EXECUTABLE_TARGET}"

generate_icon() {
    swift "${SCRIPT_DIR}/render_app_icon.swift" "${ICON_SOURCE}"

    rm -rf "${ICONSET_DIR}"
    mkdir -p "${ICONSET_DIR}"
    sips -z 16 16 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_16x16.png" >/dev/null
    sips -z 32 32 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_16x16@2x.png" >/dev/null
    sips -z 32 32 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_32x32.png" >/dev/null
    sips -z 64 64 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_32x32@2x.png" >/dev/null
    sips -z 128 128 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_128x128.png" >/dev/null
    sips -z 256 256 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_128x128@2x.png" >/dev/null
    sips -z 256 256 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_256x256.png" >/dev/null
    sips -z 512 512 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_256x256@2x.png" >/dev/null
    sips -z 512 512 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_512x512.png" >/dev/null
    sips -z 1024 1024 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_512x512@2x.png" >/dev/null
    if ! iconutil -c icns "${ICONSET_DIR}" -o "${ICON_TARGET}"; then
        cp "${ICON_SOURCE}" "${RESOURCES_DIR}/ReadyCheck.png"
    fi
}

generate_icon

cat > "${CONTENTS_DIR}/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>ReadyCheck</string>
    <key>CFBundleExecutable</key>
    <string>ReadyCheckApp</string>
    <key>CFBundleIdentifier</key>
    <string>com.readycheck.app</string>
    <key>CFBundleIconFile</key>
    <string>ReadyCheck</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>ReadyCheck</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>__VERSION__</string>
    <key>CFBundleVersion</key>
    <string>__VERSION__</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 ReadyCheck.</string>
</dict>
</plist>
PLIST

perl -0pi -e "s/__VERSION__/${VERSION}/g" "${CONTENTS_DIR}/Info.plist"
if [[ ! -f "${ICON_TARGET}" ]]; then
    cp "${ICON_SOURCE}" "${RESOURCES_DIR}/ReadyCheck.png"
fi
printf "APPL????" > "${CONTENTS_DIR}/PkgInfo"

plutil -lint "${CONTENTS_DIR}/Info.plist"
touch "${APP_DIR}" "${CONTENTS_DIR}" "${RESOURCES_DIR}"
xattr -cr "${APP_DIR}"
SIGNING_IDENTITY="$(resolve_signing_identity)"
if [[ "${SIGNING_IDENTITY}" == "-" ]]; then
    if [[ "${READYCHECK_REQUIRE_STABLE_SIGNING:-0}" == "1" ]]; then
        echo "Error: a stable signing identity is required, but none was found." >&2
        echo "Install '${PREVIEW_SIGNING_IDENTITY}' or set READYCHECK_SIGNING_IDENTITY." >&2
        exit 1
    fi
    echo "Warning: no stable signing identity found; using ad-hoc signing." >&2
    codesign --force --deep --sign - --no-strict "${APP_DIR}" >/dev/null
else
    codesign --force --deep --sign "${SIGNING_IDENTITY}" --timestamp=none --no-strict "${APP_DIR}" >/dev/null
fi
codesign --verify --deep --strict "${APP_DIR}"
xattr -cr "${APP_DIR}"
find "${DIST_DIR}" -maxdepth 1 -type d -name "ReadyCheck*.app" ! -name "ReadyCheck.app" -exec rm -rf {} +

echo "Packaged ${APP_DIR} (signing identity: ${SIGNING_IDENTITY})"
