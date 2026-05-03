# Changelog

## 0.10

- Added a Direct IP link without domain in Quick Mode.
- Quick Mode now generates both:
  - automatic `trycloudflare.com` links
  - direct VPS IP VLESS WS link for speed testing
- Quick Mode Xray inbound now listens on `0.0.0.0` so the direct IP link can work.
- Added best-effort firewall opening for the generated direct TCP port using `ufw`, `firewall-cmd`, or `iptables` when available.
- Updated menu text and README for the new no-domain direct test link.

## 0.09

- Fixed Xray config test command for newer Xray-core versions.
- Uses `xray run -test -config` with fallback to older `xray test -config`.

## 0.08

- Restored Auto Domain mode using `trycloudflare.com`.
- No Cloudflare account or domain is needed for Option 1.

## 0.07

- Added China Recommended structure.
- Added VLESS + WebSocket + Cloudflare Tunnel mode.
- Added REALITY/Vision advanced mode.
- Added BBR enabling.
- Added multi-port Cloudflare link generation.
