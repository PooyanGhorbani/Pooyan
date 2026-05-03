#!/usr/bin/env bash
set -euo pipefail

# Run this from a folder that contains the clean files:
# pooyan.sh README.md CHANGELOG.md VERSION

git clone https://github.com/PooyanGhorbani/Pooyan.git
cd Pooyan

cp ../pooyan.sh ./pooyan.sh
cp ../README.md ./README.md
cp ../CHANGELOG.md ./CHANGELOG.md
cp ../VERSION ./VERSION
chmod +x ./pooyan.sh

# Remove old versioned files from repo root.
rm -f pooyan_0.07.sh \
      README_Pooyan_0.07.md \
      CHANGELOG_Pooyan_0.07.md \
      upload_commands_pooyan_0.07.txt

git add -A
git commit -m "Release Pooyan 0.07 with clean GitHub file names"
git push origin main

# Quick remote syntax test on any Linux/VPS:
# bash -n <(curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh)
