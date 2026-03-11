# GitHub App Setup Reference

## App Details

| Field | Value |
|-------|-------|
| Name | `ben-ai-ops-k8s` |
| App ID | `3063256` |
| Client ID | `Iv23li09lzr2DAsnBnNO` |
| Installation ID | `115555335` |
| Installed on | `ben-ai-ops` |

## Permissions

| Scope | Access |
|-------|--------|
| Actions | Read |
| Contents | Write |
| Issues | Write |
| Metadata | Read |
| Pull Requests | Write |

## Authentication Flow

```
┌──────────────┐     JWT (RS256)     ┌──────────────┐
│  Private Key  │ ──────────────────► │  GitHub API   │
│  (.pem file)  │                     │  /app         │
└──────────────┘                     └──────┬───────┘
                                            │
                                    POST /installations
                                      /{id}/access_tokens
                                            │
                                     ┌──────▼───────┐
                                     │ Access Token  │
                                     │ (1hr expiry)  │
                                     └──────────────┘
```

1. **JWT**: Signed with the PEM private key, valid for 10 minutes, identifies the App
2. **Installation Token**: Exchanged from JWT, valid for 1 hour, scoped to installed repos

## File Locations

| File | Path | Tracked? |
|------|------|----------|
| Private key | `.github-apps/ben-ai-ops-k8s.2026-03-11.private-key.pem` | NO (.gitignored) |
| Environment | `.env` | NO (.gitignored) |
| Token script | `bootstrap/scripts/github-app-token.py` | Yes |

## Key Rotation

When you rotate the App's private key:

1. Download new PEM from GitHub App settings
2. Place in `.github-apps/` with the new date in filename
3. Update `GITHUB_APP_PEM_FILE` in `.env`
4. Delete the old PEM file
5. Run `bash bootstrap/scripts/github-auth-check.sh` to verify

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `Bad credentials` (401) | JWT expired or wrong App ID | Regenerate JWT; check `GITHUB_APP_ID` |
| `Not Found` (404) | Wrong installation ID | Check `GITHUB_APP_INSTALLATION_ID` |
| PEM parse error | Corrupted or wrong format key | Re-download from App settings |
| Clock skew | Server time off by >60s | Sync system clock (`timedatectl`) |
