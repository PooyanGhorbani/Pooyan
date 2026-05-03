# Changelog

## 0.17 - RackNerd Strong 5 Links

- Added `Pooyan-TRY-TLS-443`, matching the user's fastest tested style: direct `trycloudflare.com` host + TLS 443 + WS.
- Kept the RackNerd output clean: TRY-TLS-443, CF-443, CF-80, HY2-443, Direct-IP only.
- The exact old `trycloudflare.com` hostname is not hardcoded because Quick Tunnel hostnames are temporary; the script now generates the same connection type dynamically.
- Kept strict TryCloudflare host extraction so log text cannot enter the VLESS links.

## 0.16 - RackNerd Strong 4 Links

- Added one optional Hysteria2 UDP 443 link: `Pooyan-RN-HY2-443`.
- Kept RackNerd output clean: CF-443, CF-80, HY2-443, Direct-IP only.
- Added stronger RackNerd network tuning: BBR, TCP fast open, MTU probing, larger TCP buffers.
- Added `pooyan test` for quick service/port checks.
- Added Hysteria2 service status and logs to `pooyan status` and `pooyan logs`.
- Kept strict TryCloudflare host extraction so log text cannot enter the VLESS links.

## 0.15 - RackNerd 3 Links Clean

- Reduced output to three links: CF-443, CF-80, Direct-IP.
- Fixed polluted `trycloudflare.com` host parsing.

## 0.14 - RackNerd Stable Only

- Introduced RackNerd-only stable mode.
