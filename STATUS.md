# Ghost Mirror — Project Status (parked)

**Last checked:** 2026-06-21  
**Version:** 0.1.0  
**Phase:** Cheap model + Black Book — **IN PROGRESS**

---

## Reboot line — after full system restart

```bash
bash ~/ghost-mirror/scripts/post-reboot-scan.sh
```

Full instructions: **[REBOOT.md](./REBOOT.md)**

Quick health only:
```bash
bash ~/ghost-mirror/scripts/connect-cloud-mirror.sh --check
```

---

## Phase map

```
DONE  A1–A6  VPS + Ghost Cloud + VNC; Ghost Cloud opened from Linux ✓
DONE  B1–B2  ISO downloaded + local mirror "Ghost Mirror" created
NEXT  B3     Open Ghost Mirror.app → Start → install Ubuntu
LATER B4+    GhostHome wire, clipboard (HITLIST.md), sign/sell
```

**Parked = no new code until post-reboot scan passes.**

---

## Honest state

### Confirmed by you

| Item | Status |
|------|--------|
| Cloud desktop visible | Yes |
| Terminal commands | Run successfully |
| Linux-only stack | No Microsoft |

### Verified by tooling

| Item | Status |
|------|--------|
| SSH VPS | OK |
| TigerVNC + noVNC | OK |
| Ghost Cloud + GhostHome | OK |
| App builds | OK |

### Not started yet

| Item | Status |
|------|--------|
| Ubuntu ISO (~3GB) | Not downloaded |
| Local VM (Phase B) | Not started |
| App signing / sale | Not started |

---

## Session files

| File | Use |
|------|-----|
| [REBOOT.md](./REBOOT.md) | Before/after reboot |
| [COMMANDS.md](./COMMANDS.md) | Step-by-step commands |
| [BUILD_ORDER.md](./BUILD_ORDER.md) | Phase overview |
| `scripts/post-reboot-scan.sh` | Full scan after reboot |

---

*Ghost Mirror — Ghost Mirror. Parked tidy. Reboot → scan → forward.*
