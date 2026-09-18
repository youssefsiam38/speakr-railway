# Speakr on Railway

A one-click [Railway](https://railway.com) template that runs [Speakr](https://github.com/murtaza-nasir/speakr) —
an open-source, privacy-focused AI audio-notes app. Upload or record audio and get transcripts, AI summaries and
titles, speaker labels and a searchable, shareable note library — all on your own infrastructure, using **your own
transcription and LLM providers**.

> **Community-maintained and not affiliated.** This template is based on Speakr but is **not affiliated with,
> endorsed by, or an official offering of** the Speakr project, and it does not use the Speakr logo. See
> [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

- **Image:** the official `learnedmachine/speakr` (the `lite` variant, ~700 MB, no PyTorch), pinned by digest and
  used unmodified — see [UPSTREAM.md](UPSTREAM.md).
- Speakr is **dual-licensed AGPL-3.0 / commercial**; this template deploys it under the **AGPL-3.0**. See
  [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for what that means for you.

## What you get

- One service: the Speakr web app + REST API, with SQLite and your audio files on a `/data` volume.
- A **generated admin password** (`ADMIN_PASSWORD`). Registration is **closed** (`ALLOW_REGISTRATION=false`), so only
  the admin account exists until you invite users — a stranger who finds your URL cannot sign up or read your notes.
- **Bring-your-own AI.** Speakr calls an OpenAI-compatible transcription (speech-to-text) provider and a text/LLM
  provider (summaries, titles, chat). You supply the keys at deploy; they stay your credentials.

## Deploy

You will be asked for two API keys at deploy time:

1. **`TRANSCRIPTION_API_KEY`** — for the speech-to-text provider (required; the app will not start without a
   transcription provider). Defaults target OpenAI's `whisper-1`.
2. **`TEXT_MODEL_API_KEY`** — for the text/LLM provider used for summaries, titles and chat. Defaults target OpenAI
   `gpt-4o-mini`.

With the OpenAI defaults you can paste the **same OpenAI API key** into both. To use a different provider (OpenRouter,
Azure OpenAI, a self-hosted ASR, etc.), change the `*_BASE_URL` / `*_MODEL` variables — see
[Speakr's docs](https://murtaza-nasir.github.io/speakr).

Then:

1. Click **Deploy on Railway**, provide the keys, and wait for the service to go healthy.
2. Open the service → **Variables** and copy `ADMIN_PASSWORD` (sign in with `ADMIN_EMAIL`, default
   `admin@example.com`).
3. Open the public domain, sign in, and upload or record your first note.

## Security

- The admin login gates the app and the API; registration is closed by default. Treat `ADMIN_PASSWORD` like a
  password and rotate it by changing the variable. See [SECURITY.md](SECURITY.md).

## Repository layout

| Path | What |
|---|---|
| `compose.yaml` | Local test topology (the official image + a mock provider + a volume) |
| `tests/` | Static, smoke, persistence, and live (HTTPS) tests |
| `tests/mock/` | A tiny stdlib OpenAI-compatible stub so the tests exercise transcribe/summarise without a real key |
| `marketplace/OVERVIEW.md` | The marketplace overview shown on the template page |
| `RAILWAY_TEMPLATE.md` | The exact published template configuration |
| `UPSTREAM.md` · `SECURITY.md` · `ARCHITECTURE.md` · `MAINTENANCE.md` | Reference docs |

## Local development

```bash
# Runs the official image plus a mock transcription/LLM provider (tests/mock), so the full
# upload -> transcribe -> summarise pipeline runs without spending a real API key.
SPEAKR_TEST_PASSWORD=change-me docker compose up
tests/smoke.sh         # health, login/registration gates, admin login, upload -> transcribe -> summarise
tests/persistence.sh   # the admin, a recording and its transcript survive a restart
```

## Licence

The template's own files are MIT (`LICENSE`). Speakr is dual-licensed AGPL-3.0 / commercial and is deployed here
under the AGPL-3.0; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
