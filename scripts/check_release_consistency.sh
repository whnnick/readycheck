#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

swift_version="$(sed -n 's/.*public static let version = "\([^"]*\)".*/\1/p' Sources/ReadyCheckCore/ReadyCheckCore.swift)"
swift_test_version="$(sed -n 's/.*XCTAssertEqual(ReadyCheckCore.version, "\([^"]*\)").*/\1/p' Tests/ReadyCheckCoreTests/ScaffoldTests.swift)"
app_version="$(sed -n 's/^VERSION="\([^"]*\)"/\1/p' scripts/package_app.sh)"
dmg_version="$(sed -n 's/^VERSION="\([^"]*\)"/\1/p' scripts/package_dmg.sh)"
windows_version="$(node -p "require('./apps/windows/package.json').version")"
windows_lock_version="$(node -p "require('./apps/windows/package-lock.json').version")"

if [[ -z "${swift_version}" ]]; then
    echo "Unable to read ReadyCheckCore.version" >&2
    exit 1
fi

for entry in \
    "ScaffoldTests.swift:${swift_test_version}" \
    "package_app.sh:${app_version}" \
    "package_dmg.sh:${dmg_version}" \
    "apps/windows/package.json:${windows_version}" \
    "apps/windows/package-lock.json:${windows_lock_version}"; do
    name="${entry%%:*}"
    value="${entry#*:}"
    if [[ "${value}" != "${swift_version}" ]]; then
        echo "Version mismatch: ${name}=${value}, expected ${swift_version}" >&2
        exit 1
    fi
done

required_references=(
    "README.md:ReadyCheck-${swift_version}-macos.dmg"
    "README.md:ReadyCheck-${swift_version}-windows-x64-portable.zip"
    "README.zh-CN.md:ReadyCheck-${swift_version}-macos.dmg"
    "README.zh-CN.md:ReadyCheck-${swift_version}-windows-x64-portable.zip"
    "CHANGELOG.md:## ${swift_version} -"
    "CHANGELOG.zh-CN.md:## ${swift_version} -"
)

for entry in "${required_references[@]}"; do
    file="${entry%%:*}"
    pattern="${entry#*:}"
    if ! grep -Fq "${pattern}" "${file}"; then
        echo "Missing release reference in ${file}: ${pattern}" >&2
        exit 1
    fi
done

echo "Release version references are consistent: ${swift_version}"
