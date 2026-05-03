# Changelog

## 0.12

- Fixed Quick Mode not installing the `pooyan` manager command.
- Quick Mode now creates a persistent Xray systemd service for the Direct IP link.
- Quick Mode now creates the Direct IP link first, before trying Cloudflare.
- Quick Mode now creates `/root/pooyan-v2rayn-import.txt` with pure VLESS links only.
- Quick Mode no longer generates CF Preferred IP links by default, because they confused v2rayN testing and caused TLS handshake errors when used before confirming the normal Argo link.
- Encoded WebSocket path as `%2F...` in generated links to reduce client import problems.
- Added warnings not to paste VLESS links into the Linux shell, because `&` breaks the command.

## 0.11

- Added Direct IP fallback when trycloudflare.com fails.

## 0.10

- Added a Direct IP test link to Quick Mode.

## 0.09

- Fixed Xray config test command compatibility.

## 0.08

- Restored Auto Domain mode with trycloudflare.com.

## 0.07

- Added China Recommended mode, VLESS defaults, BBR, Cloudflare port list, and Reality/Vision mode.
