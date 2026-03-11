# Architecture

## Overview

Single control-plane bare-metal Kubernetes cluster for homelab use.

```
┌─────────────────────────────────────────────────┐
│                  k8s-homelab                     │
│                                                  │
│  ┌──────────────┐                                │
│  │ control-01   │  192.168.1.202                 │
│  │ CP + etcd    │  Ubuntu 24.04 / K8s v1.32.13  │
│  └──────┬───────┘                                │
│         │                                        │
│         │  (future worker nodes)                 │
│         │                                        │
│  ┌──────┴───────┐  ┌──────────────┐              │
│  │ worker-01    │  │ worker-02    │              │
│  │ (planned)    │  │ (planned)    │              │
│  └──────────────┘  └──────────────┘              │
└─────────────────────────────────────────────────┘
```

## Components

| Layer | Component | Status |
|-------|-----------|--------|
| OS | Ubuntu 24.04.4 LTS | Deployed |
| Runtime | containerd 1.7.28 | Deployed |
| Orchestration | Kubernetes v1.32.13 | Deployed |
| CNI | Calico v3.29.3 | Deployed |
| Load Balancer | MetalLB | Planned |
| Ingress | ingress-nginx | Planned |
| Storage | NFS provisioner | Planned |
| GitOps | Flux / ArgoCD | Planned |
| Monitoring | Prometheus + Grafana | Planned |

## Repository Layout

```
bootstrap/     OS prep and node bootstrap scripts
cluster/       Kubernetes cluster configuration (kubeadm)
platform/      Infrastructure add-ons (CNI, LB, ingress, storage)
apps/          Application deployments
docs/          Documentation and runbooks
.github/       CI workflows
```

## Design Decisions

1. **Bare-metal**: No cloud provider, no managed Kubernetes
2. **kubeadm**: Standard bootstrapping, no exotic tools
3. **containerd**: Direct CRI, no Docker shim
4. **Calico**: Full-featured CNI with network policy support
5. **GitHub App auth**: No personal tokens in automation
