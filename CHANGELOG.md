# Changelog

## 0.14 - RackNerd Stable Only

- Rebuilt quick mode specifically for RackNerd.
- Removed noisy extra ports from the quick output.
- Keeps only the connections that were useful in the user's RackNerd/v2rayN tests:
  - CF old-style 443
  - CF old-style 80
  - trycloudflare 443
  - trycloudflare 80
  - Direct IP backup/test
- Added stronger trycloudflare creation retry logic: http2 IPv4, http2 auto, quic IPv4, default.
- Always creates `/root/pooyan-v2rayn-import.txt` for clean v2rayN import.
- Keeps `pooyan` manager command working.

## 0.13 - China Stable Restore

- Restored old VLESS + WS + trycloudflare style.
- Added Direct IP fallback.
