<p align="center">
  <img src=".github/ghost-mirror-icon.png" alt="Ghost Mirror" width="200">
</p>

<p align="center">
  <img src="Resources/ghost-mirror-logo-replica.png" alt="Ghost Mirror — Ease Audio" width="480">
</p>

<h1 align="center">Ease Mirror™</h1>

<p align="center">
  <strong>Your Linux PC. Mirrored on Mac.</strong><br>
  <sub>Ease Audio™ · Apple Silicon · Ghost Cloud</sub>
</p>

<p align="center">
  <a href="#install-ease-mirror-mac">Mac install</a> ·
  <a href="#get-a-vps">Get a VPS</a> ·
  <a href="#install-ghost-cloud-vps">Ghost Cloud</a> ·
  <a href="#connect-mac-to-vps">Connect</a> ·
  <a href="#troubleshooting">Help</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13%2B-blue" alt="macOS 13+">
  <img src="https://img.shields.io/badge/Apple%20Silicon-M1%2B-black" alt="Apple Silicon">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift 5.9">
</p>

---

Ease Mirror is a native macOS app from **Ease Audio** — Ubuntu on Apple Silicon via Apple's Virtualization framework, with optional **Ghost Cloud** encrypted vault on **your own VPS**.

| Mode | What it does |
|------|----------------|
| **Local Mirror** | Ubuntu ARM64 desktop in a window on your Mac |
| **Ghost Cloud** | Encrypted file vault — email login, 25 MB free per user |
| **Cloud Mirror** | Same Linux on your VPS, in the browser (optional) |

---

## Before you start

### Mac (Ease Mirror)

- Apple Silicon Mac (M1 or later)
- macOS 13 Ventura or newer
- Xcode 15+ or Swift 5.9 (`xcode-select --install`)
- ~10 GB free disk (app + Ubuntu ISO ~3 GB + VM disk 32 GB sparse)

### VPS (Ghost Cloud — your server)

- Ubuntu **22.04** or **24.04**
- **2 GB RAM** minimum, **20 GB** disk
- SSH access with your public key
- Optional domain for HTTPS (e.g. `cloud.yoursite.com`)

### SSH key on Mac (one time)

```bash
ssh-keygen -t ed25519 -C "you@email.com"
cat ~/.ssh/id_ed25519.pub
```

Copy the output and paste it into your VPS provider when you create the server.

---

## Install Ease Mirror (Mac)

### Step 1 — Get the code

```bash
git clone https://github.com/Don-Slater/ease-mirror.git
cd ease-mirror
```

### Step 2 — Build the app

```bash
./scripts/build.sh --release
```

If macOS blocks the app:

```bash
xattr -cr "Ease Mirror.app"
```

### Step 3 — Open Ease Mirror

```bash
open "Ease Mirror.app"
```

### Step 4 — Download Ubuntu ISO

In the app: click **Download ISO** (~3 GB, Ubuntu 24.04 ARM64).

Or in Terminal:

```bash
bash scripts/download-ubuntu-iso.sh
```

ISO saves to: `~/Library/Application Support/EaseMirror/ISOs/`

### Step 5 — Install Ubuntu (first time only)

1. In the app, click **Start** (install mode).
2. Complete the Ubuntu installer in the window.
3. When the desktop appears, click **Mark Installed**.
4. Click **Stop**, then **Start** again — it now boots from disk.

Default VM: **4 GB RAM**, **32 GB disk** (sparse — grows as you use it).

### Step 6 — Daily use

| Action | How |
|--------|-----|
| Start Linux | **Start** in the app |
| Stop Linux | **Stop** |
| Open Ghost Cloud | **Open Ghost Cloud** (after VPS setup below) |
| Fix boot issues | **Repair Boot** or run `Diagnose Local VM.command` |

### CLI (optional)

```bash
.build/release/ease-mirror-cli list
.build/release/ease-mirror-cli create "My Mirror" --memory 4 --disk 32
.build/release/ease-mirror-cli download-iso
```

---

## Get a VPS

You need a Linux server from any cloud provider. Pick one and create **Ubuntu 24.04**.

