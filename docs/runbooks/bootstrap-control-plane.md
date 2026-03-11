# Runbook: Bootstrap Control Plane

## Purpose

Initialize the first Kubernetes control plane node from a freshly prepared Ubuntu 24.04 machine.

## Prerequisites

- [ ] Node OS bootstrapped (`bootstrap/scripts/node-prep.sh` completed)
- [ ] containerd running
- [ ] kubelet, kubeadm, kubectl installed
- [ ] Swap disabled
- [ ] Network connectivity to internet (for image pulls)

## Procedure

### 1. Verify node readiness

```bash
# Check required services
systemctl is-active containerd
swapon --show  # should be empty
lsmod | grep -E 'overlay|br_netfilter'
sysctl net.ipv4.ip_forward  # should be 1
```

### 2. Initialize control plane

Using the config file:
```bash
sudo bash bootstrap/scripts/kubeadm-init.sh
```

Or manually:
```bash
sudo kubeadm init --config bootstrap/kubeadm/kubeadm-config.yaml
```

Save the output — it contains the worker join command.

### 3. Configure kubectl

```bash
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 4. Install CNI (Calico)

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/calico.yaml
```

### 5. Wait for node Ready

```bash
kubectl get nodes -w
# Wait until STATUS shows "Ready"
```

### 6. Verify system pods

```bash
kubectl get pods -n kube-system
```

Expected:
| Pod | Status |
|-----|--------|
| etcd-control-01 | Running |
| kube-apiserver-control-01 | Running |
| kube-controller-manager-control-01 | Running |
| kube-scheduler-control-01 | Running |
| kube-proxy-* | Running |
| calico-node-* | Running |
| calico-kube-controllers-* | Running |
| coredns-* (x2) | Running |

### 7. Save join command

```bash
# The join command was in the kubeadm init output
# To regenerate:
kubeadm token create --print-join-command
```

## Current Cluster Facts

| Item | Value |
|------|-------|
| Control plane | control-01 (192.168.1.202) |
| Kubernetes | v1.32.13 |
| CNI | Calico v3.29.3 |
| Pod CIDR | 192.168.0.0/16 |
| Service CIDR | 10.96.0.0/12 |
| API endpoint | 192.168.1.202:6443 |

## Rollback

If initialization fails:
```bash
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd
sudo iptables -F && sudo iptables -t nat -F
```

**Warning**: This destroys all cluster state. Only use on a fresh setup.
