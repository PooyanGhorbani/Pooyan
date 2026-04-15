#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="Pooyan"
PROJECT_VERSION="0.04"
APP_TITLE="${PROJECT_NAME} ${PROJECT_VERSION}"

GITHUB_USER="PooyanGhorbani"
GITHUB_REPO="Pooyan"
GITHUB_BRANCH="main"
GITHUB_VISIBILITY="public"
GITHUB_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}"
RAW_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/pooyan.sh"

choose_language() {
  clear
  echo "========================================"
  printf "%20s\n" "${APP_TITLE}"
  echo "========================================"
  echo
  echo "1) پارسی"
  echo "2) English"
  echo "3) 中文"
  echo "4) Русский"
  echo
  read -rp "Select language [1]: " LANG_CHOICE
  case "${LANG_CHOICE:-1}" in
    1) LANG_CODE="fa" ;;
    2) LANG_CODE="en" ;;
    3) LANG_CODE="zh" ;;
    4) LANG_CODE="ru" ;;
    *) LANG_CODE="fa" ;;
  esac
}

repo_info() {
  echo "GitHub: ${GITHUB_URL}"
  echo "Repo: ${GITHUB_USER}/${GITHUB_REPO}"
  echo "Branch: ${GITHUB_BRANCH}"
  echo "Visibility: ${GITHUB_VISIBILITY}"
}

public_install_hint() {
  echo "bash <(curl -fsSL ${RAW_URL})"
}

private_install_hint() {
  cat <<'EOF'
1) Upload pooyan.sh to your server manually
2) chmod +x pooyan.sh
3) bash pooyan.sh
EOF
}

