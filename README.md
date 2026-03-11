# k8s-homelab

Bare-metal Kubernetes homelab infrastructure managed via GitHub App automation.

## Architecture

```
┌──────────────┐
│ control-01   │  192.168.1.202
│ CP + etcd    │  Ubuntu 24.04 / K8s v1.32.13
└──────┬───────┘
       │  (workers planned)
┌──────┴───────┐  ┌──────────────┐
│ worker-01    │  │ worker-02    │
│ (planned)    │  │ (planned)    │
└──────────────┘  └──────────────┘
```

| Component | Version | Status |
|-----------|---------|--------|
| Kubernetes | v1.32.13 | Deployed |
| containerd | 1.7.28 | Deployed |
| Calico CNI | v3.29.3 | Deployed |
| MetalLB | - | Planned |
| ingress-nginx | - | Planned |

| Network | CIDR |
|---------|------|
| Pod | 192.168.0.0/16 |
| Service | 10.96.0.0/12 |
| LAN | 192.168.1.0/24 |

## Bootstrap

```bash
# 1. Prepare OS (on each node)
sudo bash bootstrap/scripts/k8s-node-bootstrap.sh

# 2. Init control plane (first node only)
sudo kubeadm init --config cluster/kubeadm/kubeadm-config.yaml

# 3. Configure kubectl
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 4. Install CNI
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/calico.yaml

# 5. Join workers
sudo kubeadm join 192.168.1.202:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

See [docs/runbooks/bootstrap.md](docs/runbooks/bootstrap.md) for full runbook.

## Repository Structure

```
bootstrap/          Node bootstrap scripts and OS prep
  scripts/          k8s-node-bootstrap.sh, GitHub App auth scripts
cluster/            Kubernetes cluster configuration
  kubeadm/          kubeadm-config.yaml
platform/           Infrastructure add-ons (CNI, LB, ingress)
  calico/           Calico CNI
apps/               Application deployments
docs/               Documentation
  runbooks/         Operational runbooks
  architecture.md   Cluster architecture
  network.md        Network design
.github/            CI workflows (yamllint, shellcheck)
```

## GitOps Plan

| Phase | Component | Approach |
|-------|-----------|----------|
| Current | Manual kubectl + kubeadm | Bootstrap phase |
| Next | Flux / ArgoCD | Declarative cluster management |
| Target | Full GitOps | All config in repo, auto-sync to cluster |

**Goal**: Every change to the cluster flows through a PR in this repository.

## GitHub App Auth

```bash
# Setup
cp .env.example .env
bash bootstrap/scripts/github-auth-check.sh

# Configure git
bash bootstrap/scripts/git-use-app-token.sh
```

## CI

- **YAML lint**: Validates all YAML files
- **ShellCheck**: Static analysis on shell scripts

## Docs

- [Architecture](docs/architecture.md)
- [Network](docs/network.md)
- [Bootstrap Runbook](docs/runbooks/bootstrap.md)
- [GitHub App Setup](docs/github-app-setup.md)
- [Claude Workflow](docs/claude-workflow.md)
