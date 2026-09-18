# Deploy and Host Speakr on Railway

Speakr is an open-source, privacy-focused AI audio-notes app: upload or record audio and get transcripts, AI
summaries and titles, speaker labels, and a searchable, shareable note library — all on your own infrastructure,
using your own transcription and LLM providers. This template deploys the self-hosted Speakr server with your admin
account set from the template's variables and registration closed. It is a community-maintained template based on
Speakr; it is not affiliated with, endorsed by, or an official offering of the Speakr project, and it does not use
the Speakr logo.

## About Hosting Speakr

Speakr runs as a single self-hosted server that serves its web app and REST API, storing recordings' metadata in
SQLite and the audio files on disk. Transcription (speech-to-text) and text generation (summaries, titles, chat) are
handled by external, OpenAI-compatible providers that you configure — the app itself keeps your recordings and notes
private on your own volume. It requires a login and its admin account is configured from environment variables, so a
weak or unset password would let anyone who finds the URL sign in.

This template runs Speakr on Railway with a generated admin password and registration turned off (so the instance is
admin-only from first boot), its data persisted on a volume, a secure session cookie, and the port and health check
wired. It runs the official image unmodified, pinned by digest, and asks you for your transcription and LLM API keys
at deploy time.

## Common Use Cases

- A private, self-hosted place to transcribe and summarise meetings, calls, lectures and voice memos.
- A searchable personal or team knowledge base built from your recordings, with per-recording sharing.
- An audio-notes backend you drive from your own OpenAI, OpenRouter, Azure OpenAI or self-hosted ASR/LLM providers.

## Dependencies for Speakr Hosting

- An OpenAI-compatible **transcription** provider (required to start) — e.g. OpenAI `whisper-1`, or a self-hosted ASR.
- An OpenAI-compatible **text/LLM** provider for summaries, titles and chat — e.g. OpenAI `gpt-4o-mini`, OpenRouter.
- Nothing else external: the database is embedded (SQLite on the volume) and audio files live alongside it.

### Deployment Dependencies

- Speakr: https://github.com/murtaza-nasir/speakr (dual AGPL-3.0 / commercial; deployed here under AGPL-3.0)
- Template repository and tests: https://github.com/youssefsiam38/speakr-railway

### Implementation Details

Speakr runs upstream's official `lite` image (no PyTorch; ~700 MB), pinned by digest and unmodified. The template
creates the admin account from `ADMIN_USERNAME` / `ADMIN_EMAIL` / a generated `ADMIN_PASSWORD` on first boot
(`SKIP_EMAIL_DOMAIN_CHECK=true` skips the DNS lookup on the admin email), sets `ALLOW_REGISTRATION=false` so sign-up
is closed, and secures sessions with a generated `SECRET_KEY` and `SESSION_COOKIE_SECURE=true`. It wires `PORT`
(8899), the public domain and the `/login` health check. Transcription and text generation are configured through
`TRANSCRIPTION_*` and `TEXT_MODEL_*` variables (default to OpenAI); with the defaults the same OpenAI key works for
both.

Tested in CI and on a live deployment of this template: the app is healthy, the web root requires a login, the API
rejects a request with no token and accepts the correct admin login, registration is closed, and a recording
uploaded through the API is transcribed and summarised end to end and survives a redeploy.

After deploying, copy `ADMIN_PASSWORD` from the service's variables and sign in at the app's domain (email
`ADMIN_EMAIL`, default `admin@example.com`). Invite additional users from the admin panel.

## Why Deploy Speakr on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you
don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Speakr on Railway, you are one step closer to supporting a complete full-stack application with minimal
burden. Host your servers, databases, AI agents, and more on Railway.
