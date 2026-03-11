#!/usr/bin/env python3
"""
Generate a GitHub App installation access token.

Usage:
    python3 scripts/github-app-token.py
    python3 scripts/github-app-token.py --format=export   # output as shell export
    python3 scripts/github-app-token.py --format=mask     # show masked token + expiry

Reads config from environment variables (or .env file):
    GITHUB_APP_ID           - GitHub App ID
    GITHUB_APP_INSTALLATION_ID - Installation ID
    GITHUB_APP_PEM_FILE     - Path to private key PEM file

Exit codes:
    0 - success
    1 - missing dependencies or config
    2 - authentication failure
"""

import sys
import os
import time
import json
import argparse

# ---------------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------------
try:
    import jwt
except ImportError:
    print("ERROR: PyJWT not installed. Run: pip install PyJWT", file=sys.stderr)
    sys.exit(1)

try:
    import urllib.request
    import urllib.error
except ImportError:
    print("ERROR: urllib not available", file=sys.stderr)
    sys.exit(1)


def load_dotenv(path: str) -> None:
    """Minimal .env loader — no external dependency needed."""
    if not os.path.isfile(path):
        return
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip("\"'")
            if key not in os.environ:  # don't override existing env
                os.environ[key] = value


def get_config() -> tuple[str, str, str]:
    """Return (app_id, installation_id, pem_path) or exit with error."""
    # Try loading .env from project root (two levels up from bootstrap/scripts/)
    project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    load_dotenv(os.path.join(project_root, ".env"))

    app_id = os.environ.get("GITHUB_APP_ID", "")
    installation_id = os.environ.get("GITHUB_APP_INSTALLATION_ID", "")
    pem_file = os.environ.get("GITHUB_APP_PEM_FILE", "")

    errors = []
    if not app_id:
        errors.append("GITHUB_APP_ID is not set")
    if not installation_id:
        errors.append("GITHUB_APP_INSTALLATION_ID is not set")
    if not pem_file:
        errors.append("GITHUB_APP_PEM_FILE is not set")
    elif not os.path.isfile(pem_file):
        errors.append(f"PEM file not found: {pem_file}")

    if errors:
        for e in errors:
            print(f"ERROR: {e}", file=sys.stderr)
        print("\nSee .env.example for required variables.", file=sys.stderr)
        sys.exit(1)

    return app_id, installation_id, pem_file


def generate_jwt(app_id: str, pem_path: str) -> str:
    """Generate a short-lived JWT for the GitHub App."""
    with open(pem_path) as f:
        private_key = f.read()

    now = int(time.time())
    payload = {
        "iat": now - 60,       # 60s grace for clock skew
        "exp": now + (10 * 60),  # 10 min max allowed by GitHub
        "iss": int(app_id),
    }
    return jwt.encode(payload, private_key, algorithm="RS256")


def request_access_token(jwt_token: str, installation_id: str) -> dict:
    """Exchange JWT for an installation access token."""
    url = f"https://api.github.com/app/installations/{installation_id}/access_tokens"
    headers = {
        "Authorization": f"Bearer {jwt_token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }

    req = urllib.request.Request(url, headers=headers, method="POST")
    try:
        resp = urllib.request.urlopen(req)
        return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"ERROR: GitHub API returned {e.code}", file=sys.stderr)
        # Don't leak full response — just the message
        try:
            msg = json.loads(body).get("message", body[:200])
        except json.JSONDecodeError:
            msg = body[:200]
        print(f"  {msg}", file=sys.stderr)
        sys.exit(2)


def mask_token(token: str) -> str:
    """Show first 4 and last 4 chars only."""
    if len(token) <= 12:
        return "****"
    return f"{token[:8]}...{token[-4:]}"


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate GitHub App access token")
    parser.add_argument(
        "--format",
        choices=["token", "export", "mask", "json"],
        default="token",
        help="Output format (default: raw token)",
    )
    args = parser.parse_args()

    app_id, installation_id, pem_file = get_config()
    jwt_token = generate_jwt(app_id, pem_file)
    data = request_access_token(jwt_token, installation_id)

    token = data["token"]
    expires_at = data.get("expires_at", "unknown")

    if args.format == "token":
        print(token)
    elif args.format == "export":
        print(f"export GITHUB_TOKEN='{token}'")
        print(f"# Expires: {expires_at}")
    elif args.format == "mask":
        print(f"Token: {mask_token(token)}")
        print(f"Expires: {expires_at}")
        perms = data.get("permissions", {})
        if perms:
            print(f"Permissions: {', '.join(f'{k}:{v}' for k, v in perms.items())}")
    elif args.format == "json":
        safe = {
            "token_preview": mask_token(token),
            "expires_at": expires_at,
            "permissions": data.get("permissions", {}),
        }
        print(json.dumps(safe, indent=2))


if __name__ == "__main__":
    main()
