# Pooyan 0.13 - China Stable

Install:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh)
```

Then choose option `1`.

## What changed in 0.13

This version restores the old stable style:

- VLESS + WebSocket
- Auto `trycloudflare.com` Quick Tunnel
- Old China-style Cloudflare front domain links using `cloudflare.182682.xyz`
- Official Cloudflare HTTP ports: `80, 8080, 8880, 2052, 2082, 2086, 2095`
- Official Cloudflare HTTPS ports: `443, 2053, 2083, 2087, 2096, 8443`
- Direct IP link without domain and without TLS
- `pooyan` command is installed automatically
- Clean v2rayN import file is generated at:

```bash
/root/pooyan-v2rayn-import.txt
```

Do not paste VLESS links into the Linux shell because `&` breaks the URL. Import from the file above.

## Commands

```bash
pooyan
pooyan quick
pooyan links
pooyan status
pooyan logs
```

## Important files

```text
/root/v2ray.txt
/root/pooyan-v2rayn-import.txt
/root/pooyan-sub.txt
```
