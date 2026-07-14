#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${PROJECT_DIR}/../.." && pwd)"
GIF_PATH="${REPO_ROOT}/docs/assets/readycheck-preview.gif"
CONTACT_SHEET="${TMPDIR:-/tmp}/readycheck-preview-contact-sheet.png"

for command in npm ffmpeg ffprobe rg; do
    if ! command -v "${command}" >/dev/null 2>&1; then
        echo "Required command not found: ${command}" >&2
        exit 1
    fi
done

cd "${PROJECT_DIR}"
npm run check

if [[ ! -s "${GIF_PATH}" ]]; then
    echo "README preview GIF is missing or empty: ${GIF_PATH}" >&2
    exit 1
fi

dimensions="$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "${GIF_PATH}")"
duration="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${GIF_PATH}")"

if [[ "${dimensions}" != "960x540" ]]; then
    echo "Unexpected GIF dimensions: ${dimensions}; expected 960x540" >&2
    exit 1
fi

if ! awk -v value="${duration}" 'BEGIN { exit !(value >= 5.9 && value <= 6.1) }'; then
    echo "Unexpected GIF duration: ${duration}; expected about 6 seconds" >&2
    exit 1
fi

if rg -n -i \
    '(email|account id|authorization:[[:space:]]*bearer|sk-[a-z0-9]{16,}|[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,})' \
    index.html DESIGN.md README.md; then
    echo "Potential account or credential text found in the composition source." >&2
    exit 1
fi

ffmpeg -y -loglevel error -i "${GIF_PATH}" \
    -vf "fps=1,scale=480:-1:flags=lanczos,tile=3x2" \
    -frames:v 1 -update 1 "${CONTACT_SHEET}"

echo "Automated README preview checks passed."
echo "Contact sheet: ${CONTACT_SHEET}"
echo "Manual gate: inspect all six frames for overlap, clipping, edge artifacts, unreadable text, and personal information."
