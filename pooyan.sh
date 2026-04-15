#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="Pooyan"
PROJECT_VERSION="0.02"
APP_TITLE="${PROJECT_NAME} ${PROJECT_VERSION}"

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

t() {
  local key="$1"
  case "$LANG_CODE" in
    fa)
      case "$key" in
        welcome) echo "به ${APP_TITLE} خوش آمدید" ;;
        subtitle) echo "رابط چهارزبانه پروژه آماده است." ;;
        note) echo "منطق نهایی پروژه را در بخش‌های مربوطه اضافه کنید." ;;
        menu_title) echo "منوی اصلی" ;;
        quick) echo "1. حالت سریع" ;;
        install) echo "2. نصب سرویس" ;;
        uninstall) echo "3. حذف سرویس" ;;
        cache) echo "4. پاک کردن کش" ;;
        manage) echo "5. مدیریت سرویس" ;;
        exit) echo "0. خروج" ;;
        prompt) echo "حالت را انتخاب کنید [0]: " ;;
        selected) echo "گزینه انتخاب‌شده:" ;;
        placeholder) echo "در این پکیج فقط رابط آماده شده است. منطق نهایی را خودت به این بخش وصل کن." ;;
        bye) echo "خروج با موفقیت انجام شد." ;;
        invalid) echo "گزینه نامعتبر است." ;;
      esac ;;
    en)
      case "$key" in
        welcome) echo "Welcome to ${APP_TITLE}" ;;
        subtitle) echo "The multilingual interface is ready." ;;
        note) echo "Add your final project logic in the relevant sections." ;;
        menu_title) echo "Main Menu" ;;
        quick) echo "1. Quick Mode" ;;
        install) echo "2. Install Service" ;;
        uninstall) echo "3. Uninstall Service" ;;
        cache) echo "4. Clear Cache" ;;
        manage) echo "5. Manage Service" ;;
        exit) echo "0. Exit" ;;
        prompt) echo "Choose mode [0]: " ;;
        selected) echo "Selected option:" ;;
        placeholder) echo "This package currently includes the interface scaffold only. Plug your final logic into this section." ;;
        bye) echo "Exited successfully." ;;
        invalid) echo "Invalid option." ;;
      esac ;;
    zh)
      case "$key" in
        welcome) echo "欢迎使用 ${APP_TITLE}" ;;
        subtitle) echo "四语言界面已准备完成。" ;;
        note) echo "请在对应位置加入你的最终项目逻辑。" ;;
        menu_title) echo "主菜单" ;;
        quick) echo "1. 快速模式" ;;
        install) echo "2. 安装服务" ;;
        uninstall) echo "3. 卸载服务" ;;
        cache) echo "4. 清理缓存" ;;
        manage) echo "5. 管理服务" ;;
        exit) echo "0. 退出" ;;
        prompt) echo "请选择模式 [0]: " ;;
        selected) echo "已选择：" ;;
        placeholder) echo "此压缩包当前仅包含界面骨架，请在这里接入你的最终逻辑。" ;;
        bye) echo "已成功退出。" ;;
        invalid) echo "选项无效。" ;;
      esac ;;
    ru)
      case "$key" in
        welcome) echo "Добро пожаловать в ${APP_TITLE}" ;;
        subtitle) echo "Четырёхъязычный интерфейс готов." ;;
        note) echo "Добавьте финальную логику проекта в соответствующие разделы." ;;
        menu_title) echo "Главное меню" ;;
        quick) echo "1. Быстрый режим" ;;
        install) echo "2. Установить сервис" ;;
        uninstall) echo "3. Удалить сервис" ;;
        cache) echo "4. Очистить кэш" ;;
        manage) echo "5. Управление сервисом" ;;
        exit) echo "0. Выход" ;;
        prompt) echo "Выберите режим [0]: " ;;
        selected) echo "Выбрано:" ;;
        placeholder) echo "Сейчас в пакете только интерфейс. Подключите сюда финальную логику проекта." ;;
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
  echo "$(t note)"
  echo
  echo "$(t menu_title)"
  echo "$(t quick)"
  echo "$(t install)"
  echo "$(t uninstall)"
  echo "$(t cache)"
  echo "$(t manage)"
  echo "$(t exit)"
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
