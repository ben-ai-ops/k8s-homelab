# Runbook: Node Bootstrap

## Purpose

Prepare a fresh Ubuntu 24.04 LTS machine as a Kubernetes node.

## Prerequisites

- Ubuntu 24.04 LTS (server, minimal install)
- Network connectivity
- sudo access

## Steps

### 1. OS Bootstrap

```bash
sudo bash bootstrap/scripts/k8s-node-bootstrap.sh
```

This handles:
- Disable swap
- Load kernel modules (overlay, br_netfilter)
- Configure sysctl (ip_forward, bridge-nf-call)
- Install containerd with SystemdCgroup=true
- Install kubelet, kubeadm, kubectl
- Hold package versions

### 2. Initialize Control Plane (first node only)

```bash
sudo kubeadm init \
  --config cluster/kubeadm/kubeadm-config.yaml
```

Or with flags:
```bash
sudo kubeadm init \
  --apiserver-advertise-address=192.168.1.202 \
  --pod-network-cidr=192.168.0.0/16
```

### 3. Configure kubectl

```bash
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 4. Install CNI

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/calico.yaml
```

### 5. Join Worker Nodes

On each worker:
```bash
sudo bash bootstrap/scripts/k8s-node-bootstrap.sh
sudo kubeadm join 192.168.1.202:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

Regenerate join command if token expired:
```bash
kubeadm token create --print-join-command
```

### 6. Verify

```bash
kubectl get nodes -o wide
kubectl get pods -n kube-system
```

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Node NotReady | CNI not installed | Install Calico |
| kubelet crashloop | Swap enabled | `swapoff -a` |
| connection refused :6443 | API server not up | Check `crictl ps`, wait |
| token expired | >24h since init | `kubeadm token create --print-join-command` |
