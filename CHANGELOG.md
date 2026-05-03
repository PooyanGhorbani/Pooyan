# Changelog

## 0.15 - RackNerd 3 Links Clean

- Fixed a critical parsing bug where cloudflared progress text such as `Trying cloudflared quick tunnel mode: http2-v4` could be inserted into VLESS host/SNI.
- Reduced RackNerd output to only 3 practical links: CF-443, CF-80, and Direct IP.
- Removed duplicate TRY-443 and TRY-80 links to keep v2rayN clean.
- Added strict validation for `*.trycloudflare.com` host extraction.
- Kept Direct IP as backup/test link.

## 0.14 - RackNerd Stable Only

- RackNerd-focused Cloudflare WS output.
- Generated CF and TRY variants plus Direct IP.
