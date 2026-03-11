# CLAUDE.md — Project Instructions for Claude Code

## Project
k8s-homelab — Kubernetes homelab managed by ben-ai-ops via GitHub App automation.

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
- Owner: ben-ai-ops (GitHub organization/user)

## GitHub App Authentication
- App: `ben-ai-ops-k8s` (ID: 3063256)
- Installation ID: 115555335
- PEM file: `.github-apps/ben-ai-ops-k8s.2026-03-11.private-key.pem`
- Token script: `bootstrap/scripts/github-app-token.py`
- Tokens expire in 1 hour — regenerate as needed

### Quick reference
```bash
# Check auth is working
bash bootstrap/scripts/github-auth-check.sh

# Export token to shell
source bootstrap/scripts/export-github-token.sh

# Configure git remote with App token
bash bootstrap/scripts/git-use-app-token.sh

# Refresh token before push (if >1hr since last setup)
bash bootstrap/scripts/git-use-app-token.sh && git push origin main
```

## Communication
- 使用中文與使用者溝通
- 執行前先寫 script，減少不必要的 API/token 消耗
- 先展示計畫，確認後再執行

## Rules
- NEVER commit or log secrets (tokens, PEM files, .env, join commands)
- NEVER push without explicit user approval
- NEVER amend commits without being asked
- NEVER expose sudo passwords or sensitive credentials in files
- Always use `set -Eeuo pipefail` in bash scripts
- Mask tokens in any output (show first 8 + last 4 chars only)
- Use `.env` for local config — it is gitignored
- `bootstrap/kubeadm-init-output.txt` and `bootstrap/worker-join-command.sh` are gitignored
- Before pushing, check for sensitive data in staged files

## Project Structure
```
.
├── CLAUDE.md
├── .env                                # Local secrets (gitignored)
├── .env.example
├── .gitignore
├── .yamllint.yaml
├── .github-apps/                       # PEM keys (gitignored)
├── .github/workflows/
│   └── lint.yaml                       # YAML lint + ShellCheck
├── bootstrap/
│   ├── scripts/
│   │   ├── k8s-node-bootstrap.sh       # OS prep for k8s nodes
│   │   ├── github-app-token.py         # Generate access token
│   │   ├── export-github-token.sh      # Export GITHUB_TOKEN
│   │   ├── git-use-app-token.sh        # Set git remote with token
│   │   └── github-auth-check.sh        # Verify auth end-to-end
│   ├── kubeadm-init-output.txt         # (gitignored)
│   └── worker-join-command.sh           # (gitignored)
├── cluster/
│   └── kubeadm/
│       └── kubeadm-config.yaml
├── platform/
│   └── calico/
├── apps/
└── docs/
    ├── architecture.md
    ├── network.md
    ├── github-app-setup.md
    ├── claude-workflow.md
    ├── control-plane-init-summary.md
    └── runbooks/
        └── bootstrap.md
```
