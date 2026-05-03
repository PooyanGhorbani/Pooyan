# Changelog — Pooyan 0.07

## Added

- Added China Recommended mode: VLESS + WebSocket + Cloudflare Tunnel + systemd service.
- Added Advanced Reality/Vision mode for direct high-quality VPS routes.
- Added automatic BBR sysctl configuration.
- Added generation of multiple Cloudflare-compatible ports:
  - HTTPS: 443, 2053, 2083, 2087, 2096, 8443
  - HTTP: 80, 8080, 8880, 2052, 2082, 2086, 2095
- Added CF Preferred IP style links using `cloudflare.182682.xyz` as a replaceable address placeholder.
- Added `pooyan` manager command for status, restart, logs, links, and uninstall.
- Added temporary Quick Tunnel mode for testing.

## Changed

- Version bumped from 0.06 to 0.07.
- VLESS is now the main/default protocol path for China-focused deployment.
- Install Service is now the recommended path instead of Quick Mode.

## Notes

- Keep `/root/.cloudflared` if you want to preserve Cloudflare authorization.
- Quick mode is only for testing and will not survive reboot.
- Reality/Vision mode is best tested only on VPS routes with good direct China connectivity.
