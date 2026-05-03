#!/usr/bin/env bash
set -e

git clone https://github.com/PooyanGhorbani/Pooyan.git
cd Pooyan
cp ../pooyan.sh ./pooyan.sh
cp ../README.md ./README.md
cp ../CHANGELOG.md ./CHANGELOG.md
cp ../VERSION ./VERSION
rm -f pooyan_0.07.sh README_Pooyan_0.07.md CHANGELOG_Pooyan_0.07.md upload_commands_pooyan_0.07.txt || true
git add pooyan.sh README.md CHANGELOG.md VERSION
git commit -m "Restore China stable quick mode 0.13"
git push
