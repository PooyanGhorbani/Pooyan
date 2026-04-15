# Pooyan 0.07

Pooyan 0.07 is a multi-user Xray + Cloudflared installer with:
- per-user links
- expiry limits
- quota limits
- usage sync/reporting
- a `pooyan` command for user management

## Quick install

After uploading `pooyan.sh` to the root of your public repository:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh)
```

## Notes

- The multi-user edition focuses on persistent service mode.
- Usage tracking is synchronized periodically and quota enforcement is not instantaneous.
- After installation, run:

```bash
pooyan
```

## What it installs

- Xray
- Cloudflared
- SQLite-backed user database
- systemd services:
  - `xray.service`
  - `cloudflared.service`
  - `pooyan-sync.timer`
