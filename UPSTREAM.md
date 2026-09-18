# Upstream and pinned versions

This template runs **Speakr** (the upstream project by murtaza-nasir) from its official image, pinned by digest.
There is no wrapper image — the application is used unmodified and configured through environment variables.

## Speakr

- Project: https://github.com/murtaza-nasir/speakr
- Docs: https://murtaza-nasir.github.io/speakr
- Licence: dual **AGPL-3.0 / commercial** (`licenses/SPEAKR-LICENSE` holds the AGPL-3.0 text). This template deploys
  it under the AGPL-3.0.
- Official image: `learnedmachine/speakr` (Docker Hub)
- Pinned: `learnedmachine/speakr:0.10.5-alpha-lite`
  - digest `sha256:a0f28aa2a562596447290c632e4c0c11fa2a7d3f751c9b759f7eee4316a50664`
  - multi-arch (linux/amd64, linux/arm64)

## Why the `lite` image

The `lite` variant omits PyTorch (~700 MB vs ~4.4 GB), so deploys are fast and cheap. All features work; only Inquire
Mode's semantic search falls back to basic text search. Transcription and summaries use your configured external
providers regardless, so the lite image loses nothing for the common workflow. To switch to the full image, change
the tag to `0.10.5-alpha` (and its digest) — see below.

## Refreshing a digest

```bash
# lite tag digest:
docker buildx imagetools inspect learnedmachine/speakr:<version>-lite --format '{{json .Manifest}}' | jq -r .digest
```

Update the pins here, in `compose.yaml`, and in `_audit/spec_speakr.py`, then re-run the tests and re-point the
template at the new tag. See `MAINTENANCE.md`.
