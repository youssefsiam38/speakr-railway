# Architecture

## Service graph

```
        Railway HTTPS edge
              │
              ▼
   ┌──────────────────────────────────────────────┐        your providers (over HTTPS)
   │  app  (public domain :8899)                    │        ┌───────────────────────────┐
   │  the Speakr self-hosted server (gunicorn):     │───────▶│ transcription (speech->text)│
   │   - web app          GET /        (login)      │        │  TRANSCRIPTION_BASE_URL     │
   │   - login page       GET /login   (public)     │        └───────────────────────────┘
   │   - REST API         /api/v1/*    (token/session)       ┌───────────────────────────┐
   │   - api tokens       /api/tokens  (session)    │───────▶│ text/LLM (summaries, chat)  │
   │  volume: /data                                 │        │  TEXT_MODEL_BASE_URL        │
   │   - SQLite (users, recordings, transcripts)    │        └───────────────────────────┘
   │   - uploaded audio (/data/uploads)             │
   └──────────────────────────────────────────────┘
```

One service. Speakr runs a single Flask/gunicorn server that serves the web app and the REST API, storing metadata
in SQLite and audio files on the `/data` volume. Transcription and text generation are **external, deployer-supplied
OpenAI-compatible providers** — nothing else runs in the deployment.

## The app service

- Image: the official `learnedmachine/speakr` (the `lite` variant — no PyTorch, ~700 MB; all features work, only
  Inquire Mode's semantic search falls back to text search), pinned by digest, used unmodified.
- **Port:** `8899`. Speakr's gunicorn binds `0.0.0.0:8899`; the template sets `PORT=8899`, the public domain's target
  port to `8899`, and the health check to `/login` (a public `200`) — all aligned. (Railway routes both the edge and
  the health check to `$PORT`.)
- **Admin from env, no bootstrap race.** The image entrypoint creates the admin from `ADMIN_USERNAME`, `ADMIN_EMAIL`
  and the generated `ADMIN_PASSWORD` on first boot (`SKIP_EMAIL_DOMAIN_CHECK=true` skips the DNS/MX lookup on the
  admin email). `ALLOW_REGISTRATION=false` keeps sign-up closed. There is no first-run "create admin" page to race on
  a public URL.
- **Sessions.** `SECRET_KEY` is set (stable session/CSRF signing across restarts) and `SESSION_COOKIE_SECURE=true`
  (the cookie is only sent over HTTPS). Speakr already trusts Railway's `X-Forwarded-Proto` via ProxyFix.
- **Volume:** `/data` holds the SQLite database (`/data/instance`) and uploaded audio (`/data/uploads`). The image
  runs as root, so it can write the Railway-mounted volume without extra configuration.

## Providers

- **Transcription** (`TRANSCRIPTION_BASE_URL` / `TRANSCRIPTION_MODEL` / `TRANSCRIPTION_API_KEY`): an OpenAI-compatible
  speech-to-text endpoint (default OpenAI `whisper-1`). Required — the app validates a transcription provider at
  startup and exits if none is configured.
- **Text/LLM** (`TEXT_MODEL_BASE_URL` / `TEXT_MODEL_NAME` / `TEXT_MODEL_API_KEY`): an OpenAI-compatible chat endpoint
  (default OpenAI `gpt-4o-mini`) for summaries, titles and chat.

Both are read from environment variables at process start, so changing a provider is a variable change plus a
redeploy.
