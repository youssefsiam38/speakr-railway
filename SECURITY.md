# Security

## The admin login gates the app; registration is closed

Speakr requires a login. This template creates the admin account from environment variables —
`ADMIN_USERNAME`, `ADMIN_EMAIL`, and a **generated** `ADMIN_PASSWORD` — on first boot, and sets
`ALLOW_REGISTRATION=false`, so the deployment is admin-only until you invite users. There is no first-run
"create admin" step for a stranger to claim on a public URL. The web app root (`/`) redirects unauthenticated
visitors to `/login`, and the REST API (`/api/v1/*`) returns `401` without a valid session or Bearer token. A wrong
password does not authenticate. Verified in the smoke, persistence and live tests.

## What the template does

- **Generated admin password** (`ADMIN_PASSWORD`, 24 alphanumerics) — copy it from the service variables to sign in.
  Login and the auth endpoints have built-in rate limiting.
- **Closed registration** (`ALLOW_REGISTRATION=false`). Invite additional users from the admin panel.
- **Session security.** A generated `SECRET_KEY` signs sessions and CSRF tokens (stable across restarts), and
  `SESSION_COOKIE_SECURE=true` sends the session cookie only over HTTPS.
- **Pinned image.** The official image is pinned by digest (see `UPSTREAM.md`); the application is unmodified.
- **Secret hygiene.** No secret is committed; the tests read the admin password from a mode-restricted file over
  HTTPS and never print it; the static test greps the tree for credential shapes.

## What you should do

- **Copy and guard `ADMIN_PASSWORD`.** Anyone with it can read and manage your recordings. Rotate it by changing the
  variable (or from the account page after signing in).
- **Your provider API keys are yours.** `TRANSCRIPTION_API_KEY` and `TEXT_MODEL_API_KEY` are set as Railway
  variables and used only to call the providers you chose. Treat them like passwords; rotate at the provider.
- **Public sharing is per-recording and opt-in.** Speakr can generate public share links for individual recordings
  when you choose to; nothing is public by default.
- **Back up the `/data` volume** (SQLite + audio files) with Railway's volume backups.
- **Keep the image current.** Speakr ships security fixes (it runs FFmpeg on untrusted uploads); see `MAINTENANCE.md`
  for bumping the pinned digest.

## Reporting

For issues in Speakr itself, report upstream (it runs a coordinated security process). For issues specific to this
template's packaging, open an issue on the template repository.
