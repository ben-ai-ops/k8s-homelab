# AI Operator Model

## Overview

This repository uses Claude Code as an AI-assisted infrastructure operator. The AI operates under strict policy constraints and never takes unilateral action on the cluster.

## How It Works

```
User Intent
    │
    ▼
Claude Code (AI Operator)
    │
    ├──► Reads repo, docs, cluster state
    ├──► Proposes changes via branch + PR
    ├──► Writes scripts, manifests, docs
    │
    ▼
Human Review
    │
    ├──► Approve / Request changes
    │
    ▼
Merge → Cluster converges
```

## Capabilities

| Can Do | Cannot Do |
|--------|-----------|
| Read cluster state (`kubectl`) | Push to `main` directly |
| Write manifests and scripts | Run `kubeadm init/reset` without approval |
| Create branches and PRs | Delete branches or force-push |
| Generate tokens (GitHub App) | Store secrets in tracked files |
| Update documentation | Modify network config without asking |
| Run lint and validation | Reboot nodes without asking |

## Authentication

The AI operator authenticates to GitHub using the `ben-ai-ops-k8s` GitHub App:

- No personal access tokens
- Scoped permissions (contents, PRs, issues)
- Tokens expire in 1 hour
- All commits attributed to `ben-ai-ops-k8s[bot]`

## Workflow

1. User provides intent (natural language)
2. AI inspects current state
3. AI proposes a plan
4. User approves plan
5. AI implements changes locally
6. AI opens a PR for review
7. User reviews and merges
8. AI does not push to `main` without explicit approval

## Guardrails

See [AI Operator Policy](policies/ai-operator-policy.md) for the full policy document.

## Communication

- AI communicates in Chinese (Traditional) per user preference
- AI writes scripts before executing to reduce token consumption
- AI presents plans before implementation
- AI masks all sensitive values in output
