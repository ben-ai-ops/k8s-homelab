# Control Plane Initialization Summary

## Cluster Info

| Item | Value |
|------|-------|
| Node | `control-01` |
| IP | `192.168.1.202` |
| Role | control-plane |
| Kubernetes | v1.32.13 |
| Container Runtime | containerd 1.7.28 |
| CNI | Calico v3.29.3 |
| Pod CIDR | `192.168.0.0/16` |
| Service CIDR | `10.96.0.0/12` (default) |
| API Server | `192.168.1.202:6443` |
| Init Date | 2026-03-11 |

## What was done

1. `kubeadm init` with `--apiserver-advertise-address=192.168.1.202 --pod-network-cidr=192.168.0.0/16`
2. Configured `~/.kube/config` for user `ben`
3. Installed Calico CNI from official manifest

## Join command for workers

```bash
sudo kubeadm join 192.168.1.202:6443 --token 05wyzr.yuzvhe484ed5uiyj \
    --discovery-token-ca-cert-hash sha256:87e6771a525799384797da2fe6a8929374d42c28752842f50fa2ee743958ccea
```

Token expires after 24 hours. Regenerate with:
```bash
kubeadm token create --print-join-command
```

## Installed components

| Component | Status |
|-----------|--------|
| etcd | Static pod, running |
| kube-apiserver | Static pod, running |
| kube-controller-manager | Static pod, running |
| kube-scheduler | Static pod, running |
| kube-proxy | DaemonSet, running |
| CoreDNS | Deployment (2 replicas) |
| Calico | DaemonSet + controller |

## Not yet installed

- MetalLB
- ingress-nginx
- Helm
- NFS storage provisioner
- Monitoring (Prometheus/Grafana)
