# Network

## Physical Network

| Item | Value |
|------|-------|
| LAN | 192.168.1.0/24 |
| Gateway | 192.168.1.1 |
| DNS | 192.168.1.1 (via systemd-resolved) |

## Node IPs

| Node | IP | Interface |
|------|----|-----------|
| control-01 | 192.168.1.202 | eno1 |

## Kubernetes Networks

| Network | CIDR | Purpose |
|---------|------|---------|
| Pod | 192.168.0.0/16 | Calico-managed pod IPs |
| Service | 10.96.0.0/12 | ClusterIP services |
| DNS | 10.96.0.10 | CoreDNS |

## CNI: Calico

- Mode: VXLAN (default)
- Version: v3.29.3
- IPAM: Calico IPAM
- Network policy: Supported

## Planned

- **MetalLB**: L2 mode for LoadBalancer services (IP range TBD)
- **ingress-nginx**: HTTP/HTTPS ingress controller
