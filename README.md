# Pooyan 0.09

Auto Domain China Edition.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh)
```

## Important fix in 0.09

Version 0.08 restored Auto Domain mode, but one Xray check command was wrong on newer Xray-core builds.

Fixed:

```bash
xray test -config config.json
```

Changed to the compatible check:

```bash
xray run -test -config config.json
```

The script also keeps a fallback for older builds.

## Default behavior

Option 1 is the old easy behavior:

- Auto Domain with `trycloudflare.com`
- No Cloudflare account is required
- No custom domain is required
- The script automatically creates the temporary Cloudflare address and prints VLESS links

## Menu

1. Auto Domain - VLESS + trycloudflare.com, no domain needed
2. Custom Domain - VLESS + Cloudflare Tunnel + service + BBR
3. Advanced - VLESS + REALITY + Vision direct
4. Show current links
5. Manager menu
6. Uninstall

## China recommendation

For the easiest setup in China, choose option 1 first.

For a stable customer setup with your own domain, choose option 2.

For a high-quality CN2/CMI/AS9929 VPS, you can also test option 3.

## Notes

The automatic `trycloudflare.com` address can change after reboot or rerun. This is normal for Cloudflare Quick Tunnel.

For a permanent hostname, use option 2 with your own Cloudflare domain.
