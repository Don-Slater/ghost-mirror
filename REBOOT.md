# Ghost Mirror — Reboot guide

Use this before you shut down Mac and/or VPS. After reboot, run the scan — do not skip steps.

---

## Before you reboot (2 min)

**1. Note where you are (optional):**
```bash
bash ~/ghost-mirror/scripts/tunnel-cloud-vnc.sh YOUR_VPS_IP stop
```
Tunnel stops cleanly. VPS keeps running — that’s fine.

**2. Close Ghost Mirror app** (Cmd+Q)

**3. Save any open work in Cursor**

---

## Reboot Mac

Apple menu → **Restart**

Or Terminal:
```bash
sudo shutdown -r now
```

---

## Reboot VPS (optional — only if you want a clean server)

**Skip this unless Hostinger panel says reboot needed or you want kernel updates applied.**

```bash
ssh -i ~/.ssh/your_key root@YOUR_VPS_IP 'reboot'
```
Wait ~2 min before scanning.

---

## After reboot — meet back here

Run **one command** — full system scan:

```bash
bash ~/ghost-mirror/scripts/post-reboot-scan.sh
```

It checks: SSH, VNC, Ghost Cloud, tunnel, app binary, ISO status, and prints **REBOOT LINE** for next step.

**Then open desktop again:**
```bash
bash ~/ghost-mirror/scripts/connect-cloud-desktop.sh
```

---

## Reboot line (memorise this)

```bash
bash ~/ghost-mirror/scripts/post-reboot-scan.sh
```

Green scan → Phase A7 (use GhostHome) or Phase B (ISO) when you’re ready.

---

*Parked at A6 confirmed. Next session starts with post-reboot-scan.*
