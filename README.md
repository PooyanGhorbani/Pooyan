# Pooyan 0.17 - RackNerd Strong 5 Links

A clean RackNerd-focused installer for China use cases. It keeps the output small, but adds the fast direct `trycloudflare.com` TLS 443 style that worked best in testing.

## What it builds

1. `Pooyan-TRY-TLS-443` - direct `trycloudflare.com` host + TLS 443, added because this style gave the best speed in testing
2. `Pooyan-RN-CF-443` - VLESS + WS + TLS 443 using the China-style Cloudflare front address
3. `Pooyan-RN-CF-80` - VLESS + WS port 80 backup using the Cloudflare front address
4. `Pooyan-RN-HY2-443` - Hysteria2 UDP 443 speed-test link
5. `Pooyan-RN-DIRECT-IP` - emergency/direct test link

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh)
```

Choose option `1`.

## Import to v2rayN

After installation, use:

```bash
cat /root/pooyan-v2rayn-import.txt
```

Do not paste VLESS links into the Linux command line. Copy the output into v2rayN, or download `/root/pooyan-v2rayn-import.txt` with WinSCP.

## Manager commands

```bash
pooyan renew
pooyan links
pooyan import
pooyan test
pooyan status
pooyan logs
```

## Important notes

- The old exact `trycloudflare.com` hostname is temporary. This script does not hardcode the old host; it creates a fresh `trycloudflare.com` host and generates the same fast connection type as `Pooyan-TRY-TLS-443`.
- `Pooyan-RN-HY2-443` uses UDP 443. If it does not connect, open UDP `443` in the VPS provider firewall panel and local firewall.
- Direct IP is only backup/test on RackNerd.
- `trycloudflare.com` is temporary, so use `pooyan renew` when the Cloudflare links stop working.
