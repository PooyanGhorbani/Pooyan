# Pooyan 0.11

China-friendly Xray installer with three modes:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh)
```

## Modes

1. **Quick Mode - Auto trycloudflare.com + Direct IP fallback**
   - No domain needed
   - No Cloudflare account needed
   - Creates a Direct IP VLESS/WS link first
   - Then tries to create a temporary `trycloudflare.com` link
   - If Cloudflare quick tunnel fails, the Direct IP link is still saved

2. **Custom Domain Mode - VLESS + WS + Cloudflare Tunnel**
   - Needs your own Cloudflare domain
   - Stable hostname
   - Runs as systemd services
   - Enables BBR when possible

3. **Advanced Mode - VLESS + REALITY + Vision**
   - Direct VPS mode
   - Recommended only for good China routes such as CN2 / CMI / AS9929

## Manager

After installation:

```bash
pooyan
```

Links are saved here:

```text
/opt/pooyan/v2ray.txt
/root/v2ray.txt
```

## Important notes

- Quick `trycloudflare.com` addresses are temporary and can change after rerun/reboot.
- Direct IP links need the TCP port open in the VPS firewall/security group.
- For China, test several Cloudflare ports and keep the fastest stable one.
- If Quick Mode cannot get a trycloudflare URL, check:

```bash
cat /tmp/pooyan-argo.log
cat /tmp/pooyan-xray.log
```
