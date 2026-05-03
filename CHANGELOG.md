# CHANGELOG

## 0.13

- Reverted Quick mode to the old stable China-style connection layout.
- Removed the problematic CF Preferred IP auto-links from quick output.
- Added one Direct IP VLESS WS link without domain and without TLS.
- Added many old-style Cloudflare front-domain links:
  - HTTP: 80, 8080, 8880, 2052, 2082, 2086, 2095
  - HTTPS/TLS: 443, 2053, 2083, 2087, 2096, 8443
- Always installs the `pooyan` manager command.
- Always writes clean import-only links to `/root/pooyan-v2rayn-import.txt`.
- Prevents installation from stopping if TryCloudflare fails; Direct IP is still generated.

## 0.12

- Attempted quick manager fix.

## 0.11

- Added quick fallback.

## 0.10

- Added Direct IP quick mode.

## 0.09

- Fixed Xray config test command.

## 0.08

- Restored Auto Domain mode.
