# Claude Code Workflow Guide

## Prerequisites

1. Clone the repo (if not already):
   ```bash
   bash bootstrap/scripts/git-use-app-token.sh  # sets up token first
   git clone https://github.com/ben-ai-ops/k8s-homelab.git
   ```

2. Create `.env` from template:
   ```bash
   cp .env.example .env
   # Edit if paths differ on your machine
   ```

3. Verify auth:
   ```bash
   bash bootstrap/scripts/github-auth-check.sh
   ```

## Daily Workflow

### 1. Start a session

```bash
cd ~/k8s-homelab

# Authenticate git with the App
bash bootstrap/scripts/git-use-app-token.sh

# Launch Claude Code
claude
```

### 2. Common operations

**Pull latest changes:**
```bash
git pull origin main
```

**Push changes (after Claude creates a commit):**
```bash
bash bootstrap/scripts/git-use-app-token.sh   # refresh token if >1hr
git push origin main
```

**Create a PR:**
```bash
source bootstrap/scripts/export-github-token.sh
# Use GITHUB_TOKEN with gh CLI or API calls
```

### 3. Token refresh

Tokens expire after 1 hour. If you get a 401 error:
```bash
bash bootstrap/scripts/git-use-app-token.sh
```

## Safety Rules

These are enforced in `CLAUDE.md` and apply to all Claude Code sessions:

| Rule | Why |
|------|-----|
| No push without approval | Prevents accidental deployments |
| No amend without asking | Protects commit history |
| No secrets in output | Tokens/keys stay local |
| Mask tokens in logs | `ghs_abc1...xyz9` format only |

## How the Scripts Connect

```
.env                          ← config (app id, pem path)
  │
  ▼
github-app-token.py           ← generates access token
  │
  ├──► export-github-token.sh ← exports to $GITHUB_TOKEN
  ├──► git-use-app-token.sh   ← sets git remote URL
  └──► github-auth-check.sh   ← validates everything works
```

## Revert to SSH

If you prefer SSH over HTTPS App token:
```bash
bash bootstrap/scripts/git-use-app-token.sh --remove
```
