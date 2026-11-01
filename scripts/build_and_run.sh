#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RUN_ROOT="${HOME}/Library/Application Support/ReadyCheck Development"
mkdir -p "${RUN_ROOT}"
RUN_DIR="$(mktemp -d "${RUN_ROOT}/candidate.XXXXXX")"

# Keep GUI launches in a complete, persistent bundle, separate from release staging.
READYCHECK_DIST_DIR="${RUN_DIR}" "${SCRIPT_DIR}/package_app.sh"
codesign --verify --deep --strict "${RUN_DIR}/ReadyCheck.app"
pkill -x ReadyCheckApp 2>/dev/null || true
/usr/bin/open -n "${RUN_DIR}/ReadyCheck.app"
