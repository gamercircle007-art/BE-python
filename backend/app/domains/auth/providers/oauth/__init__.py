"""
OAuth provider package — Google / Apple Sign In (future).

IMPLEMENTATION CHECKLIST:
  1. Create google.py implementing OAuthProvider.verify_id_token()
  2. Add POST /auth/oauth/google route in router.py
  3. On success: find-or-create user by email, issue JWT via TokenService
  4. Store google sub in user_identities table (recommended)
  5. Configure GOOGLE_OAUTH_ENABLED=true and client credentials in .env
"""