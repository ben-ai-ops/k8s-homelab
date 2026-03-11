# k8s-homelab

Bare-metal Kubernetes homelab infrastructure managed via GitHub App automation.

## Cluster

| Node | Role | IP | OS | K8s Version |
|------|------|----|----|-------------|
| control-01 | control-plane | 192.168.1.202 | Ubuntu 24.04.4 LTS | v1.32.13 |

| Component | Version |
|-----------|---------|
| containerd | 1.7.28 |
| Calico CNI | v3.29.3 |
| Pod CIDR | 192.168.0.0/16 |
| Service CIDR | 10.96.0.0/12 |

## Quick Start

```bash
# 1. Set up environment
cp .env.example .env

# 2. Verify GitHub App auth
bash scripts/github-auth-check.sh

# 3. Configure git with App token
bash scripts/git-use-app-token.sh
```

## Project Structure

```
├── scripts/
│   ├── k8s-node-bootstrap.sh     # OS prep for k8s nodes (idempotent)
│   ├── github-app-token.py       # Generate GitHub App access token
│   ├── export-github-token.sh    # Export GITHUB_TOKEN to shell
│   ├── git-use-app-token.sh      # Set git remote with App token
│   └── github-auth-check.sh      # End-to-end auth verification
├── docs/
│   ├── control-plane-init-summary.md
│   ├── github-app-setup.md
│   └── claude-workflow.md
├── bootstrap/                     # Local only (gitignored)
├── CLAUDE.md                      # Claude Code project instructions
└── .env.example                   # Environment template
```

## Node Bootstrap

Prepare a fresh Ubuntu 24.04 machine as a Kubernetes node:

```bash
sudo bash scripts/k8s-node-bootstrap.sh
```

This script is idempotent and handles:
- Disable swap
- Kernel modules (overlay, br_netfilter)
- Sysctl (ip_forward, bridge-nf-call)
- Install containerd (SystemdCgroup=true)
- Install kubelet, kubeadm, kubectl
- Version hold

## GitHub App Auth

Authentication uses the `ben-ai-ops-k8s` GitHub App instead of personal tokens.

```bash
# Get a fresh token
source scripts/export-github-token.sh

# Or configure git directly
bash scripts/git-use-app-token.sh
```

See [docs/github-app-setup.md](docs/github-app-setup.md) for details.

## Roadmap

- [ ] Add worker nodes
- [ ] MetalLB (load balancer)
- [ ] ingress-nginx
- [ ] NFS storage provisioner
- [ ] Helm
- [ ] Monitoring (Prometheus/Grafana)
