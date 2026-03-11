#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# Configure git to use GitHub App token for this repo.
#
# What it does:
#   1. Generates a fresh installation access token
#   2. Sets the repo remote URL to use the token
#   3. Configures local git user as the App bot
#
# Usage:
#   bash scripts/git-use-app-token.sh          # setup
#   bash scripts/git-use-app-token.sh --remove  # revert to SSH/default
#
# Note: Token expires in ~1 hour. Re-run to refresh.
# ──────────────────────────────────────────────────────────────
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

REPO_OWNER="ben-ai-ops"
REPO_NAME="k8s-homelab"
REMOTE_NAME="origin"
APP_BOT_NAME="ben-ai-ops-k8s[bot]"
APP_BOT_EMAIL="3063256+ben-ai-ops-k8s[bot]@users.noreply.github.com"

# Load .env
if [[ -f "${PROJECT_ROOT}/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "${PROJECT_ROOT}/.env"
    set +a
fi

cd "${PROJECT_ROOT}"

# ── Remove mode ──────────────────────────────────────────────
if [[ "${1:-}" == "--remove" ]]; then
    echo "Reverting remote to SSH..."
    git remote set-url "${REMOTE_NAME}" "git@github.com:${REPO_OWNER}/${REPO_NAME}.git"
    git config --local --unset user.name 2>/dev/null || true
    git config --local --unset user.email 2>/dev/null || true
    echo "✓ Remote reset to SSH. Local git user config cleared."
    exit 0
fi

# ── Check git repo ───────────────────────────────────────────
if [[ ! -d .git ]]; then
    echo "ERROR: Not a git repository. Run this from the project root." >&2
    exit 1
fi

# ── Generate token ───────────────────────────────────────────
echo "Generating GitHub App token..."
TOKEN=$(python3 "${SCRIPT_DIR}/github-app-token.py" --format=token)

if [[ -z "${TOKEN}" ]]; then
    echo "ERROR: Failed to generate token" >&2
    exit 1
fi

MASKED="${TOKEN:0:8}...${TOKEN: -4}"

# ── Set remote URL ───────────────────────────────────────────
REMOTE_URL="https://x-access-token:${TOKEN}@github.com/${REPO_OWNER}/${REPO_NAME}.git"
git remote set-url "${REMOTE_NAME}" "${REMOTE_URL}"
echo "✓ Remote '${REMOTE_NAME}' configured with App token (${MASKED})"

# ── Set git user to App bot ──────────────────────────────────
git config --local user.name "${APP_BOT_NAME}"
git config --local user.email "${APP_BOT_EMAIL}"
echo "✓ Git user set to ${APP_BOT_NAME}"

echo ""
echo "You can now push/pull. Token expires in ~1 hour."
echo "Run with --remove to revert to SSH."
