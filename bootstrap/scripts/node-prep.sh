#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# node-prep.sh — Prepare an Ubuntu 24.04 node for Kubernetes
#
# Wrapper around k8s-node-bootstrap.sh with pre-flight checks.
# Idempotent. Safe to re-run.
#
# Usage:
#   sudo bash bootstrap/scripts/node-prep.sh
# ──────────────────────────────────────────────────────────────
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Pre-flight ───────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Must run as root (sudo)" >&2
    exit 1
fi

echo "=== Node Prep: Pre-flight Checks ==="

# Check OS
if ! grep -q 'VERSION_ID="24.04"' /etc/os-release 2>/dev/null; then
    echo "WARNING: Expected Ubuntu 24.04, found:"
    grep PRETTY_NAME /etc/os-release
    echo "Continuing anyway..."
fi

# Check network
if ! ping -c1 -W3 pkgs.k8s.io &>/dev/null; then
    echo "ERROR: Cannot reach pkgs.k8s.io — check network connectivity" >&2
    exit 1
fi
echo "  ✓ Network connectivity OK"

# Check disk space (need at least 5GB free)
FREE_GB=$(df / --output=avail -BG | tail -1 | tr -d ' G')
if [[ ${FREE_GB} -lt 5 ]]; then
    echo "ERROR: Less than 5GB free on /" >&2
    exit 1
fi
echo "  ✓ Disk space: ${FREE_GB}GB free"

echo ""

# ── Run bootstrap ────────────────────────────────────────────
exec bash "${SCRIPT_DIR}/k8s-node-bootstrap.sh"
