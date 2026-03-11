# GitOps Model

## Principle

> The Git repository is the single source of truth for cluster state.

Every change to infrastructure and applications flows through a pull request in this repository. The cluster converges to match the desired state declared in Git.

## Current State

| Layer | Method | Target |
|-------|--------|--------|
| OS bootstrap | Manual script execution | Phase 0 |
| Cluster init | Manual kubeadm | Phase 1 |
| Platform add-ons | `kubectl apply` | Phase 2 |
| Apps | Not yet deployed | Phase 3 |

## Target State

```
Developer / AI Operator
       │
       ▼
   Pull Request
       │
       ▼
  GitHub Actions ──► Lint, Validate
       │
       ▼
   Merge to main
       │
       ▼
  GitOps Controller ──► Reconcile cluster
  (Flux / ArgoCD)
       │
       ▼
  Kubernetes Cluster
```

## Repository as Control Plane

| Directory | Synced by | Scope |
|-----------|-----------|-------|
| `platform/` | GitOps controller | Infrastructure add-ons |
| `apps/` | GitOps controller | Application workloads |
| `cluster/` | Manual / kubeadm | Cluster-level config |
| `bootstrap/` | Manual execution | One-time node setup |

## PR Workflow

1. Changes proposed via branch + PR
2. GitHub Actions validates:
   - YAML lint
   - Shell script lint
   - Kubernetes manifest validation
3. Human or AI operator reviews
4. Merge to `main`
5. GitOps controller detects change and reconciles

## Conventions

- All Kubernetes manifests in YAML
- One component per directory under `platform/` or `apps/`
- Each component directory contains a `kustomization.yaml` or raw manifests
- No `kubectl apply` from local machine in steady state (Phase 2+)
- Secrets managed via Sealed Secrets or SOPS (planned)
