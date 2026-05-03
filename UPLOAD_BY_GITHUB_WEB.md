# Upload with GitHub web UI

Upload/replace only these files in the repository root:

- `pooyan.sh`
- `README.md`
- `CHANGELOG.md`
- `VERSION`
- `LICENSE` stays as-is

Delete these old/versioned helper files from the repository root:

- `pooyan_0.07.sh`
- `README_Pooyan_0.07.md`
- `CHANGELOG_Pooyan_0.07.md`
- `upload_commands_pooyan_0.07.txt`

After this, the install command stays fixed:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh)
```