| Provider | Notes |
|----------|--------|
| [Hetzner](https://www.hetzner.com/cloud) | Good price, EU/US |
| [DigitalOcean](https://www.digitalocean.com) | Simple dashboard |
| [Hostinger VPS](https://www.hostinger.com/vps-hosting) | Cheap entry plans |
| [Oracle Cloud Free](https://www.oracle.com/cloud/free/) | Free tier (ARM) |

### Create the server

1. Sign up and create a **VPS** / **Droplet** / **Cloud instance**.
2. Choose **Ubuntu 24.04 LTS**.
3. Size: **2 GB RAM**, **20 GB disk** minimum.
4. Add your **SSH public key** (`~/.ssh/id_ed25519.pub`).
5. Copy the **public IP** (example: `203.0.113.10`).
6. (Optional) Point DNS **A record** `cloud.yoursite.com` → that IP.

### SSH into the server

```bash
ssh root@YOUR_VPS_IP
```

Some providers use `ubuntu@YOUR_VPS_IP` instead of `root@`.

---

## Install Ghost Cloud (VPS)

Ghost Cloud is the encrypted vault. Users sign up with **email + password**. Free accounts get **25 MB** each.

### Step 1 — Install on the VPS

**From GitHub** (when [ghostcloud repo](https://github.com/Don-Slater/ghostcloud) is live):

```bash
curl -fsSL https://raw.githubusercontent.com/Don-Slater/ghostcloud/main/scripts/install-vps.sh -o install-vps.sh
chmod +x install-vps.sh
sudo bash install-vps.sh
```

**From your Mac** (copy the script):

```bash
scp ~/BenStudio/ghostcloud-app/scripts/install-vps.sh root@YOUR_VPS_IP:/tmp/
ssh root@YOUR_VPS_IP 'bash /tmp/install-vps.sh'
```

### Step 2 — HTTPS (recommended)

```bash
sudo DOMAIN=cloud.yoursite.com EMAIL=you@email.com bash install-vps.sh
```

Without a domain you get `http://YOUR_VPS_IP:8787` — open port **8787** in the provider firewall.

### Step 3 — Check it works

On the VPS:

```bash
curl -s http://127.0.0.1:8787/health
systemctl status ghostcloud-app ghostcloud-ipfs
```

You want `"ok": true` in the health response.

### Step 4 — Create your account

1. Open `https://cloud.yoursite.com/signup` (or `http://YOUR_VPS_IP:8787/signup`).
2. Enter **email** and **password** (min 8 characters).
3. You get **25 MB** encrypted storage.

### Ghost Cloud pages

| Page | URL | Purpose |
|------|-----|---------|
| Sign up | `/signup` | New account |
| Sign in | `/login` | Email + password |
| Library | `/library` | Upload / download files |
| Forgot password | `/forgot-password` | Reset (new empty vault — old files cannot be recovered) |
| VPS guide | `/docs/vps` | Full VPS doc on your live server |

---

## Connect Mac to VPS

### Step 1 — Config file on Mac

```bash
mkdir -p ~/.ben_studio
cp config/ease_mirror_cloud.env.example ~/.ben_studio/ease_mirror_cloud.env
chmod 600 ~/.ben_studio/ease_mirror_cloud.env
```

Edit with **your** values:

```bash
EASE_MIRROR_CLOUD_IP=YOUR_VPS_IP
EASE_MIRROR_GHOST_URL=https://cloud.yoursite.com
EASE_MIRROR_CLOUD_USER=root
EASE_MIRROR_SSH_KEY=/Users/YOURNAME/.ssh/id_ed25519
EASE_MIRROR_VNC_PASSWORD=your-vnc-password
```

Or in the app: **View → Full Mode → VPS Settings**.

### Step 2 — Open Ghost Cloud from the app

Click **Open Ghost Cloud** — opens your vault in the browser.

### Step 3 — Cloud desktop in browser (optional)

```bash
bash scripts/setup-cloud-desktop.sh YOUR_VPS_IP
bash scripts/tunnel-cloud-vnc.sh YOUR_VPS_IP start
open "http://127.0.0.1:6080/vnc.html?autoconnect=true&resize=scale"
```

Stop the tunnel:

```bash
bash scripts/tunnel-cloud-vnc.sh YOUR_VPS_IP stop
```

---

## Daily workflow

**Producer on Mac:**

1. Open **Ease Mirror** → **Start** Ubuntu.
2. Click **Open Ghost Cloud** → upload/download WAVs and projects.
3. Work in **Logic** on Mac.
4. **Stop** the VM when done.

**Web only (no Mac app):**

1. Go to `https://cloud.yoursite.com/login`
2. Sign in → **Library** → upload/download.

---

## Disk footprint

Nothing heavy lives in this Git repo (~4 MB source). Runtime data is on your Mac:

| Item | Location | Size |
|------|----------|------|
| Ubuntu ISO | `~/Library/Application Support/EaseMirror/ISOs/` | ~3 GB (once) |
| VM disk | `~/Library/Application Support/EaseMirror/VMs/` | 32 GB sparse default |
| App build | `.build/` after compile | ~190 MB — gitignored |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Cannot open Ease Mirror.app | `xattr -cr "Ease Mirror.app"` |
| ISO missing | **Download ISO** in app or `bash scripts/download-ubuntu-iso.sh` |
| VM won't boot | **Repair Boot** or `bash scripts/diagnose-local-vm.sh` |
| Ghost Cloud won't load | Check firewall (443 or 8787), `systemctl status ghostcloud-app` on VPS |
| Vault full | Free plan is **25 MB** — delete files or raise quota on VPS |
| SSH fails | Check IP, SSH key path in env file, provider key settings |

---

## Architecture

```
Ease Mirror.app (SwiftUI)
    └── EaseMirrorCore
            ├── VMStore          — VM definitions on disk
            ├── LinuxVMEngine    — Virtualization.framework
            └── GhostCloudBridge — Ghost Cloud + VPS scripts
```

---

## More docs

| File | Contents |
|------|----------|
| [SETUP.md](./SETUP.md) | Extended setup guide |
| [COMMANDS.md](./COMMANDS.md) | Copy-paste command blocks |
| [CHEAP_MODEL.md](./CHEAP_MODEL.md) | Lite tier spec |
| [.github/BRANDING.md](./.github/BRANDING.md) | Logo and social preview |

---

## License

© **Ease Audio**. Ease Mirror™ and Ghost Mirror™ are trademarks of Ease Audio.

VM patterns derived from Apple's Virtualization sample (Apple Sample Code License).

**Ease Audio** — tools for producers who ship.
