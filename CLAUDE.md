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
- Token script: `scripts/github-app-token.py`
- Tokens expire in 1 hour — regenerate as needed

### Quick reference
```bash
# Check auth is working
bash scripts/github-auth-check.sh

# Export token to shell
source scripts/export-github-token.sh

# Configure git remote with App token
bash scripts/git-use-app-token.sh

# Refresh token before push (if >1hr since last setup)
bash scripts/git-use-app-token.sh && git push origin main
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
- `bootstrap/` is gitignored — contains join tokens and init output (local only)
- Before pushing, check for sensitive data in staged files

## Project Structure
```
.
├── CLAUDE.md                        # This file
├── .env                             # Local secrets (gitignored)
├── .env.example                     # Template for .env
├── .gitignore
├── .github-apps/                    # PEM keys (gitignored)
├── bootstrap/                       # Join tokens & init output (gitignored)
│   ├── kubeadm-init-output.txt
│   └── worker-join-command.sh
├── scripts/
│   ├── github-app-token.py          # Generate installation access token
│   ├── export-github-token.sh       # Source to export GITHUB_TOKEN
│   ├── git-use-app-token.sh         # Configure git remote with token
│   ├── github-auth-check.sh         # Verify auth end-to-end
│   └── k8s-node-bootstrap.sh        # OS bootstrap for k8s nodes
└── docs/
    ├── github-app-setup.md          # App setup reference
    ├── claude-workflow.md            # Claude Code workflow guide
    └── control-plane-init-summary.md # Cluster init reference
```
