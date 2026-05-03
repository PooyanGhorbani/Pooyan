# Changelog

## 0.09

Emergency fix for Xray-core config validation.

### Fixed

- Fixed the `xray test: unknown command` error.
- Replaced the broken direct `xray test -config` call with `xray run -test -config`.
- Added a compatibility function that tries the new command first and keeps fallback behavior for older builds.
- Auto Domain mode still does not ask for a custom domain.

### Changed

- Version bumped from 0.08 to 0.09.
- README updated with the Xray test fix.

## 0.08

Emergency fix for default installation behavior.

### Fixed

- Restored the old default behavior: the script no longer asks for a domain by default.
- Option 1 now uses automatic `trycloudflare.com` address generation.
- Custom Cloudflare domain setup moved to option 2.
- Menu text now clearly says which mode needs a domain and which mode does not.

### Changed

- Version bumped from 0.07 to 0.08.
- README updated to explain Auto Domain vs Custom Domain.

## 0.07

- Added China Recommended mode.
- Added Cloudflare custom domain tunnel mode.
- Added multi-port VLESS WS links.
- Added REALITY/Vision mode.
- Added BBR helper.
