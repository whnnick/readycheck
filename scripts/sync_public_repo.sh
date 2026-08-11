#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PUBLIC_SYNC_DIR="${READYCHECK_PUBLIC_SYNC_DIR:-/private/tmp/readycheck-public-sync}"
MODE="${1:---dry-run}"

if [[ "${MODE}" != "--dry-run" && "${MODE}" != "--apply" ]]; then
    echo "Usage: $0 [--dry-run|--apply]" >&2
    exit 2
fi

for command in git rg rsync; do
    if ! command -v "${command}" >/dev/null 2>&1; then
        echo "Required command not found: ${command}" >&2
        exit 1
    fi
done

if [[ ! "${SOURCE_ROOT}" == */.worktrees/* ]] \
    || ! git -C "${SOURCE_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Run this script from the ReadyCheck development worktree." >&2
    echo "Detected source: ${SOURCE_ROOT}" >&2
    exit 1
fi

if [[ -n "$(git -C "${SOURCE_ROOT}" status --porcelain)" ]]; then
    echo "Development worktree is dirty. Commit or explicitly resolve changes before public sync." >&2
    exit 1
fi

if [[ ! -e "${PUBLIC_SYNC_DIR}/.git" ]]; then
    if [[ "${MODE}" == "--dry-run" ]]; then
        echo "Public sync worktree does not exist yet: ${PUBLIC_SYNC_DIR}"
        echo "--apply would fetch origin/main and initialize this temporary worktree."
        exit 0
    fi

    git -C "${SOURCE_ROOT}" fetch origin main
    git -C "${SOURCE_ROOT}" worktree prune
    git -C "${SOURCE_ROOT}" worktree add --detach "${PUBLIC_SYNC_DIR}" origin/main
elif [[ "${MODE}" == "--apply" ]]; then
    if [[ -n "$(git -C "${PUBLIC_SYNC_DIR}" status --porcelain)" ]]; then
        echo "Public sync worktree is dirty. Review it before applying a new sync." >&2
        exit 1
    fi
    git -C "${PUBLIC_SYNC_DIR}" fetch origin main
    git -C "${PUBLIC_SYNC_DIR}" checkout --detach origin/main
fi

excludes=(
    --exclude .git
    --exclude .build
    --exclude dist
    --exclude apps/windows/node_modules
    --exclude marketing/remotion/node_modules
    --exclude marketing/remotion/out
    --exclude marketing/hyperframes/node_modules
    --exclude marketing/hyperframes/renders
    --exclude marketing/hyperframes/snapshots
    --exclude .worktrees
    --exclude .codex
    --exclude .agents
    --exclude AGENTS.md
    --exclude docs/superpowers
)

if [[ "${MODE}" == "--dry-run" ]]; then
    rsync -an --delete "${excludes[@]}" "${SOURCE_ROOT}/" "${PUBLIC_SYNC_DIR}/"
    echo "Dry run complete. Re-run with --apply to update ${PUBLIC_SYNC_DIR}."
    exit 0
fi

find "${PUBLIC_SYNC_DIR}" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
rsync -a --delete "${excludes[@]}" "${SOURCE_ROOT}/" "${PUBLIC_SYNC_DIR}/"

for forbidden in AGENTS.md .codex .agents .worktrees docs/superpowers dist; do
    if [[ -e "${PUBLIC_SYNC_DIR}/${forbidden}" ]]; then
        echo "Forbidden public-sync path exists: ${forbidden}" >&2
        exit 1
    fi
done

if rg -n --hidden -S \
    --glob '!.git' \
    --glob '!**/.git/**' \
    --glob '!*.gif' \
    --glob '!*.png' \
    --glob '!*.jpg' \
    --glob '!**/apps/windows/package-lock.json' \
    --glob '!**/scripts/sync_public_repo.sh' \
    '(/Users/[^/[:space:]]+|[[:alnum:]._%+-]+@[[:alpha:]][[:alnum:].-]*\.[[:alpha:]]{2,}|Authorization:[[:space:]]*Bearer|sk-[A-Za-z0-9]{16,})' \
    "${PUBLIC_SYNC_DIR}" \
    | grep -Eiv '(/Users/example/|@example\.com)'; then
    echo "Potential private data found in public sync. Review before continuing." >&2
    exit 1
fi

git -C "${PUBLIC_SYNC_DIR}" diff --check
echo "Public sync updated and checked: ${PUBLIC_SYNC_DIR}"
echo "No commit, tag, push, or release action was performed."
