# k8s-homelab

Bare-metal Kubernetes homelab — AI-managed infrastructure via GitHub App and PR workflow.

## Architecture

```
┌───────────────┐
│  control-01    │  192.168.1.202 · Ubuntu 24.04 · K8s v1.32.13
│  CP + etcd     │  containerd 1.7.28 · Calico v3.29.3
└───────┬───────┘
        │ (workers planned)
┌───────┴───────┐  ┌───────────────┐
│  worker-01     │  │  worker-02     │
└───────────────┘  └───────────────┘
```

| Network | CIDR |
|---------|------|
| Pod | 192.168.0.0/16 |
| Service | 10.96.0.0/12 |
| LAN | 192.168.1.0/24 |

## Repository Layout

```
bootstrap/              Node bootstrap and cluster init
  scripts/              node-prep.sh, kubeadm-init.sh, GitHub App auth
  kubeadm/              kubeadm-config.yaml
  ansible/              Inventory for future automation
cluster/                Cluster-level configuration (day-2)
platform/               Infrastructure add-ons (Calico, MetalLB, ingress)
apps/                   Application workloads (GitOps-managed)
docs/                   Architecture, runbooks, policies
.github/workflows/      CI: lint, k8s validation, docs check
```

## Bootstrap

```bash
# Phase 0: Prepare node OS
sudo bash bootstrap/scripts/node-prep.sh

# Phase 1: Initialize control plane
sudo bash bootstrap/scripts/kubeadm-init.sh

# Phase 1: Install CNI
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/calico.yaml

# Phase 1: Join workers
sudo kubeadm join 192.168.1.202:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

See [Runbook: Bootstrap Control Plane](docs/runbooks/bootstrap-control-plane.md) for details.

## AI Operator Model

This repo is managed by **Claude Code** as an AI infrastructure operator:

| Principle | Implementation |
|-----------|---------------|
| Git-driven | All changes via PR, no direct main pushes |
| Policy-constrained | [AI Operator Policy](docs/policies/ai-operator-policy.md) |
| Auditable | Commits by `ben-ai-ops-k8s[bot]` via GitHub App |
| Human-in-the-loop | AI proposes, human approves |

```
User Intent → AI Operator → PR → CI Validation → Human Review → Merge
```

See [AI Operator Model](docs/ai-operator.md) for the full design.

## GitOps Model

| Phase | Current | Target |
|-------|---------|--------|
| Bootstrap (Phase 0-1) | Manual scripts | Ansible |
| Platform (Phase 2) | `kubectl apply` | GitOps controller (Flux/ArgoCD) |
| Apps (Phase 3) | Not started | GitOps auto-sync |

**Goal**: Every cluster change originates from a PR in this repository.

See [GitOps Model](docs/gitops.md) for the full design.

## Lifecycle

| Phase | Description | Status |
|-------|-------------|--------|
| 0 - OS Prep | Node bootstrap | ✅ Done |
| 1 - Cluster Init | kubeadm + CNI | ✅ Done |
| 2 - Platform | Add-ons (LB, ingress, storage) | Planned |
| 3 - Apps | Workloads via GitOps | Planned |

See [Cluster Lifecycle](docs/lifecycle.md) for details.

## CI Pipelines

| Workflow | Purpose | Status |
|----------|---------|--------|
| lint.yml | YAML lint + ShellCheck | Pending (needs `workflows` permission) |
| validate-k8s.yml | kubeconform manifest validation | Pending |
| docs-check.yml | Broken links + required docs | Pending |

## GitHub App Auth

```bash
cp .env.example .env
bash bootstrap/scripts/github-auth-check.sh
bash bootstrap/scripts/git-use-app-token.sh
```

See [GitHub App Setup](docs/github-app-setup.md).

## Documentation

- [Architecture](docs/architecture.md)
- [Network](docs/network.md)
- [Cluster Lifecycle](docs/lifecycle.md)
- [GitOps Model](docs/gitops.md)
- [AI Operator Model](docs/ai-operator.md)
- [AI Operator Policy](docs/policies/ai-operator-policy.md)
- [Bootstrap Runbook](docs/runbooks/bootstrap-control-plane.md)
- [GitHub App Setup](docs/github-app-setup.md)
- [Claude Workflow](docs/claude-workflow.md)
