# Marketplace audit

A record of the diligence behind publishing this template.

## Identity

- Template: **Speakr** — a self-hosted, privacy-focused AI audio-notes app (transcription, AI summaries/titles,
  speaker labels, searchable and shareable notes, MCP-style API).
- Upstream: [murtaza-nasir/speakr](https://github.com/murtaza-nasir/speakr), dual AGPL-3.0 / commercial, active.

## Licence and brand

- **Dual AGPL-3.0 / commercial** (`licenses/SPEAKR-LICENSE` holds the AGPL text). This template deploys Speakr under
  the AGPL-3.0, which permits running it as a service; the image is used unmodified, so no additional
  source-disclosure obligation is created by this template. AGPL has no "competing use" restriction, so publishing a
  Marketplace template is permitted. A commercial licence remains available upstream for those who want to avoid the
  AGPL for their own modifications.
- **Brand.** "Speakr" and its logo are the project's marks and are not covered by the AGPL. This template is
  community-maintained, states only that it is based on Speakr, does not use the Speakr logo (it ships its own
  generic icon), and does not imply official status. See `THIRD_PARTY_NOTICES.md`.

## Security review

- **Admin login enforced, registration closed, no bootstrap race.** The admin is set from `ADMIN_USERNAME` /
  `ADMIN_EMAIL` / a generated `ADMIN_PASSWORD`, and `ALLOW_REGISTRATION=false`. `/` redirects to `/login`;
  `/api/v1/*` returns `401` without a session or Bearer token; a wrong password does not authenticate — verified
  live. `SESSION_COOKIE_SECURE=true` with a stable generated `SECRET_KEY`.
- **Secret hygiene.** The admin password is generated; the tests read it from a mode-restricted file and never print
  it; the static test greps the tree for credential shapes. The provider API keys are the deployer's own Railway
  variables.
- **Reproducible.** The image is pinned by digest (multi-arch).

## Reproducibility & tests

- `tests/static.sh` (20 checks): syntax, shellcheck, mock compiles, compose shape, digest pin, admin/provider wiring,
  closed-registration posture, secret scan.
- `tests/smoke.sh` (13 checks): health, the `/` login redirect, the `/api/v1` 401 gate, closed registration, a wrong
  password rejected, admin login, API-token mint, and a real upload -> transcribe -> summarise round trip (driven
  against a local stdlib mock OpenAI-compatible provider so no real key is spent).
- `tests/persistence.sh` (5 checks): a transcribed recording and the admin account survive a restart (SQLite +
  files on the volume).
- `tests/railway-smoke.sh`: the same flows over HTTPS against the deployed template (the upload->transcribe leg is
  exercised live against a mock provider reachable from the deployment).
- CI runs static + smoke + persistence on every push (no image build — the official image is used unmodified).

## Deploy-time inputs

- `TRANSCRIPTION_API_KEY` — **required** (the app will not start without a transcription provider). Defaults target
  OpenAI `whisper-1`.
- `TEXT_MODEL_API_KEY` — **required** for summaries/titles/chat. Defaults target OpenAI `gpt-4o-mini`. With the
  defaults the same OpenAI key works for both.
- `ADMIN_PASSWORD` — generated (copy it to sign in). `ADMIN_EMAIL` defaults to `admin@example.com`.
- Everything else is fixed by the template (port, health check, volume, closed registration, secure cookie).

## Verdict

Shippable. A self-contained, reproducible, admin-authenticated single-service deployment with closed registration,
whose auth, persistence and the full transcribe/summarise pipeline are verified on a live Railway deployment, with
brand use limited per the project's policy and the AGPL honoured.
