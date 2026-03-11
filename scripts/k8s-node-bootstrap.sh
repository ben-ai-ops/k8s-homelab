#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# k8s-node-bootstrap.sh
#
# Prepare an Ubuntu 24.04 LTS machine as a Kubernetes node.
# Safe to re-run (idempotent). Does NOT initialize the cluster.
#
# Usage:
#   sudo bash scripts/k8s-node-bootstrap.sh
# ──────────────────────────────────────────────────────────────
set -Eeuo pipefail

# ── Preflight ─────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Must run as root (sudo)" >&2
    exit 1
fi

KUBE_VERSION="1.32"  # stable minor version
BACKUP_DIR="/root/k8s-bootstrap-backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "${BACKUP_DIR}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }
backup() {
    local file="$1"
    if [[ -f "${file}" ]]; then
        cp "${file}" "${BACKUP_DIR}/$(basename "${file}").bak"
        log "  Backed up ${file}"
    fi
}

log "=== Kubernetes Node Bootstrap ==="
log "Backup dir: ${BACKUP_DIR}"

# ── 1. Disable swap ──────────────────────────────────────────
log ""
log "--- 1. Disable swap ---"
if swapon --show | grep -q .; then
    swapoff -a
    log "Swap disabled (runtime)"
else
    log "Swap already off"
fi

# Remove swap entries from fstab
if grep -qE '^\s*[^#].*\bswap\b' /etc/fstab; then
    backup /etc/fstab
    sed -i '/\bswap\b/s/^/#/' /etc/fstab
    log "Swap entries commented out in /etc/fstab"
else
    log "No active swap in /etc/fstab"
fi

# Disable swap.img systemd unit if present
if systemctl is-enabled swap.img.swap &>/dev/null; then
    systemctl mask swap.img.swap
    log "Masked swap.img.swap unit"
fi

# ── 2. Kernel modules ───────────────────────────────────────
log ""
log "--- 2. Kernel modules ---"
MODULES_CONF="/etc/modules-load.d/k8s.conf"
cat > "${MODULES_CONF}" <<MOD
# Kubernetes required modules
overlay
br_netfilter
MOD
log "Wrote ${MODULES_CONF}"

modprobe overlay
modprobe br_netfilter
log "Loaded: overlay, br_netfilter"

# ── 3. Sysctl ────────────────────────────────────────────────
log ""
log "--- 3. Sysctl ---"
SYSCTL_CONF="/etc/sysctl.d/99-kubernetes.conf"
cat > "${SYSCTL_CONF}" <<SYSCTL
# Kubernetes networking
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
SYSCTL
log "Wrote ${SYSCTL_CONF}"

sysctl --system >/dev/null 2>&1
log "Sysctl applied"

# ── 4. Install base packages ────────────────────────────────
log ""
log "--- 4. Base packages ---"
export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
apt-get install -y -qq \
    curl \
    gpg \
    jq \
    vim \
    git \
    apt-transport-https \
    ca-certificates \
    chrony \
    nfs-common \
    socat \
    conntrack \
    ethtool \
    >/dev/null
log "Base packages installed"

# Enable chrony
systemctl enable --now chrony >/dev/null 2>&1
log "chrony enabled"

# ── 5. Install containerd ───────────────────────────────────
log ""
log "--- 5. containerd ---"
if ! command -v containerd &>/dev/null; then
    apt-get install -y -qq containerd >/dev/null
    log "containerd installed"
else
    log "containerd already installed"
fi

# Generate default config and set SystemdCgroup
CONTAINERD_CONF="/etc/containerd/config.toml"
mkdir -p /etc/containerd

if [[ -f "${CONTAINERD_CONF}" ]]; then
    backup "${CONTAINERD_CONF}"
fi

containerd config default > "${CONTAINERD_CONF}"

# Set SystemdCgroup = true
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' "${CONTAINERD_CONF}"
log "containerd config: SystemdCgroup = true"

# Use the correct sandbox image for k8s
# Ensure the pause image matches what kubeadm expects
sed -i 's|sandbox_image = .*|sandbox_image = "registry.k8s.io/pause:3.10"|' "${CONTAINERD_CONF}"
log "containerd config: sandbox_image set to registry.k8s.io/pause:3.10"

systemctl enable containerd >/dev/null 2>&1
systemctl restart containerd
log "containerd enabled and restarted"

# ── 6. Install Kubernetes packages ───────────────────────────
log ""
log "--- 6. Kubernetes packages (v${KUBE_VERSION}) ---"
KUBE_KEYRING="/etc/apt/keyrings/kubernetes-apt-keyring.gpg"
KUBE_REPO="/etc/apt/sources.list.d/kubernetes.list"

# Add the signing key
mkdir -p /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${KUBE_VERSION}/deb/Release.key" \
    | gpg --batch --yes --dearmor -o "${KUBE_KEYRING}"
log "Added Kubernetes APT signing key"

# Add the repo
echo "deb [signed-by=${KUBE_KEYRING}] https://pkgs.k8s.io/core:/stable:/v${KUBE_VERSION}/deb/ /" \
    > "${KUBE_REPO}"
log "Added Kubernetes APT repo (v${KUBE_VERSION})"

apt-get update -qq
apt-get install -y -qq kubelet kubeadm kubectl >/dev/null
log "kubelet, kubeadm, kubectl installed"

# Hold versions to prevent accidental upgrades
apt-mark hold kubelet kubeadm kubectl >/dev/null
log "Packages held"

# Enable kubelet (it will crashloop until cluster init — that's normal)
systemctl enable kubelet >/dev/null 2>&1
log "kubelet enabled"

# ── 7. Verification ─────────────────────────────────────────
log ""
log "=========================================="
log "  VERIFICATION"
log "=========================================="
echo ""

echo "Hostname:       $(hostname)"
echo "IP:             $(ip -4 addr show eno1 2>/dev/null | grep -oP 'inet \K[\d./]+' || echo 'N/A')"
echo ""

echo "Swap:           $(swapon --show 2>/dev/null | grep -c . || echo 0) device(s)"
free -h | grep -i swap
echo ""

echo "Kernel modules:"
echo "  overlay:        $(lsmod | grep -cw overlay || echo 0) loaded"
echo "  br_netfilter:   $(lsmod | grep -cw br_netfilter || echo 0) loaded"
echo ""

echo "Sysctl:"
echo "  bridge-nf-call-iptables:  $(sysctl -n net.bridge.bridge-nf-call-iptables)"
echo "  bridge-nf-call-ip6tables: $(sysctl -n net.bridge.bridge-nf-call-ip6tables)"
echo "  ip_forward:               $(sysctl -n net.ipv4.ip_forward)"
echo ""

echo "Services:"
echo "  containerd: $(systemctl is-active containerd)"
echo "  chrony:     $(systemctl is-active chrony)"
echo "  kubelet:    $(systemctl is-active kubelet 2>/dev/null || echo 'activating (expected pre-init)')"
echo ""

echo "Versions:"
echo "  containerd: $(containerd --version 2>/dev/null | awk '{print $3}')"
echo "  kubeadm:    $(kubeadm version -o short 2>/dev/null)"
echo "  kubelet:    $(kubelet --version 2>/dev/null | awk '{print $2}')"
echo "  kubectl:    $(kubectl version --client -o yaml 2>/dev/null | grep gitVersion | awk '{print $2}')"
echo ""

echo "containerd SystemdCgroup:"
echo "  $(grep 'SystemdCgroup' /etc/containerd/config.toml | grep -v '#' | head -1 | xargs)"
echo ""

log "Bootstrap complete. Node is ready for kubeadm init/join."
