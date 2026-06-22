# Ghost Mirror — Full setup & use guide

**Ease Audio™** · plain steps · one block at a time

<p align="center">
  <img src="Resources/ghost-mirror-logo-replica.png" alt="Ghost Mirror" width="400">
</p>

---

## What you are building

| Piece | What it is | Where it runs |
|-------|------------|---------------|
| **Ghost Cloud** | Encrypted file vault (email login, 25 MB free) | **Your VPS** or local Mac for testing |
| **Ease Mirror** | Ubuntu Linux desktop inside a Mac app | **Your Mac** (Apple Silicon) |
| **Cloud desktop** | Same Linux, in browser via SSH | **Your VPS** (optional) |

You can use **Ghost Cloud alone** (web only) or **Ease Mirror + Ghost Cloud** (Mac app + vault on your server).

---

## Before you start

### Mac (Ease Mirror)

- Apple Silicon Mac (M1 or later)
- macOS 13 Ventura or newer
- Xcode 15+ or Swift 5.9 (`xcode-select --install`)
- ~10 GB free disk (app + optional Ubuntu ISO ~3 GB + VM disk 32 GB sparse)

### VPS (Ghost Cloud — your server)

- Ubuntu **22.04** or **24.04** (x86 or ARM)
- **2 GB RAM** minimum, **20 GB** disk
- SSH access (your public key in the provider panel)
- Optional: domain name (e.g. `cloud.yoursite.com`) for HTTPS

### SSH key on Mac (if you do not have one)

```bash
ssh-keygen -t ed25519 -C "you@email.com"
cat ~/.ssh/id_ed25519.pub
```

Paste that public key into your VPS provider when creating the server.

---

# Part 1 — Ghost Cloud on your VPS

This is the encrypted vault users sign into with **email + password**.

## Step 1 — Create the VPS

1. Pick a provider (Hostinger, Hetzner, DigitalOcean, Oracle Free, etc.).
2. Create **Ubuntu 24.04** server.
3. Add your **SSH public key**.
4. Copy the **public IP** (example: `203.0.113.10`).
5. (Optional) Point DNS **A record** `cloud.yoursite.com` → that IP.

## Step 2 — SSH into the server

```bash
ssh root@YOUR_VPS_IP
```

Some clouds use `ubuntu@YOUR_VPS_IP` instead of `root@`.

## Step 3 — Install Ghost Cloud

**Option A — from GitHub (when repo is public):**

```bash
curl -fsSL https://raw.githubusercontent.com/Ease-Audio/ghostcloud/main/scripts/install-vps.sh -o install-vps.sh
chmod +x install-vps.sh
sudo bash install-vps.sh
```

**Option B — copy from your Mac (before GitHub push):**

```bash
# On your Mac:
scp ~/BenStudio/ghostcloud-app/scripts/install-vps.sh root@YOUR_VPS_IP:/tmp/
ssh root@YOUR_VPS_IP 'bash /tmp/install-vps.sh'
```

**With HTTPS (recommended):**

```bash
sudo DOMAIN=cloud.yoursite.com EMAIL=you@email.com bash install-vps.sh
```

Without a domain you get `http://YOUR_VPS_IP:8787` — open port **8787** in the provider firewall.

## Step 4 — Check it works

On the VPS:

```bash
curl -s http://127.0.0.1:8787/health
systemctl status ghostcloud-app ghostcloud-ipfs
```

You want `"ok": true` in the health JSON.

## Step 5 — Create your account

1. Open in browser: `https://cloud.yoursite.com/signup` (or `http://IP:8787/signup`).
2. Enter **email** and **password** (min 8 characters, you choose it).
3. You get **25 MB** encrypted storage on the free plan.

## Step 6 — Use Ghost Cloud (web)

| Page | URL | What you do |
|------|-----|-------------|
| Sign in | `/login` | Email + password |
| Sign up | `/signup` | New account |
| Forgot password | `/forgot-password` | Reset link (starts **new empty** vault — old files cannot be recovered) |
| Library | `/library` | Upload / download / delete files |
| Terminal | `/bridge` | Shell on the VPS (after login) |
| Mail | `/mail` | GhostMail inboxes (separate passwords) |
| VPS guide | `/docs/vps` | This install doc on the live site |

**Upload:** Library → choose files → upload.  
**Share:** Library → create share link → set a share password → send link.

### Password reset email (optional)

On the VPS, edit the systemd service to add SMTP (see `ghostcloud-app/config/smtp.env.example`).  
Without SMTP, the reset link appears on screen after you submit forgot-password.

---

# Part 2 — Ease Mirror on your Mac (local Linux)

## Step 1 — Get the code

```bash
cd ~/BenStudio/EaseMirror
# or: git clone https://github.com/Ease-Audio/ease-mirror.git && cd ease-mirror
```

## Step 2 — Build the app

```bash
./scripts/build.sh --release
```

If macOS blocks the app:

```bash
xattr -cr "Ease Mirror.app"
```

## Step 3 — Open Ease Mirror

```bash
open "Ease Mirror.app"
```

## Step 4 — Download Ubuntu ISO

In the app: click **Download ISO** (~3 GB, Ubuntu 24.04 ARM64).

Or in Terminal:

```bash
bash ~/BenStudio/EaseMirror/scripts/download-ubuntu-iso.sh
```

ISO saves to: `~/Library/Application Support/EaseMirror/ISOs/`

## Step 5 — Install Ubuntu (first time only)

