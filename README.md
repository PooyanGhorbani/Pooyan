# Pooyan 0.08

Auto Domain China Edition.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh)
```

## Important fix in 0.08

Version 0.07 asked for a Cloudflare domain by default. This was not the old behavior.

Version 0.08 restores the old easy behavior as the default:

- Option 1: Auto Domain with `trycloudflare.com`
- No Cloudflare account is required
- No domain is required
- The script automatically creates the temporary Cloudflare address and prints VLESS links

If you want a fixed custom domain, use option 2.

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
