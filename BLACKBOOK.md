# Ghost Mirror — Black Book

Engineering notebook for the **final build**. Cheap model ships without these polished; this doc is where the fiddly bits live.

**Cheap model spec:** [CHEAP_MODEL.md](./CHEAP_MODEL.md)  
**Quick hit list:** [HITLIST.md](./HITLIST.md)

---

## The bridge (dimensions)

```
Mac host          Ghost Cloud (vault)         Linux guest
Ghost Mirror app   IPFS + web UI               local VM  OR  VPS cloud desktop
     │                    │                         │
     └──── same files ────┴──── same files ──────────┘
              GhostHome: Documents / Downloads / Projects
```

Ghost Cloud is the **bridge between dimensions** — OS can run on Mac silicon or VPS; data stays one place.

---

## Cheap model vs final build

| Area | Cheap model (now) | Final build |
|------|-------------------|-------------|
| Local VM | Start/stop, Ubuntu install | Clipboard, resize, guest tools |
| Cloud desktop | Browser via script | Stable in-app OR browser default |
| Ghost Cloud | Open URL in browser | Deep link + tunnel from app |
| Clipboard Mac↔Linux | **Not wired** | See § Clipboard below |
| VPS setup | Pre-provisioned / Ben runs scripts | In-app wizard |
| Share folder | Auto on start | Auto + desktop shortcut in XFCE |
| Sign / sell | Unsigned `.app` | Notarized `.dmg` |

---

## Clipboard Mac ↔ Linux (final build)

**Status:** Not working in cheap model. **Priority: High.**

### Cloud path (VNC + noVNC)

Server side (partially done):

- `vncconfig -iconic &` must run in `~/.vnc/xstartup` before `exec startxfce4`
- Fixed in `scripts/fix-vnc-service.sh`; old VPS installs may still have bad xstartup

Client side (TODO):

- noVNC clipboard needs **Clipboard API** enabled in noVNC client settings
- URL params: check noVNC version on VPS for `clipboard=` or sidebar clipboard panel
- Browser must allow clipboard read/write (Safari/Chrome prompt)
- WebKit WebView: clipboard often **blocked** — another reason cheap model uses **browser**

Test plan (final):

1. Copy text on Mac → paste in Linux Firefox on cloud desktop
2. Copy in Linux → paste on Mac
3. Repeat with in-app WebView only if WebKit entitlements fixed

### Local path (Virtualization.framework)

Apple `VZVirtualMachineView` does **not** expose Linux guest clipboard sync today.

Options for final build (pick one):

1. **VirtioFS + script hack** — sync via file drop in `Share/clipboard.txt` (cheap hack, not real clipboard)
2. **Guest agent** — research `spice-vdagent` / custom daemon over virtio serial (heavy)
3. **Shared folder only** — document “use GhostHome for text files” (honest fallback)
4. **Apple future API** — watch Virtualization.framework release notes

Recommended final approach:

- **Primary:** shared folder + Ghost Cloud for files (already works)
- **Stretch:** noVNC clipboard for cloud tier
- **Local VM:** investigate virtio-guest-tools when Ubuntu ARM64 guest tools mature on Apple Silicon

---

## Cloud desktop (chocolate teapot)

### What works

```bash
bash ~/ghost-mirror/scripts/connect-cloud-desktop.sh
```

- SSH tunnel `localhost:6080` → VPS noVNC
- Opens **browser** with password in URL (stable)
- VNC password: set in `~/.ben_studio/ghost_mirror_cloud.env` (see `config/ghost_mirror_cloud.env.example`)

### What breaks

| Symptom | Cause | Fix |
|---------|-------|-----|
| Flash then sign-in loop | SSH tunnel died | `tunnel-cloud-vnc.sh` uses `ssh -f` + ServerAliveInterval |
| Blank page | noVNC down on VPS | `fix-vnc-service.sh` |
| systemd crash loop | `ease-mirror-vnc` vs manual `:1` | `systemctl disable ease-mirror-vnc` when manual VNC running |
| Desktop exits immediately | Bad xstartup (`dbus-launch` exits) | `exec startxfce4` in xstartup |
| In-app WebView unstable | WebKit + websockets + clipboard | Cheap model: browser only |

