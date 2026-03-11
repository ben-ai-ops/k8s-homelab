# CLAUDE.md — Project Instructions for Claude Code

## Project
k8s-homelab — Kubernetes homelab managed by ben-ai-ops via GitHub App automation.

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
```

## Rules
- NEVER commit or log secrets (tokens, PEM files, .env)
- NEVER push without explicit user approval
- NEVER amend commits without being asked
- Always use `set -Eeuo pipefail` in bash scripts
- Mask tokens in any output (show first 8 + last 4 chars only)
- Use `.env` for local config — it is gitignored

## Project Structure
```
.
├── CLAUDE.md                    # This file
├── .env                         # Local secrets (gitignored)
├── .env.example                 # Template for .env
├── .gitignore
├── .github-apps/                # PEM keys (gitignored)
├── scripts/
│   ├── github-app-token.py      # Generate installation access token
│   ├── export-github-token.sh   # Source to export GITHUB_TOKEN
│   ├── git-use-app-token.sh     # Configure git remote with token
│   └── github-auth-check.sh     # Verify auth end-to-end
└── docs/
    ├── github-app-setup.md      # App setup reference
    └── claude-workflow.md        # Claude Code workflow guide
```
