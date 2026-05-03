#!/usr/bin/env bash
set -e

git pull --rebase
cp pooyan.sh README.md CHANGELOG.md VERSION /path/to/Pooyan/
cd /path/to/Pooyan
rm -f pooyan_0.07.sh README_Pooyan_0.07.md CHANGELOG_Pooyan_0.07.md upload_commands_pooyan_0.07.txt
chmod +x pooyan.sh
git add pooyan.sh README.md CHANGELOG.md VERSION
git add -u
git commit -m "Fix Xray config test in Pooyan 0.09"
git push
