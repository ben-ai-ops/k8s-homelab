# Cluster Lifecycle

## Phases

```
Phase 0          Phase 1          Phase 2          Phase 3
─────────        ─────────        ─────────        ─────────
OS Prep    →    Cluster Init  →  Platform     →   Apps
                                  Add-ons          Workloads

node-prep.sh    kubeadm init     Calico           User apps
containerd      kubectl config   MetalLB          deployed via
kubelet/kubeadm CNI install      ingress-nginx    GitOps
                                 storage
```

## Phase 0: OS Bootstrap

Prepare bare-metal nodes with required packages and kernel config.

- Script: `bootstrap/scripts/node-prep.sh`
- Idempotent, safe to re-run
- Targets: Ubuntu 24.04 LTS

| Action | Detail |
|--------|--------|
| Disable swap | Runtime + fstab |
| Kernel modules | overlay, br_netfilter |
| Sysctl | ip_forward, bridge-nf-call |
| containerd | Install, SystemdCgroup=true |
| kubeadm/kubelet/kubectl | Install + version hold |

## Phase 1: Cluster Initialization

Initialize the first control plane node.

- Config: `bootstrap/kubeadm/kubeadm-config.yaml`
- Script: `bootstrap/scripts/kubeadm-init.sh`
- Runbook: `docs/runbooks/bootstrap-control-plane.md`

| Action | Detail |
|--------|--------|
| kubeadm init | Single control plane |
| kubectl config | User kubeconfig |
| CNI | Calico v3.29.3 |
| Verify | Node Ready, system pods running |

## Phase 2: Platform Add-ons

Infrastructure services deployed to the cluster.

| Component | Directory | Status |
|-----------|-----------|--------|
| Calico CNI | `platform/calico/` | Deployed |
| MetalLB | `platform/metallb/` | Planned |
| ingress-nginx | `platform/ingress-nginx/` | Planned |
| NFS provisioner | `platform/storage/` | Planned |
| Monitoring | `platform/monitoring/` | Planned |

## Phase 3: Application Workloads

User applications deployed via GitOps.

| Component | Directory | Status |
|-----------|-----------|--------|
| GitOps controller | `platform/flux/` or `platform/argocd/` | Planned |
| App manifests | `apps/` | Planned |

## Day-2 Operations

| Task | Method |
|------|--------|
| Add worker node | `node-prep.sh` → `kubeadm join` |
| Upgrade k8s | Update version in config → `kubeadm upgrade` |
| Add platform component | PR to `platform/` → GitOps sync |
| Deploy app | PR to `apps/` → GitOps sync |
| Certificate rotation | `kubeadm certs renew` |
| etcd backup | `etcdctl snapshot save` |