### Good xstartup (canonical)

```sh
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
[ -r "$HOME/.Xresources" ] && xrdb "$HOME/.Xresources"
vncconfig -iconic &
exec startxfce4
```

---

## Local VM fiddly bits

### App vanishes on Start (fixed 2026-06-21)

**Cause:** `VZVirtualMachine.start()` was called off the main thread → instant crash (`dispatch_assert_queue_fail`).

**Fix:** `LinuxVMEngine` now runs all Virtualization.framework calls on `@MainActor`.

Also fixed for Linux install: `VZGenericPlatformConfiguration`, ISO on **USB** (not virtio CD), virtio entropy device, empty disk without fake MBR.

### ISO

- Path: `~/Library/Application Support/GhostMirror/ISOs/ubuntu-24.04.4-desktop-arm64.iso`
- CLI: `.build/release/ghost-mirror-cli download-iso`
- Must be **ARM64** desktop ISO on Apple Silicon

### After install

1. Stop VM
2. App → **Mark Installed** (or CLI marks boot-from-disk)
3. Start again — boots from disk, ISO detached

### VirtioFS share

- Host: `~/Library/Application Support/GhostMirror/Share`
- Guest tag: `GhostMirrorShare`
- Guest mount (after install): mount virtiofs, run `wire-ghost-home.sh`

### Entitlements

- `com.apple.security.virtualization` required
- App must be signed for distribution (Phase C)

---

## Ghost Cloud fiddly bits

### URLs & env

File: `~/.ben_studio/ghost_mirror_cloud.env`

```
GHOST_MIRROR_CLOUD_IP=203.0.113.10
GHOST_MIRROR_GHOST_URL=https://your-ghostcloud.example.com
GHOST_MIRROR_VNC_PASSWORD=your-vnc-password
GHOST_MIRROR_SSH_KEY=~/.ssh/your_key
```

### Mac setup

```bash
bash ~/BenStudio/scripts/ghostcloud-remote/finish-setup.sh
```

### From Linux guest

- Browser → Ghost Cloud URL (proved working)
- GhostHome: `~/GhostHome/{Documents,Downloads,Projects}` on VPS

---

## SSH & tunnels

| Script | Purpose |
|--------|---------|
| `tunnel-cloud-vnc.sh start/stop/status` | localhost:6080 → VPS:6080 |
| `connect-cloud-mirror.sh --check` | Non-hanging health check |
| `post-reboot-scan.sh` | Full scan after Mac or VPS reboot |

Tunnel must stay alive while using cloud desktop. Kill stale:

```bash
bash ~/ghost-mirror/scripts/tunnel-cloud-vnc.sh YOUR_VPS_IP stop
```

---

## Copy/paste from chat (Slater workflow)

Slater often **cannot copy commands from Cursor chat** into Terminal.

Rules for Ben / app:

1. **Run commands for him** — don’t paste long blocks in chat
2. **Ghost Cloud → Bridge tab** — web terminal on cloud Linux (`/bridge`)
3. **Double-click `.command` files** in `ghost-mirror/`
4. **App buttons** call scripts — no manual copy
5. Commands also live in [COMMANDS.md](./COMMANDS.md)

### Command bridge (Ghost Cloud)

- URL: `https://your-ghostcloud.example.com/bridge` (vault login required)
- Runs commands on **cloud Linux** in `~/GhostHome`
- Ghost Mirror app: **Command Bridge** button opens it
- Inbox file for future local VM agent: `~/GhostHome/.ghostcloud/command_inbox.txt`

---

## Final build checklist

- [ ] Clipboard cloud (noVNC client config + browser test)
- [ ] Clipboard local (strategy chosen + implemented or documented fallback)
- [ ] Cloud desktop: browser default, optional in-app
- [ ] GhostHome desktop shortcut on XFCE
- [ ] One-click Ghost Cloud from app (browser)
- [ ] Auto `wire-ghost-home` post-install hook
- [ ] Notarize + staple `.dmg`
- [ ] Remove hardcoded IPs from source (env only)
- [ ] Privacy policy / Ghost Cloud data handling copy

---

*Last updated: 2026-06-21 — cheap model session*
