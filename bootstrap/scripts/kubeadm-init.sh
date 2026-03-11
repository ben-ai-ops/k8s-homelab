#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# kubeadm-init.sh — Initialize Kubernetes control plane
#
# Uses the kubeadm config from bootstrap/kubeadm/kubeadm-config.yaml.
# Saves output and join command locally.
#
# Usage:
#   sudo bash bootstrap/scripts/kubeadm-init.sh
#
# This script does NOT install CNI. Run that separately after init.
# ──────────────────────────────────────────────────────────────
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BOOTSTRAP_DIR="${PROJECT_ROOT}/bootstrap"
KUBEADM_CONFIG="${BOOTSTRAP_DIR}/kubeadm/kubeadm-config.yaml"
OUTPUT_FILE="${BOOTSTRAP_DIR}/kubeadm-init-output.txt"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# ── Pre-flight ───────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Must run as root (sudo)" >&2
    exit 1
fi

if [[ ! -f "${KUBEADM_CONFIG}" ]]; then
    echo "ERROR: kubeadm config not found: ${KUBEADM_CONFIG}" >&2
    exit 1
fi

# Check if already initialized
if [[ -f /etc/kubernetes/admin.conf ]]; then
    echo "ERROR: Cluster appears already initialized (/etc/kubernetes/admin.conf exists)" >&2
    echo "  If you want to reinitialize, run: sudo kubeadm reset -f" >&2
    exit 1
fi

# Check containerd
if ! systemctl is-active --quiet containerd; then
    echo "ERROR: containerd is not running" >&2
    exit 1
fi

log "=== Kubernetes Control Plane Init ==="
log "Config: ${KUBEADM_CONFIG}"
log ""

# ── Init ─────────────────────────────────────────────────────
kubeadm init --config "${KUBEADM_CONFIG}" 2>&1 | tee "${OUTPUT_FILE}"

log ""
log "Init output saved to: ${OUTPUT_FILE}"

# ── Extract join command ─────────────────────────────────────
JOIN_FILE="${BOOTSTRAP_DIR}/worker-join-command.sh"
JOIN_CMD=$(grep -A1 'kubeadm join' "${OUTPUT_FILE}" | tr -d '\t\\' | tr '\n' ' ' | xargs)

if [[ -n "${JOIN_CMD}" ]]; then
    cat > "${JOIN_FILE}" <<JOINEOF
#!/usr/bin/env bash
# Run this on each worker node as root to join the cluster.
# Token expires after 24 hours. To regenerate:
#   kubeadm token create --print-join-command

${JOIN_CMD}
JOINEOF
    chmod +x "${JOIN_FILE}"
    log "Join command saved to: ${JOIN_FILE}"
else
    log "WARNING: Could not extract join command from output"
fi

# ── Configure kubectl for the invoking user ──────────────────
SUDO_USER_HOME=$(eval echo "~${SUDO_USER:-root}")
if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    KUBE_DIR="${SUDO_USER_HOME}/.kube"
    mkdir -p "${KUBE_DIR}"
    cp /etc/kubernetes/admin.conf "${KUBE_DIR}/config"
    chown -R "$(id -u "${SUDO_USER}"):$(id -g "${SUDO_USER}")" "${KUBE_DIR}"
    log "kubectl configured for user: ${SUDO_USER}"
fi

log ""
log "=== Next Steps ==="
log "1. Install CNI:  kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/calico.yaml"
log "2. Verify:       kubectl get nodes"
log "3. Join workers: sudo bash ${JOIN_FILE}"
