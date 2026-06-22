# Ghost Mirror — Cheap Model (v0)

Shippable **lite tier** built off the same app. Proves the product; final polish lives in [BLACKBOOK.md](./BLACKBOOK.md).

---

## What the user gets

1. **Local Linux PC on Mac** — Ubuntu in a window (Apple Virtualization)
2. **Ghost Cloud bridge** — one button opens vault in browser
3. **Cloud desktop (bonus)** — VPS Linux in browser (chocolate teapot, but real)
4. **GhostHome path** — shared folder wired on VM start

## What we deliberately skip

- Mac ↔ Linux clipboard
- In-app cloud desktop WebView
- In-app VPS provisioning wizard
- Notarized installer / Gumroad
- Pretty onboarding

---

## App behaviour (cheap mode)

Default on launch. **View → Full Mode** unlocks engineer sidebar (provision VPS, WebView, IP field).

| Button | Action |
|--------|--------|
| Start / Stop | Local VM |
| Open Ghost Cloud | Browser → `GHOST_MIRROR_GHOST_URL` |
| Cloud Desktop | Runs `connect-cloud-desktop.sh` → browser |
| Download ISO | Same as before |
| Black Book | Opens `BLACKBOOK.md` in default editor |

Scripts do the work — no copy/paste from chat.

---

## Build & run

```bash
cd ~/ghost-mirror && ./scripts/build.sh --release
open "Ghost Mirror.app"
```

Local mirror default: **Ghost Mirror** (4 GB RAM / 32 GB disk).  
Next human step: **Start** → install Ubuntu → **Mark Installed**.

---

## Upgrade path → Final build

Work through [BLACKBOOK.md](./BLACKBOOK.md) checklist in order:

1. Clipboard (biggest UX gap)
2. Cloud stability (browser is OK for v1; polish WebView optional)
3. GhostHome UX in guest
4. Sign + sell

---

## Positioning (draft)

- **Cheap model:** “Linux on your Mac + Ghost Cloud vault. Cloud desktop included as beta.”
- **Full product:** Same + clipboard + polished cloud + signed download.

*Pricing TBD — architecture supports one codebase, two tiers via `ProductTier` in app.*
