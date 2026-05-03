# Pooyan 0.14 - RackNerd Stable Only

This version is intentionally small and clean for RackNerd VPS use.

## What it builds

Only 5 links maximum:

1. `Pooyan-RN-CF-443` - old-style China Cloudflare front link
2. `Pooyan-RN-CF-80` - old-style China Cloudflare front link
3. `Pooyan-RN-TRY-443` - direct trycloudflare link
4. `Pooyan-RN-TRY-80` - direct trycloudflare link
5. `Pooyan-RN-DIRECT-IP` - Direct IP backup/test link

No 2053/2083/2087/2096/8443 links are generated in this RackNerd-only version, to avoid clutter and handshake-test noise.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh)
```

Choose option `1`.

## v2rayN import

Use this file only:

```bash
cat /root/pooyan-v2rayn-import.txt
```

Do not paste VLESS links into the Linux/PuTTY command line, because `&` breaks the link.

## Manager

```bash
pooyan renew
pooyan links
pooyan import
pooyan status
pooyan logs
```

## Files

- Human-readable links: `/root/v2ray.txt`
- Clean v2rayN import: `/root/pooyan-v2rayn-import.txt`
- Base64 subscription: `/root/pooyan-sub.txt`
