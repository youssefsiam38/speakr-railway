# Third-party notices

This template runs the following third-party software. It keeps its own licence; the template's own files are MIT
(see `LICENSE`).

## Speakr

- Source: https://github.com/murtaza-nasir/speakr
- Licence: **dual AGPL-3.0 / commercial** — the AGPL-3.0 text is in `licenses/SPEAKR-LICENSE`.
- Used unmodified from the official image `learnedmachine/speakr` (pinned by digest in `UPSTREAM.md`). This template
  adds no wrapper image and does not modify the application.

> **Dual-licence note.** Speakr is offered under the AGPL-3.0 **or** a separate commercial licence. This template
> deploys Speakr **under the AGPL-3.0**, which permits running it for yourself and your users. If you **modify**
> Speakr and make the modified version available to users over a network, the AGPL requires you to offer those users
> the corresponding source. This template does not modify Speakr, so it imposes no additional source-disclosure
> obligation on you. If you prefer not to be bound by the AGPL for your own modifications, a commercial licence is
> available from the Speakr maintainers — see the upstream README.

> **Trademark / brand.** "Speakr", its logo, and other brand identifiers are the marks of the Speakr project and are
> **not** covered by the AGPL. This is a community-maintained deployment template that is based on Speakr; it is
> **not affiliated with, endorsed by, or an official offering of** the Speakr project, and it does not use the Speakr
> logo (it ships its own generic icon).

## FFmpeg

The Speakr image bundles static FFmpeg/ffprobe binaries (LGPL/GPL, from the BtbN builds) to process uploaded media.
They are part of the upstream image and are used unmodified.

---

This template is community-maintained and is not affiliated with the Speakr project.
