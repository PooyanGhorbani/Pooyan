# Pooyan 0.10

China-friendly Xray installer with three practical modes:

1. **Quick Mode**: VLESS + WebSocket + automatic `trycloudflare.com` address, plus one **Direct IP link without domain** for speed testing.
2. **Custom Domain Mode**: VLESS + WebSocket + Cloudflare Tunnel with your own fixed Cloudflare domain.
3. **Advanced Mode**: VLESS + REALITY + Vision direct connection for good VPS routes such as CN2 / CMI / AS9929.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh)
```

## Recommended for China

Start with **Option 1 - Quick Mode**.

It creates:

- Cloudflare automatic `trycloudflare.com` links
- Cloudflare preferred-IP style links
- One direct VPS IP link without domain

The Direct IP link is only for quick speed testing. If it does not connect, open the generated TCP port in your VPS provider firewall/security group.

## Manager

After installation:

```bash
pooyan
```

## Files

Links are saved here:

```text
/opt/pooyan/v2ray.txt
/root/v2ray.txt
```

## Notes

- Quick Mode does not need a Cloudflare account or domain.
- `trycloudflare.com` addresses can change after reboot or rerun.
- For fixed addresses, use Custom Domain Mode.
- For the best direct VPS route, test Advanced REALITY/Vision mode.
