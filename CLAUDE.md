# CLAUDE.md — Project Instructions for Claude Code

## Project
k8s-homelab — Bare-metal Kubernetes homelab, AI-managed via GitHub App and PR workflow.

## Cluster

| Node | Role | IP | OS | Status |
|------|------|----|----|--------|
| control-01 | control-plane | 192.168.1.202 | Ubuntu 24.04.4 LTS | Ready |

- Kubernetes: v1.32.13
- Container Runtime: containerd 1.7.28
- CNI: Calico v3.29.3
- Pod CIDR: 192.168.0.0/16
- Service CIDR: 10.96.0.0/12
- API Server: 192.168.1.202:6443

## Repository
- Remote: https://github.com/ben-ai-ops/k8s-homelab
- Owner: ben-ai-ops

## GitHub App Authentication
- App: `ben-ai-ops-k8s` (ID: 3063256)
- Installation ID: 115555335
- PEM file: `.github-apps/ben-ai-ops-k8s.2026-03-11.private-key.pem`
- Token script: `bootstrap/scripts/github-app-token.py`
- Tokens expire in 1 hour — regenerate as needed

### Quick reference
```bash
bash bootstrap/scripts/github-auth-check.sh       # verify auth
source bootstrap/scripts/export-github-token.sh    # export token
bash bootstrap/scripts/git-use-app-token.sh        # configure git remote
```

## Communication
- 使用中文與使用者溝通
- 執行前先寫 script，減少不必要的 API/token 消耗
- 先展示計畫，確認後再執行

## Policy
See [docs/policies/ai-operator-policy.md](docs/policies/ai-operator-policy.md) for full policy.

### Must Never
- Commit secrets, tokens, PEM files, or `.env`
- Push to `main` without explicit approval
- Amend commits without being asked
- Expose passwords or credentials in output
- Run `kubeadm init/reset` without approval

### Must Always
- Mask tokens (first 8 + last 4 chars)
- Use `set -Eeuo pipefail` in bash scripts
- Propose changes via PR
- Present plan before execution

## Project Structure
```
bootstrap/
  scripts/                 node-prep.sh, kubeadm-init.sh, GitHub App auth
  kubeadm/                 kubeadm-config.yaml
  ansible/inventory/       lab.yml
cluster/kubeadm/           kubeadm-config.yaml (day-2 reference)
platform/calico/           CNI
apps/                      Application workloads
docs/
  architecture.md          Cluster architecture
  lifecycle.md             Cluster lifecycle phases
  gitops.md                GitOps model
  ai-operator.md           AI operator design
  network.md               Network design
  policies/                ai-operator-policy.md
  runbooks/                bootstrap-control-plane.md, bootstrap.md
  github-app-setup.md      GitHub App reference
  claude-workflow.md        Claude Code workflow
.github/workflows/         lint.yml, validate-k8s.yml, docs-check.yml (pending)
```

## Gitignored Sensitive Files
- `.env`
- `*.pem`
- `.github-apps/`
- `bootstrap/kubeadm-init-output.txt`
- `bootstrap/worker-join-command.sh`
