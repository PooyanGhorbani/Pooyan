# Pooyan 0.15 - RackNerd 3 Links Clean

Clean RackNerd-focused installer for China testing.

## What this version generates

Only 3 client links:

1. `Pooyan-RN-CF-443` - Cloudflare front address on TLS 443
2. `Pooyan-RN-CF-80` - Cloudflare front address on HTTP 80
3. `Pooyan-RN-DIRECT-IP-PORT` - direct VPS IP backup/test link

This version removes the duplicate direct `trycloudflare.com` links to avoid clutter.

## Fixed in 0.15

- Fixed broken link generation where cloudflared status text was accidentally captured inside the VLESS host/SNI.
- `get_trycloudflare_host` now prints progress messages to stderr, not stdout.
- Host validation now accepts only a clean `*.trycloudflare.com` hostname.
- v2rayN import file stays clean.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh)
```

After installation, import links from:

```bash
cat /root/pooyan-v2rayn-import.txt
```

Do not paste VLESS links into the Linux shell because `&` can break the link.

## Manager

```bash
pooyan
pooyan links
pooyan import
pooyan renew
pooyan status
pooyan logs
```
