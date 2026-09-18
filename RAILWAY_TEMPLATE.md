# Railway template configuration

The template's exact configuration. Reproduce it from this file if it ever has to be rebuilt.

| | |
|---|---|
| Name | Speakr |
| Code | `speakr` |
| Template id | `8bef7ced-60ac-4049-b0bd-ebf3289419ca` |
| Deploy URL | https://railway.com/deploy/speakr |
| Category | AI/ML |
| Card description | Self-hosted AI audio transcription & notes with your own AI providers |
| Icon | `assets/icon.png` |
| Overview markdown | `marketplace/OVERVIEW.md` (Railway enforces its section headings) |

Generated values use Railway's `secret()` function: `hexN` is `${{secret(N, "abcdef0123456789")}}` and `alnumN` is
`${{secret(N, "a-zA-Z0-9")}}` spelled out. Alphanumeric passwords are used wherever a value is embedded in a
connection URL, so nothing needs percent-encoding. Images are referenced by tag, because the template generator
rejects digests; `UPSTREAM.md` records the digests.

## Services

### `app`

| Field | Value |
|---|---|
| Source | `learnedmachine/speakr:0.10.5-alpha-lite@sha256:a0f28aa2a562596447290c632e4c0c11fa2a7d3f751c9b759f7eee4316a50664` |
| Public domain | target port 8899 |
| Volume | `/data` |
| Healthcheck | `/login`, timeout from `RAILWAY_HEALTHCHECK_TIMEOUT_SEC` |
| Restart policy | on failure, 10 retries |

| Variable | Value |
|---|---|
| `PORT` | `8899` |
| `ADMIN_USERNAME` | `admin` |
| `ADMIN_EMAIL` | `admin@example.com` |
| `ADMIN_PASSWORD` | generated, alnum24 |
| `SKIP_EMAIL_DOMAIN_CHECK` | `true` |
| `SECRET_KEY` | generated, hex64 |
| `SESSION_COOKIE_SECURE` | `true` |
| `ALLOW_REGISTRATION` | `false` |
| `TEXT_MODEL_BASE_URL` | `https://api.openai.com/v1` |
| `TEXT_MODEL_NAME` | `gpt-4o-mini` |
| `TEXT_MODEL_API_KEY` | required input, no default |
| `TRANSCRIPTION_BASE_URL` | `https://api.openai.com/v1` |
| `TRANSCRIPTION_MODEL` | `whisper-1` |
| `TRANSCRIPTION_API_KEY` | required input, no default |
| `RAILWAY_HEALTHCHECK_TIMEOUT_SEC` | `300` |

## Notes

- **Single service, stock image.** Runs the official `learnedmachine/speakr` `lite` image (no PyTorch, ~700 MB),
  pinned by digest and unmodified, on a `/data` volume (SQLite + uploaded audio).
- **Admin from env, no bootstrap race.** `ADMIN_USERNAME` / `ADMIN_EMAIL` / a generated `ADMIN_PASSWORD` create the
  admin on first boot; `SKIP_EMAIL_DOMAIN_CHECK=true` avoids a DNS/MX lookup on the admin email;
  `ALLOW_REGISTRATION=false` keeps sign-up closed. Login is `POST /login` (email + password + `csrf_token`; a real
  browser's `Referer` satisfies Flask-WTF's strict-referer CSRF check over HTTPS). The API also accepts a personal
  Bearer token minted at `POST /api/tokens`.
- **Providers are required and deployer-supplied.** `TRANSCRIPTION_API_KEY` is a required input — with no
  transcription provider Speakr's connector fails to initialise and the process exits at startup. `TEXT_MODEL_API_KEY`
  powers summaries/titles/chat. Both default to OpenAI, so one OpenAI key works for both.
- **`PORT` = 8899** = gunicorn's fixed bind = the domain target port; health check `/login` (public `200`; `/`
  redirects to it). `SESSION_COOKIE_SECURE=true` with a generated `SECRET_KEY`; Speakr honours `X-Forwarded-Proto`
  via ProxyFix. The image runs as root, so it writes the Railway-mounted volume without `RAILWAY_RUN_UID`.
- **Licence / brand.** Speakr is dual-licensed AGPL-3.0 / commercial; this template deploys it under the AGPL-3.0,
  unmodified. "Speakr" and its logo are the project's marks (not covered by the AGPL); the template is
  community-maintained, ships its own generic icon, and does not imply official status.
