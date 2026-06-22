# Ghost Mirror — Command Walkthrough

**Do it this way. Not the 5-minute YouTube way.**

Copy one block at a time. Wait for ✅ before the next step.

---

## STEP 0 — Reboot line (after power cut)

```bash
bash ~/ghost-mirror/scripts/connect-cloud-mirror.sh --check
```

**Expect:** `OK` and `VNC:up`

If `VNC:down`:
```bash
bash ~/ghost-mirror/scripts/fix-vnc-service.sh
```

See **[STATUS.md](./STATUS.md)** for honest project state.

---

## STEP 0b — Open this file + Terminal

```bash
cd ~/ghost-mirror
```

Keep Terminal on the left. This file on the right. YouTube can wait.

---

## STEP 1 — Check the app is built

```bash
cd ~/ghost-mirror
.build/release/ghost-mirror-cli paths
```

**Expect:**
```
App support: .../GhostMirror
VMs:         .../GhostMirror/VMs
ISO:         .../ubuntu-24.04.4-desktop-arm64.iso
Share:       .../GhostMirror/Share
```

✅ Paths print → go Step 2

---

## STEP 2 — Open Ghost Mirror app

```bash
open ~/ghost-mirror/Ease\ Mirror.app
```

✅ App window opens → go Step 3

**If macOS blocks it:**
```bash
xattr -cr ~/ghost-mirror/Ease\ Mirror.app
open ~/ghost-mirror/Ease\ Mirror.app
```

---

## STEP 3 — Cloud VPS quick check (does not hang)

```bash
bash ~/ghost-mirror/scripts/connect-cloud-mirror.sh --check
```

**Expect:** `OK` + `VNC:up` + `ls` shows GhostHome folders

✅ OK → go Step 4

---

## STEP 4 — VNC tunnel status

```bash
bash ~/ghost-mirror/scripts/tunnel-cloud-vnc.sh YOUR_VPS_IP status
```

**Expect:** `running` or `running (port 6080 in use)`

If **stopped**, start it:
```bash
bash ~/ghost-mirror/scripts/tunnel-cloud-vnc.sh YOUR_VPS_IP start
```

✅ Tunnel running → go Step 5

---

## STEP 5 — Open Linux desktop (no Microsoft)

**Option A — inside Ghost Mirror app**

1. Sidebar → **Cloud Mirror**
2. IP: `YOUR_VPS_IP` (from `~/.ben_studio/ghost_mirror_cloud.env`)
3. Click **Open Cloud Desktop**

**Option B — Terminal**

```bash
bash ~/ghost-mirror/scripts/connect-cloud-desktop.sh
```

**Option C — browser only**

```bash
bash ~/ghost-mirror/scripts/tunnel-cloud-vnc.sh YOUR_VPS_IP start
open "http://127.0.0.1:6080/vnc.html?autoconnect=true&resize=scale"
```

✅ XFCE desktop visible → go Step 6

---

## STEP 6 — Ghost Cloud on Mac (once)

```bash
bash ~/BenStudio/scripts/ghostcloud-remote/finish-setup.sh
```

✅ Vault ready → go Step 7

---

## STEP 7 — Store a file to Ghost Cloud

```bash
gc-store ~/Desktop/somefile.txt
ghostcloud list
```

✅ File in vault → go Step 8 (local VM)

---

## STEP 8 — Download Ubuntu ISO (~3 GB, local mirror)

```bash
cd ~/ghost-mirror
.build/release/ghost-mirror-cli download-iso
```

Wait for finish. Go make tea. Not a 5-min YouTube skip.

✅ ISO path exists → go Step 9

---

## STEP 9 — Create local mirror

```bash
.build/release/ghost-mirror-cli create "Ghost Mirror" --memory 8 --disk 32
.build/release/ghost-mirror-cli list
```

✅ Mirror listed → go Step 10

---

## STEP 10 — Boot Ubuntu installer (in app)

1. Open **Ghost Mirror.app**
2. Select **Ghost Mirror**
3. Click **Start**
4. Install Ubuntu in the window
5. When done → **Mark Installed**
6. **Start** again (boots from disk)

---

## STOP / START / FIX

**Stop VNC tunnel**
```bash
bash ~/ghost-mirror/scripts/tunnel-cloud-vnc.sh YOUR_VPS_IP stop
```

**SSH into cloud**
```bash
bash ~/ghost-mirror/scripts/connect-cloud-mirror.sh
```

**Rebuild app after code changes**
```bash
cd ~/ghost-mirror
./scripts/build.sh --release
open ~/ghost-mirror/Ease\ Mirror.app
```

**List mirrors**
```bash
.build/release/ghost-mirror-cli list
```

---

## What NOT to do (YouTube wrong way)

| ❌ Wrong | ✅ Ghost Mirror way |
|---------|-------------------|
| Microsoft Remote Desktop | Ghost Mirror → Open Cloud Desktop |
| Random RDP ports open | SSH tunnel only |
| Parallels / UTM with no vault | Ghost Cloud + GhostHome |
| Skip ISO, wonder why it fails | Step 8 — download ISO first |
| 5-min "works on my machine" | These steps, in order |

---

## Your VPS

| Item | Value |
|------|-------|
| IP | from `GHOST_MIRROR_CLOUD_IP` in env |
| User | `root` |
| SSH key | from `GHOST_MIRROR_SSH_KEY` in env |
| Ghost web | from `GHOST_MIRROR_GHOST_URL` in env |
| GhostHome | `/root/GhostHome` |
| Desktop | XFCE + TigerVNC + noVNC |

---

*Ghost Mirror — Ghost Mirror. Linux only. No Microsoft.*
