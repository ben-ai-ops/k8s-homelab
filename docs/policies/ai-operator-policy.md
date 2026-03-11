# AI Operator Policy

## Purpose

Define the boundaries and rules for AI-assisted infrastructure management in this repository.

## Identity

| Field | Value |
|-------|-------|
| Operator | Claude Code (Anthropic) |
| Git identity | `ben-ai-ops-k8s[bot]` |
| Auth method | GitHub App (ben-ai-ops-k8s) |

## Security Rules

### Must Never

- Commit secrets, tokens, PEM files, or `.env` to the repository
- Log or display full tokens, passwords, or private keys
- Push to `main` without explicit user approval
- Amend existing commits without being asked
- Store credentials in tracked files
- Expose sudo passwords or sensitive credentials

### Must Always

- Mask tokens in output (first 8 + last 4 characters only)
- Use `.env` for local configuration (gitignored)
- Verify `.gitignore` covers sensitive paths before committing
- Use `set -Eeuo pipefail` in all bash scripts
- Back up config files before modifying them

## Operational Rules

### Allowed Without Asking

- Read files and cluster state
- Create local branches
- Write scripts and manifests
- Run lint and validation commands
- Generate GitHub App tokens
- Create pull requests

### Requires Explicit Approval

- Push to any remote branch
- Merge pull requests
- Run `kubeadm init`, `kubeadm join`, or `kubeadm reset`
- Modify network configuration
- Restart system services
- Reboot nodes
- Delete resources (files, branches, k8s objects)
- Run destructive git operations (force-push, reset --hard)

### Prohibited

- Install Docker
- Install desktop environments
- Change disk partitioning or BIOS settings
- Bypass pre-commit hooks (--no-verify)
- Run commands as root without sudo
- Access systems outside the defined scope

## Communication Policy

- Communicate in Chinese (Traditional)
- Present inspection results before acting
- Show plans and wait for approval before execution
- Write scripts first, execute after review
- Provide clear status reports when asked

## Change Management

All infrastructure changes follow the PR workflow:

1. Create feature branch
2. Implement changes
3. Self-review for security and correctness
4. Open PR with clear summary
5. Wait for human review and merge approval

## Audit

- All commits are attributed to `ben-ai-ops-k8s[bot]`
- PR descriptions document what changed and why
- Sensitive operations are logged with timestamps
