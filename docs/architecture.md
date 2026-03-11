# Architecture

## Overview

Single control-plane bare-metal Kubernetes cluster for homelab use, managed by an AI operator through a Git-driven workflow.

```
┌──────────────────────────────────────────────────────────┐
│                      k8s-homelab                          │
│                                                           │
│   ┌───────────────┐                                       │
│   │  control-01    │  192.168.1.202                       │
│   │  CP + etcd     │  Ubuntu 24.04 / K8s v1.32.13        │
│   └───────┬───────┘                                       │
│           │                                               │
│   ┌───────┴───────┐  ┌───────────────┐                    │
│   │  worker-01     │  │  worker-02     │                  │
│   │  (planned)     │  │  (planned)     │                  │
│   └───────────────┘  └───────────────┘                    │
│                                                           │
│   CNI: Calico v3.29.3    Pod CIDR: 192.168.0.0/16        │
│   Svc CIDR: 10.96.0.0/12                                 │
└──────────────────────────────────────────────────────────┘
```

## Components

| Layer | Component | Version | Status |
|-------|-----------|---------|--------|
| OS | Ubuntu Server | 24.04.4 LTS | Deployed |
| Runtime | containerd | 1.7.28 | Deployed |
| Orchestration | Kubernetes | v1.32.13 | Deployed |
| CNI | Calico | v3.29.3 | Deployed |
| Load Balancer | MetalLB | - | Planned |
| Ingress | ingress-nginx | - | Planned |
| Storage | NFS provisioner | - | Planned |
| GitOps | Flux / ArgoCD | - | Planned |
| Monitoring | Prometheus + Grafana | - | Planned |
| CI | GitHub Actions | - | Pending (workflows permission) |

## Repository Layout

```
bootstrap/              Node prep, kubeadm config, init scripts
  scripts/              node-prep.sh, kubeadm-init.sh, GitHub App auth
  kubeadm/              kubeadm-config.yaml
  ansible/              Ansible inventory (future automation)
cluster/                Cluster-level config (day-2 kubeadm changes)
  kubeadm/              kubeadm-config.yaml (reference)
platform/               Infrastructure add-ons
  calico/               CNI
apps/                   Application workloads (GitOps-managed)
docs/                   Architecture, runbooks, policies
  runbooks/             Operational procedures
  policies/             AI operator and security policies
.github/workflows/      CI pipelines (pending)
```

## Design Decisions

1. **Bare-metal** — No cloud provider, no managed Kubernetes
2. **kubeadm** — Standard bootstrapping, portable knowledge
3. **containerd** — Direct CRI, no Docker shim
4. **Calico** — Full-featured CNI with network policy support
5. **GitHub App auth** — No personal tokens, scoped permissions
6. **AI operator** — Claude Code as infrastructure assistant, constrained by policy
7. **PR workflow** — All changes via pull request, no direct pushes to main
8. **GitOps target** — Repository is the single source of truth for cluster state

## Management Model

```
User ──► AI Operator ──► Git (PR) ──► CI Validation ──► Merge ──► GitOps Sync
              │                            │
              └── Policy constraints        └── Lint, validate, docs check
```

See:
- [AI Operator Model](ai-operator.md)
- [GitOps Model](gitops.md)
- [Cluster Lifecycle](lifecycle.md)
- [Network Design](network.md)