t() {
  local key="$1"
  case "$LANG_CODE" in
    fa)
      case "$key" in
        welcome) echo "به ${APP_TITLE} خوش آمدید" ;;
        subtitle) echo "اطلاعات نهایی مخزن GitHub در این نسخه تنظیم شده است." ;;
        repo_note) echo "این ریپو public تنظیم شده است، ولی فایل فعلی هنوز فقط اسکلت رابط است." ;;
        repo_tip) echo "برای نصب یک‌خطی، فایل نهایی pooyan.sh باید در ریشهٔ ریپو push شده باشد." ;;
        menu_title) echo "منوی اصلی" ;;
        quick) echo "1. حالت سریع" ;;
        install) echo "2. نصب سرویس" ;;
        uninstall) echo "3. حذف سرویس" ;;
        cache) echo "4. پاک کردن کش" ;;
        manage) echo "5. مدیریت سرویس" ;;
        repo_menu) echo "6. اطلاعات GitHub و نصب" ;;
        exit) echo "0. خروج" ;;
        prompt) echo "حالت را انتخاب کنید [0]: " ;;
        selected) echo "گزینه انتخاب‌شده:" ;;
        placeholder) echo "در این بسته هنوز فقط رابط آماده است و پروژهٔ کامل هنوز وصل نشده است." ;;
        install_title) echo "راهنمای نصب" ;;
        install_private) echo "روش دستی فعلی:" ;;
        install_public) echo "دستور نصب یک‌خطی GitHub:" ;;
        bye) echo "خروج با موفقیت انجام شد." ;;
        invalid) echo "گزینه نامعتبر است." ;;
      esac ;;
    en)
      case "$key" in
        welcome) echo "Welcome to ${APP_TITLE}" ;;
        subtitle) echo "The final GitHub repository details are configured in this build." ;;
        repo_note) echo "This repo is now set to public, but the current file is still only the interface scaffold." ;;
        repo_tip) echo "For one-line install, the final pooyan.sh must be pushed to the repo root." ;;
        menu_title) echo "Main Menu" ;;
        quick) echo "1. Quick Mode" ;;
        install) echo "2. Install Service" ;;
        uninstall) echo "3. Uninstall Service" ;;
        cache) echo "4. Clear Cache" ;;
        manage) echo "5. Manage Service" ;;
        repo_menu) echo "6. GitHub Info & Install" ;;
        exit) echo "0. Exit" ;;
        prompt) echo "Choose mode [0]: " ;;
        selected) echo "Selected option:" ;;
        placeholder) echo "This package still contains the interface scaffold only; the full project is not connected yet." ;;
        install_title) echo "Install Guide" ;;
        install_private) echo "Current manual method:" ;;
        install_public) echo "GitHub one-line installer:" ;;
        bye) echo "Exited successfully." ;;
        invalid) echo "Invalid option." ;;
      esac ;;
    zh)
      case "$key" in
        welcome) echo "欢迎使用 ${APP_TITLE}" ;;
        subtitle) echo "此版本已经写入最终 GitHub 仓库信息。" ;;
        repo_note) echo "当前仓库已设为 public，但这个文件现在仍然只是界面骨架。" ;;
        repo_tip) echo "想要一键安装，最终版 pooyan.sh 需要 push 到仓库根目录。" ;;
        menu_title) echo "主菜单" ;;
        quick) echo "1. 快速模式" ;;
        install) echo "2. 安装服务" ;;
        uninstall) echo "3. 卸载服务" ;;
        cache) echo "4. 清理缓存" ;;
        manage) echo "5. 管理服务" ;;
        repo_menu) echo "6. GitHub 信息与安装" ;;
        exit) echo "0. 退出" ;;
        prompt) echo "请选择模式 [0]: " ;;
        selected) echo "已选择：" ;;
        placeholder) echo "当前压缩包仍然只包含界面骨架，完整项目还没有接入。" ;;
        install_title) echo "安装说明" ;;
        install_private) echo "当前手动方式：" ;;
        install_public) echo "GitHub 一键安装命令：" ;;
        bye) echo "已成功退出。" ;;
        invalid) echo "选项无效。" ;;
      esac ;;
    ru)
      case "$key" in
        welcome) echo "Добро пожаловать в ${APP_TITLE}" ;;
        subtitle) echo "В этой версии уже прописаны финальные данные GitHub-репозитория." ;;
        repo_note) echo "Репозиторий теперь public, но текущий файл всё ещё только каркас интерфейса." ;;
        repo_tip) echo "Для однострочной установки финальный pooyan.sh должен быть загружен в корень репозитория." ;;
        menu_title) echo "Главное меню" ;;
        quick) echo "1. Быстрый режим" ;;
        install) echo "2. Установить сервис" ;;
        uninstall) echo "3. Удалить сервис" ;;
        cache) echo "4. Очистить кэш" ;;
        manage) echo "5. Управление сервисом" ;;
        repo_menu) echo "6. GitHub и установка" ;;
        exit) echo "0. Выход" ;;
        prompt) echo "Выберите режим [0]: " ;;
        selected) echo "Выбрано:" ;;
        placeholder) echo "В этом пакете пока только интерфейс; полный проект ещё не подключён." ;;
        install_title) echo "Инструкция по установке" ;;
        install_private) echo "Текущий ручной способ:" ;;
        install_public) echo "GitHub однострочная установка:" ;;
        bye) echo "Выход выполнен успешно." ;;
        invalid) echo "Неверный пункт меню." ;;
      esac ;;
  esac
}

banner() {
  clear
  echo "========================================"
  printf "%20s\n" "${APP_TITLE}"
  echo "========================================"
  echo
}

main_menu_ui() {
  banner
  echo "$(t welcome)"
  echo "$(t subtitle)"
  echo "$(t repo_note)"
  echo "$(t repo_tip)"
  echo
  repo_info
  echo
  echo "$(t menu_title)"
  echo "$(t quick)"
  echo "$(t install)"
  echo "$(t uninstall)"
  echo "$(t cache)"
  echo "$(t manage)"
  echo "$(t repo_menu)"
  echo "$(t exit)"
  echo
}

show_install_info() {
  echo
  echo "$(t install_title)"
  repo_info
  echo
  echo "$(t install_private)"
  private_install_hint
  echo
  echo "$(t install_public)"
  public_install_hint
  echo
}

main() {
  choose_language
  main_menu_ui
  read -rp "$(t prompt)" mode
  mode="${mode:-0}"

  case "$mode" in
    0)
      echo "$(t bye)"
      ;;
    6)
      show_install_info
      ;;
    1|2|3|4|5)
      echo
      echo "$(t selected) $mode"
      echo "$(t placeholder)"
      ;;
    *)
      echo
      echo "$(t invalid)"
      ;;
  esac
}

main "$@"
