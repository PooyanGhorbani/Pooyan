#!/usr/bin/env bash
set -e

# Run this from your local clone of PooyanGhorbani/Pooyan
cp /path/to/pooyan.sh ./pooyan.sh
cp /path/to/README.md ./README.md
cp /path/to/CHANGELOG.md ./CHANGELOG.md
cp /path/to/VERSION ./VERSION

rm -f pooyan_0.07.sh README_Pooyan_0.07.md CHANGELOG_Pooyan_0.07.md upload_commands_pooyan_0.07.txt

git add pooyan.sh README.md CHANGELOG.md VERSION
git rm -f pooyan_0.07.sh README_Pooyan_0.07.md CHANGELOG_Pooyan_0.07.md upload_commands_pooyan_0.07.txt 2>/dev/null || true
git commit -m "Fix default auto-domain install behavior for Pooyan 0.08"
git push
