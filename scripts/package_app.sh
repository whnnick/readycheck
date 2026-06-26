#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${REPO_ROOT}/.build"
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
VERSION="0.1.39"

cd "${REPO_ROOT}"
mkdir -p "${BUILD_DIR}/module-cache"
export CLANG_MODULE_CACHE_PATH="${BUILD_DIR}/module-cache"
export SWIFTPM_MODULECACHE_PATH="${BUILD_DIR}/module-cache"

swift build --disable-sandbox -c release --product ReadyCheckApp

rm -rf "${APP_DIR}"
mkdir -p "${DIST_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"
cp "${EXECUTABLE_SOURCE}" "${EXECUTABLE_TARGET}"
chmod +x "${EXECUTABLE_TARGET}"

generate_icon() {
    local icon_script
    icon_script="$(mktemp "${BUILD_DIR}/readycheck-icon.XXXXXX.swift")"

    cat > "${icon_script}" <<'SWIFT'
import AppKit

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

NSColor.clear.setFill()
NSRect(origin: .zero, size: size).fill()

let outerRect = NSRect(x: 64, y: 64, width: 896, height: 896)
let outerPath = NSBezierPath(roundedRect: outerRect, xRadius: 218, yRadius: 218)
NSGradient(colors: [
    NSColor(calibratedRed: 0.08, green: 0.34, blue: 0.82, alpha: 1),
    NSColor(calibratedRed: 0.10, green: 0.72, blue: 0.82, alpha: 1)
])?.draw(in: outerPath, angle: -42)

NSColor.white.withAlphaComponent(0.28).setStroke()
outerPath.lineWidth = 18
outerPath.stroke()

let glassRect = NSRect(x: 150, y: 176, width: 724, height: 672)
let glassPath = NSBezierPath(roundedRect: glassRect, xRadius: 156, yRadius: 156)
NSColor.white.withAlphaComponent(0.16).setFill()
glassPath.fill()

NSColor.white.withAlphaComponent(0.34).setStroke()
glassPath.lineWidth = 10
glassPath.stroke()

if let symbol = NSImage(systemSymbolName: "gauge.with.dots.needle.67percent", accessibilityDescription: nil) {
    symbol.isTemplate = true
    NSColor.white.set()
    symbol.draw(
        in: NSRect(x: 250, y: 266, width: 524, height: 524),
        from: .zero,
        operation: .sourceOver,
        fraction: 0.96
    )
} else {
    let text = "RC" as NSString
    text.draw(
        in: NSRect(x: 0, y: 386, width: 1024, height: 260),
        withAttributes: [
            .font: NSFont.systemFont(ofSize: 220, weight: .bold),
            .foregroundColor: NSColor.white,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                return style
            }()
        ]
    )
}

image.unlockFocus()

guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to render ReadyCheck app icon")
}

try pngData.write(to: outputURL)
SWIFT

    swift "${icon_script}" "${ICON_SOURCE}"
    rm -f "${icon_script}"

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
codesign --force --deep --sign - --no-strict "${APP_DIR}" >/dev/null
xattr -cr "${APP_DIR}"

echo "Packaged ${APP_DIR}"
