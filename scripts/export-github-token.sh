#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# Export a fresh GitHub App token into the current shell.
#
# Usage:
#   source scripts/export-github-token.sh
#
# After sourcing, GITHUB_TOKEN will be available in your shell.
# The token expires in ~1 hour.
# ──────────────────────────────────────────────────────────────
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load .env if present
if [[ -f "${PROJECT_ROOT}/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "${PROJECT_ROOT}/.env"
    set +a
fi

# Generate token
TOKEN_OUTPUT=$(python3 "${SCRIPT_DIR}/github-app-token.py" --format=export)

if [[ $? -ne 0 ]]; then
    echo "ERROR: Failed to generate token" >&2
    return 1 2>/dev/null || exit 1  # return if sourced, exit if run
fi

# Eval the export line (first line only)
eval "$(echo "${TOKEN_OUTPUT}" | head -1)"

# Show masked confirmation
MASKED="${GITHUB_TOKEN:0:8}...${GITHUB_TOKEN: -4}"
echo "✓ GITHUB_TOKEN exported (${MASKED})"
echo "  $(echo "${TOKEN_OUTPUT}" | tail -1)"  # expiry comment
