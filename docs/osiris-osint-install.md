---
name: osiris-osint-install
description: "Osiris OSINT dashboard installed at ~/osiris on the Kali box — how it's built and run"
metadata: 
  node_type: memory
  type: project
  originSessionId: 468959f7-73df-4e18-a756-c0f623f293a9
  modified: 2026-09-26T15:16:26.661Z
---

Installed 2026-09-26: the OSINT dashboard Osiris (github.com/simplifaisoul/osiris, Next.js 16 + MapLibre) lives at `~/osiris`, built for production and served from `~/osiris/.next/standalone/server.js` on port 3000.

**Why:** `next.config.ts` sets `output: standalone`, so `npm start` / `next start` warns and is not the supported path — the standalone server is. Static assets must be copied in after every build (`cp -r .next/static .next/standalone/.next/ && cp -r public .next/standalone/`) or the UI loads unstyled.

**How to apply:** Rebuild = `npm run build` then re-copy static/public. Node is **v24.22.0 from NodeSource node_24.x** since 2026-10-18 (was v20.19.6; repo key fixed, see [[broken-third-party-apt-repos]]); standalone server verified on Node 24 (200 + css 200), `npm run build` not yet re-run on 24. `.env` is copied from `.env.example`; all core feeds are keyless, only the RECON scanner and a few enhanced feeds (NASA FIRMS, OpenSky, N2YO, AIS) need keys.
