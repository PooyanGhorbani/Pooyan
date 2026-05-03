# Pooyan 0.12

China-focused Xray installer with a safer Quick Mode.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh)
```

## Recommended for China

Choose option **1** first:

```text
Quick Mode - Direct IP first + Auto trycloudflare.com
```

This mode now creates the Direct IP link first, installs the `pooyan` manager command, and then tries to create a temporary `trycloudflare.com` link.

## Important v2rayN note

Do not paste VLESS links into the Linux shell. The `&` characters inside VLESS links are shell control characters.

Use one of these files instead:

```bash
cat /root/v2ray.txt
cat /root/pooyan-v2rayn-import.txt
```

For the cleanest v2rayN import, download this file with WinSCP or another SFTP client:

```text
/root/pooyan-v2rayn-import.txt
```

## Manager

After installation, run:

```bash
pooyan
```

The manager can show links, logs, restart services, and uninstall Pooyan.

## Files

```text
/opt/pooyan/config.json
/opt/pooyan/v2ray.txt
/root/v2ray.txt
/root/pooyan-v2rayn-import.txt
/root/pooyan-sub-base64.txt
/usr/bin/pooyan
```

## Modes

1. **Quick Mode** — Direct IP first, then trycloudflare.com if Cloudflare is reachable.
2. **Custom Domain** — Cloudflare Tunnel with your own domain.
3. **Advanced Reality** — VLESS + REALITY + Vision direct mode for good CN2/CMI/AS9929 VPS routes.
