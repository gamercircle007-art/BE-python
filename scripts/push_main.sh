#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== Git status (before) ==="
git status

echo ""
echo "=== Staging all changes ==="
git add -A

echo ""
echo "=== Committing ==="
git commit -m "feat: OTP login flow, bind APIs to Paythan Flutter UI

- Add POST /auth/login/request-otp and /auth/login/verify-otp endpoints
- Flutter login: phone only then OTP screen
- Bind signup/login APIs to Paythan UI
- Rename branding to Paythan throughout" || echo "Nothing new to commit."

echo ""
echo "=== Pushing to origin main ==="
git push origin main

echo ""
echo "=== Done ==="
git log --oneline -3