1. In the app, click **Start** (install mode).
2. Ubuntu installer opens in the window — complete install.
3. When desktop appears, click **Mark Installed** in Ease Mirror.
4. Click **Stop**, then **Start** again — now it boots from disk (not ISO).

Default VM: **4 GB RAM**, **32 GB disk** (sparse — grows as you use it).

## Step 6 — Daily use (local mirror)

| Action | How |
|--------|-----|
| Start Linux | **Start** in app |
| Stop Linux | **Stop** |
| Open terminal in guest | Ubuntu Terminal app inside the window |
| Fix boot issues | **Repair Boot** or `Diagnose Local VM.command` |
| Check paths | `.build/release/ease-mirror-cli paths` |

---

# Part 3 — Connect Mac app to your Ghost Cloud VPS

## Step 1 — Config file on Mac

```bash
mkdir -p ~/.ben_studio
cp ~/BenStudio/EaseMirror/config/ease_mirror_cloud.env.example ~/.ben_studio/ease_mirror_cloud.env
chmod 600 ~/.ben_studio/ease_mirror_cloud.env
```

Edit the file — set **your** values:

```bash
EASE_MIRROR_CLOUD_IP=YOUR_VPS_IP
EASE_MIRROR_GHOST_URL=https://cloud.yoursite.com
EASE_MIRROR_CLOUD_USER=root
EASE_MIRROR_SSH_KEY=/Users/YOURNAME/.ssh/id_ed25519
EASE_MIRROR_VNC_PASSWORD=your-vnc-password
```

Or in the app: **View → Full Mode → VPS Settings**.

## Step 2 — Cloud desktop (Linux in browser)

**From the app:** **Open Cloud Desktop**

**From Terminal:**

```bash
bash ~/BenStudio/EaseMirror/scripts/connect-cloud-desktop.sh
```

This opens a browser window to your VPS desktop (needs VNC set up on the server — see advanced below).

**Quick SSH check:**

```bash
bash ~/BenStudio/EaseMirror/scripts/connect-cloud-mirror.sh --check
```

## Step 3 — Open Ghost Cloud from the app

Click **Open Ghost Cloud** — opens your vault URL in the browser (the `EASE_MIRROR_GHOST_URL` you set).

---

# Part 4 — Cloud desktop on VPS (advanced, optional)

Only needed if you want Linux in the **browser**, not just the local VM.

On the VPS (once SSH works):

```bash
# From Mac — copies and runs desktop setup on VPS
bash ~/BenStudio/EaseMirror/scripts/setup-cloud-desktop.sh YOUR_VPS_IP
```

Then on Mac, start the tunnel:

```bash
bash ~/BenStudio/EaseMirror/scripts/tunnel-cloud-vnc.sh YOUR_VPS_IP start
open "http://127.0.0.1:6080/vnc.html?autoconnect=true&resize=scale"
```

Stop tunnel:

```bash
bash ~/BenStudio/EaseMirror/scripts/tunnel-cloud-vnc.sh YOUR_VPS_IP stop
```

---

# Quick reference — daily workflow

### Producer on Mac (typical)

1. Open **Ease Mirror** → **Start** Ubuntu for local tools.
2. Click **Open Ghost Cloud** → upload/download WAVs, stems, projects.
3. Work in **Logic** on Mac; files live in Ghost Cloud vault.
4. **Stop** VM when done.

### Web-only (no Mac app)

1. Go to `https://cloud.yoursite.com/login`
2. Sign in → **Library** → upload/download.

---

# Troubleshooting

| Problem | Fix |
|---------|-----|
| Cannot open Ease Mirror.app | `xattr -cr "Ease Mirror.app"` |
| ISO missing | Download ISO in app or run `download-ubuntu-iso.sh` |
| VM won't boot | **Repair Boot** or `bash scripts/diagnose-local-vm.sh` |
| Ghost Cloud site won't load | Check VPS firewall (443 or 8787), `systemctl status ghostcloud-app` |
| Upload fails "vault full" | Free plan is **25 MB** — delete files or raise quota on VPS |
| Wrong email/password | Use **Forgot password** — remember old files are lost after reset |
| SSH to VPS fails | Check IP, key path in env file, provider SSH key settings |
| Logo / site branding | See `.github/BRANDING.md` |

---

# CLI cheatsheet

```bash
# Ease Mirror
cd ~/BenStudio/EaseMirror
./scripts/build.sh --release
.build/release/ease-mirror-cli list
.build/release/ease-mirror-cli create "My Mirror" --memory 4 --disk 32
.build/release/ease-mirror-cli download-iso

# Ghost Cloud health (on VPS)
curl -s http://127.0.0.1:8787/health | jq

# After Mac reboot — cloud check
bash ~/BenStudio/EaseMirror/scripts/post-reboot-scan.sh
```

---

# More docs

| File | Contents |
|------|----------|
| [README.md](./README.md) | Overview + build |
| [COMMANDS.md](./COMMANDS.md) | Copy-paste command blocks |
| [CHEAP_MODEL.md](./CHEAP_MODEL.md) | What v0 includes / skips |
| [BLACKBOOK.md](./BLACKBOOK.md) | Engineering notebook |
| [../ghostcloud-app/README.md](../ghostcloud-app/README.md) | Ghost Cloud only |
| [../ghostcloud-app/templates/docs_vps.html](../ghostcloud-app/templates/docs_vps.html) | Live VPS page source |

---

**Ease Audio™** · Ghost Mirror · Ghost Cloud · tools for producers who ship.
