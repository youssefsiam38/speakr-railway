# Maintenance

## Updating to a new upstream version

1. **Bump the pin.** Get the new `lite` digest (see `UPSTREAM.md`) and update `compose.yaml` and
   `_audit/spec_speakr.py`, and re-point the template's `app` image at the new tag.
2. **Run the tests locally.**
   ```bash
   tests/static.sh
   tests/smoke.sh
   tests/persistence.sh
   ```
3. **Re-verify on Railway.** Re-run the clean-room deploy + `tests/railway-smoke.sh` before updating the published
   template.

There is no wrapper image to build or publish — the template runs the official image unmodified, so CI only runs the
tests (plus a local mock provider so the transcribe/summarise pipeline is exercised end to end).

## Rebuilding the Railway template from scratch

The exact configuration is in `RAILWAY_TEMPLATE.md`. The generator spec is `_audit/spec_speakr.py`; the kit in
`_audit/` (`tplkit.py`) builds a skeleton, patches the template, and runs a clean-room deploy. Volumes, domains and
health checks are only set by `skeleton()`, so a change to those requires rebuilding from a skeleton; if
`verify_template` reports an empty volume right after create, delete the template and re-create it.

## Gotchas worth remembering

- **Transcription is required to boot.** With no transcription provider configured, Speakr's connector fails to
  initialise and the process exits at startup. `TRANSCRIPTION_API_KEY` is a required deploy input; the app is
  healthy only once a valid provider is set.
- **`PORT` = 8899** = gunicorn's fixed bind = the domain target port; the health check is `/login` (a public `200`;
  `/` redirects to it).
- **Admin from env, no bootstrap race.** `ADMIN_USERNAME`/`ADMIN_EMAIL`/`ADMIN_PASSWORD` create the admin at boot;
  `SKIP_EMAIL_DOMAIN_CHECK=true` avoids a DNS/MX lookup on the admin email (e.g. `admin@example.com`).
  `ALLOW_REGISTRATION=false` keeps sign-up closed. Login is `POST /login` (email + password + `csrf_token`), which
  302-redirects on success; the API also accepts a personal Bearer token minted at `POST /api/tokens`.
- **HTTPS session cookie.** `SESSION_COOKIE_SECURE=true` and a stable generated `SECRET_KEY`; Speakr honours
  Railway's `X-Forwarded-Proto` via ProxyFix.
- **`lite` vs full image.** The template ships `lite` (no PyTorch). The full image adds local embeddings for Inquire
  semantic search; switch tags if you need it (larger, slower first boot as it downloads models to `/data`).
- **The marketplace OVERVIEW needs `### Deployment Dependencies` as an H3** or Railway's publish rejects the readme.
