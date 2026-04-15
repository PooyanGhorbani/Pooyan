#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="Pooyan"
PROJECT_VERSION="0.01"
APP_TITLE="${PROJECT_NAME} ${PROJECT_VERSION}"

choose_language() {
  clear
  echo "========================================"
  echo "             ${APP_TITLE}"
  echo "========================================"
  echo "1) پارسی   2) English   3) 中文   4) Русский"
  read -rp "Select language [1]: " LANG_CHOICE
  case "${LANG_CHOICE:-1}" in
    1) LANG_CODE="fa" ;;
    2) LANG_CODE="en" ;;
    3) LANG_CODE="zh" ;;
    4) LANG_CODE="ru" ;;
    *) LANG_CODE="en" ;;
  esac
}

main() {
  choose_language
  echo
  echo "${APP_TITLE}"
  echo
  echo "This repository scaffold is ready for GitHub publishing."
  echo "Add your final project logic here before release."
}

main "$@"
