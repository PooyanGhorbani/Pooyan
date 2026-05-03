# GitHub Web Upload Guide

Replace only these files in the root of the repository:

- `pooyan.sh`
- `README.md`
- `CHANGELOG.md`
- `VERSION`

Do not upload versioned script names like `pooyan_0.14.sh` to the repository root.

After upload, install with:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh)
```

For RackNerd, choose option `1`.
