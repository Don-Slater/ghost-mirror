<p align="center">
  <img src="Resources/ghost-mirror-logo-replica.png" alt="Ghost Mirror" width="520">
</p>

<p align="center">
  <strong>Your Linux PC. Mirrored on Mac.</strong><br>
  <sub>Ghost Mirror™ · Apple Silicon</sub>
</p>

<p align="center">
  <a href="#install">Install</a> ·
  <a href="#first-run">First run</a> ·
  <a href="#daily-use">Daily use</a> ·
  <a href="#troubleshooting">Help</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13%2B-blue" alt="macOS 13+">
  <img src="https://img.shields.io/badge/Apple%20Silicon-M1%2B-black" alt="Apple Silicon">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift 5.9">
</p>

---

**Ghost Mirror** is a native macOS app — Ubuntu on Apple Silicon via Apple's Virtualization framework. Near-native speed. One window. Your Linux desk on your Mac.

| What it does |
|--------------|
| **Local Mirror** — Ubuntu ARM64 desktop in a window on your Mac |
| **Near-native** — Apple Virtualization, not emulation |
| **Producer-ready** — dev tools, terminals, Linux workflows beside Logic |

---

## Requirements

- Apple Silicon Mac (M1 or later)
- macOS 13 Ventura or newer
- Xcode 15+ or Swift 5.9 (`xcode-select --install`)
- ~10 GB free disk (app + Ubuntu ISO ~3 GB + VM disk 32 GB sparse)

---

## Install

```bash
git clone https://github.com/Don-Slater/ghost-mirror.git
cd ghost-mirror
./scripts/build.sh --release
```

If macOS blocks the app:

```bash
xattr -cr "Ghost Mirror.app"
open "Ghost Mirror.app"
```

---

## First run

1. Open **Ghost Mirror**
2. Click **Download ISO** (~3 GB, Ubuntu 24.04 ARM64)
3. Click **Start** — install Ubuntu in the window
4. When desktop appears, click **Mark Installed**
5. **Stop**, then **Start** again — boots from disk

Default VM: **4 GB RAM**, **32 GB disk** (sparse — grows as you use it).

Data lives on your Mac:

| Item | Location |
|------|----------|
| Ubuntu ISO | `~/Library/Application Support/GhostMirror/ISOs/` |
| VM disk | `~/Library/Application Support/GhostMirror/VMs/` |

---

## Daily use

| Action | How |
|--------|-----|
| Start Linux | **Start** |
| Stop Linux | **Stop** |
| Fix boot | **Repair Boot** or `Diagnose Local VM.command` |

### CLI (optional)

```bash
.build/release/ghost-mirror-cli list
.build/release/ghost-mirror-cli create "My Mirror" --memory 4 --disk 32
.build/release/ghost-mirror-cli download-iso
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| App won't open | `xattr -cr "Ghost Mirror.app"` |
| ISO missing | **Download ISO** in app or `bash scripts/download-ubuntu-iso.sh` |
| VM won't boot | **Repair Boot** or `bash scripts/diagnose-local-vm.sh` |

---

## More docs

| File | Contents |
|------|----------|
| [SETUP.md](./SETUP.md) | Extended setup |
| [COMMANDS.md](./COMMANDS.md) | Copy-paste commands |

---

© **Ghost Mirror™**

VM patterns derived from Apple's Virtualization sample (Apple Sample Code License).

**Ghost Mirror** — tools for producers who ship.
