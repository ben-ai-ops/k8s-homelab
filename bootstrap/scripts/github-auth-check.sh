#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# Verify GitHub App authentication is working.
#
# Checks:
#   1. Required environment variables / .env
#   2. PEM file exists and is valid
#   3. JWT generation works
#   4. Can authenticate as the App
#   5. Can generate an installation token
#   6. Token has expected permissions
#
# Usage:
#   bash scripts/github-auth-check.sh
# ──────────────────────────────────────────────────────────────
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

PASS="✓"
FAIL="✗"
WARN="⚠"
errors=0

check() {
    local label="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "  ${PASS} ${label}"
    else
        echo "  ${FAIL} ${label}"
        ((errors++))
    fi
}

echo "── GitHub App Auth Check ──────────────────────────"

# Load .env
if [[ -f "${PROJECT_ROOT}/.env" ]]; then
    set -a
    source "${PROJECT_ROOT}/.env"
    set +a
    echo "  ${PASS} .env loaded"
else
    echo "  ${FAIL} .env not found (copy from .env.example)"
    exit 1
fi

# Check variables
echo ""
echo "Environment:"
check "GITHUB_APP_ID is set" test -n "${GITHUB_APP_ID:-}"
check "GITHUB_APP_INSTALLATION_ID is set" test -n "${GITHUB_APP_INSTALLATION_ID:-}"
check "GITHUB_APP_PEM_FILE is set" test -n "${GITHUB_APP_PEM_FILE:-}"
check "PEM file exists" test -f "${GITHUB_APP_PEM_FILE:-/nonexistent}"

# Check PEM validity
echo ""
echo "PEM file:"
if [[ -f "${GITHUB_APP_PEM_FILE:-}" ]]; then
    check "PEM is valid RSA key" openssl rsa -in "${GITHUB_APP_PEM_FILE}" -check -noout
    # Check permissions
    PERMS=$(stat -c '%a' "${GITHUB_APP_PEM_FILE}" 2>/dev/null || stat -f '%Lp' "${GITHUB_APP_PEM_FILE}" 2>/dev/null)
    if [[ "${PERMS}" == "600" || "${PERMS}" == "400" ]]; then
        echo "  ${PASS} File permissions: ${PERMS}"
    else
        echo "  ${WARN} File permissions: ${PERMS} (recommend 600)"
    fi
else
    echo "  ${FAIL} PEM file missing — skipping validation"
    ((errors++))
fi

# Check Python + PyJWT
echo ""
echo "Dependencies:"
check "python3 available" which python3
check "PyJWT installed" python3 -c "import jwt"

# API checks (only if everything above passed)
if [[ ${errors} -gt 0 ]]; then
    echo ""
    echo "Skipping API checks due to ${errors} error(s) above."
    exit 1
fi

echo ""
echo "API connectivity:"

# Generate token and check
TOKEN_JSON=$(python3 "${SCRIPT_DIR}/github-app-token.py" --format=json 2>&1) || {
    echo "  ${FAIL} Token generation failed"
    echo "  ${TOKEN_JSON}" | head -5
    exit 1
}

echo "  ${PASS} Token generated successfully"

# Parse results
EXPIRES=$(echo "${TOKEN_JSON}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('expires_at','?'))")
PERMS=$(echo "${TOKEN_JSON}" | python3 -c "import sys,json; perms=json.load(sys.stdin).get('permissions',{}); print(', '.join(f'{k}:{v}' for k,v in perms.items()))")
PREVIEW=$(echo "${TOKEN_JSON}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('token_preview','?'))")

echo "  ${PASS} Token: ${PREVIEW}"
echo "  ${PASS} Expires: ${EXPIRES}"
echo "  ${PASS} Permissions: ${PERMS}"

# Test git access
echo ""
echo "Git access:"
TEMP_TOKEN=$(python3 "${SCRIPT_DIR}/github-app-token.py" --format=token 2>/dev/null)
if git ls-remote "https://x-access-token:${TEMP_TOKEN}@github.com/ben-ai-ops/k8s-homelab.git" HEAD >/dev/null 2>&1; then
    echo "  ${PASS} Can access ben-ai-ops/k8s-homelab"
else
    echo "  ${FAIL} Cannot access ben-ai-ops/k8s-homelab"
    ((errors++))
fi
unset TEMP_TOKEN

echo ""
if [[ ${errors} -eq 0 ]]; then
    echo "All checks passed."
else
    echo "${errors} check(s) failed."
    exit 1
fi
