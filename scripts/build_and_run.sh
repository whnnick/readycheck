#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RUN_DIR="${REPO_ROOT}/.build/run"

# Keep GUI launches in a complete, persistent bundle, separate from release staging.
pkill -x ReadyCheckApp 2>/dev/null || true
READYCHECK_DIST_DIR="${RUN_DIR}" "${SCRIPT_DIR}/package_app.sh"
codesign --verify --deep --strict "${RUN_DIR}/ReadyCheck.app"
/usr/bin/open -n "${RUN_DIR}/ReadyCheck.app"
