# Changelog

## 0.11

- Fixed Quick Mode behavior when `trycloudflare.com` URL is not returned.
- Direct IP link is now generated first and saved even if Cloudflare quick tunnel fails.
- Quick Mode now tries multiple cloudflared launch modes: default, http2, and quic.
- Increased wait time for Cloudflare quick tunnel URL detection.
- Removed hard dependency on quick tunnel success for the no-domain test link.
- Better error output with `/tmp/pooyan-argo.log` and `/tmp/pooyan-xray.log` hints.

## 0.10

- Added Direct IP no-domain link in Quick Mode.

## 0.09

- Fixed Xray config test command compatibility.

## 0.08

- Restored Auto Domain mode using `trycloudflare.com` without needing a domain.

## 0.07

- Added China Recommended layout, BBR, Cloudflare port lists, and Reality/Vision mode.
