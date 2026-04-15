#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="Pooyan"
PROJECT_VERSION="0.06"
APP_TITLE="${PROJECT_NAME} ${PROJECT_VERSION}"
APP_DIR="/opt/pooyan"
APP_CMD_NAME="pooyan"
APP_CMD_PATH="/usr/bin/${APP_CMD_NAME}"

GITHUB_USER="PooyanGhorbani"
GITHUB_REPO="Pooyan"
GITHUB_BRANCH="main"
GITHUB_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}"
RAW_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/pooyan.sh"

linux_os=("Debian" "Ubuntu" "CentOS" "Fedora" "Alpine")
linux_update=("apt update" "apt update" "yum -y update" "yum -y update" "apk update")
linux_install=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "apk add -f")
LANG_CODE="fa"

get_os_name() {
  grep -i PRETTY_NAME /etc/os-release | cut -d '"' -f2 | awk '{print $1}'
}

get_os_index() {
  local current_os
  current_os="$(get_os_name)"
  local idx=0
  for i in "${linux_os[@]}"; do
    if [ "$i" = "$current_os" ]; then
      echo "$idx"
      return
    fi
    idx=$((idx+1))
  done
  echo 0
}

pid_field() {
  if [ "$(get_os_name)" = "Alpine" ]; then
    echo 1
  else
    echo 2
  fi
}

kill_matching() {
  local pattern="$1"
  local field
  field="$(pid_field)"
  local pids
  pids="$(ps -ef | grep "$pattern" | grep -v grep | awk "{print \$$field}" | xargs echo -n 2>/dev/null || true)"
  if [ -n "${pids:-}" ]; then
    kill -9 $pids >/dev/null 2>&1 || true
  fi
}

ensure_dependencies() {
  local n
  n="$(get_os_index)"
  if ! command -v unzip >/dev/null 2>&1; then
    ${linux_update[$n]}
    ${linux_install[$n]} unzip
  fi
  if ! command -v curl >/dev/null 2>&1; then
    ${linux_update[$n]}
    ${linux_install[$n]} curl
  fi
  if [ "$(get_os_name)" != "Alpine" ] && ! command -v systemctl >/dev/null 2>&1; then
    ${linux_update[$n]}
    ${linux_install[$n]} systemd
  fi
}

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
  case "${LANG_CODE}" in
    fa)
      case "$key" in
        app_welcome) echo "به ${APP_TITLE} خوش آمدید" ;;
        quick_desc_1) echo "حالت سريع به دامنه کلادفلر نياز ندارد." ;;
        quick_desc_2) echo "اين حالت پس از ريست يا اجراي دوباره بايد دوباره ساخته شود." ;;
        install_desc_1) echo "حالت نصب سرويس به دامنه متصل به کلادفلر نياز دارد." ;;
        install_desc_2) echo "پس از اولين ورود، پوشه /root/.cloudflared را نگه داريد." ;;
        site_light) echo "Pooyan Light:" ;;
        site_nat) echo "Pooyan NAT:" ;;
        reboot_note) echo "توجه: حالت سریع بعد از ریبوت سرور غیرفعال می‌شود." ;;
        slogan) echo "Pooyan 0.06" ;;
        menu_1) echo "1. حالت سریع" ;;
        menu_2) echo "2. نصب سرویس" ;;
        menu_3) echo "3. حذف سرویس" ;;
        menu_4) echo "4. پاک کردن کش" ;;
        menu_5) echo "5. مدیریت سرویس" ;;
        menu_6) echo "6. اطلاعات GitHub و نصب" ;;
        menu_0) echo "0. خروج" ;;
        choose_mode) echo "Select mode [1]: " ;;
        choose_protocol) echo "Select protocol [1=vmess,2=vless]: " ;;
        choose_ip_mode) echo "Select IP mode [4/6]: " ;;
        invalid_protocol) echo "پروتکل xray نامعتبر است." ;;
        invalid_ip_mode) echo "حالت اتصال argo نامعتبر است." ;;
        service_installed_jump) echo "سرویس از قبل نصب شده؛ ورود به منوی مدیریت..." ;;
        manage_not_installed) echo "سرویس مدیریت نصب نشده؛ اول گزینه 2 را اجرا کنید." ;;
        exit_ok) echo "خروج با موفقیت انجام شد." ;;
        uninstall_done) echo "همه سرویس‌ها حذف شدند." ;;
        delete_auth_note_1) echo "برای حذف کامل مجوزها:" ;;
        delete_auth_note_2) echo "به این آدرس برو:" ;;
        delete_auth_note_3) echo "و Argo Tunnel API Token را حذف کن." ;;
        no_domain) echo "دامنه وارد نشده است." ;;
        bad_domain) echo "فرمت دامنه درست نیست." ;;
        unsupported_arch) echo "این معماری پشتیبانی نمی‌شود:" ;;
        unsupported_os) echo "این سیستم‌عامل پشتیبانی نمی‌شود:" ;;
        fallback_apt) echo "به‌صورت پیش‌فرض از APT استفاده می‌شود." ;;
        wait_argo) echo "در انتظار ساخت آدرس Cloudflare Argo..." ;;
        wait_seconds) echo "ثانیه گذشته" ;;
        argo_timeout_retry) echo "دریافت Argo timeout شد، تلاش دوباره..." ;;
        vmess_ready) echo "لینک vmess ساخته شد. cloudflare.182682.xyz را می‌توان با CF Preferred IP جایگزین کرد." ;;
        vless_ready) echo "لینک vless ساخته شد. cloudflare.182682.xyz را می‌توان با CF Preferred IP جایگزین کرد." ;;
        saved_path) echo "اطلاعات در /root/v2ray.txt ذخیره شد. برای مشاهده دوباره: cat /root/v2ray.txt" ;;
        quick_invalid_after_reboot) echo "توجه: حالت سریع بعد از ریبوت سرور از کار می‌افتد." ;;
        copy_open_auth) echo "لینک زیر را کپی کن، در مرورگر باز کن و دامنه را authorize کن." ;;
        auth_continue) echo "بعد از تکمیل authorize، مرحله بعد ادامه پیدا می‌کند." ;;
        current_bound_services) echo "سرویس‌های متصل فعلی ARGO TUNNEL:" ;;
        custom_subdomain) echo "یک زیردامنه کامل وارد کن. مثال: xxx.example.com" ;;
        domain_must_authorized) echo "دامنه باید از همان دامنه‌های authorize‌شده در Cloudflare باشد." ;;
        input_full_domain) echo "دامنه کامل را وارد کنید: " ;;
        tunnel_create) echo "در حال ساخت TUNNEL:" ;;
        tunnel_created) echo "ساخته شد:" ;;
        tunnel_exists) echo "از قبل وجود دارد:" ;;
        tunnel_cleanup) echo "در حال پاکسازی TUNNEL:" ;;
        tunnel_delete) echo "در حال حذف TUNNEL:" ;;
        tunnel_rebuild) echo "در حال بازسازی TUNNEL:" ;;
        bind_tunnel_domain) echo "در حال اتصال TUNNEL به دامنه:" ;;
        bind_success) echo "اتصال دامنه با موفقیت انجام شد:" ;;
        install_complete) echo "نصب سرویس کامل شد. برای مدیریت سرویس دستور pooyan را اجرا کن." ;;
        port443_hint) echo "پورت 443 را می‌توان به 2053 2083 2087 2096 8443 تغییر داد." ;;
        port80_hint) echo "پورت 80 را می‌توان به 8080 8880 2052 2082 2086 2095 تغییر داد." ;;
        cf_https_note1) echo "اگر پورت‌های 80/8080/8880/2052/2082/2086/2095 کار نکردند:" ;;
        cf_https_note2) echo "به https://dash.cloudflare.com/ برو." ;;
        cf_https_note3) echo "SSL/TLS > Edge Certificates > Always Use HTTPS را خاموش کن." ;;
        github_title) echo "GitHub and install" ;;
        github_repo) echo "مخزن:" ;;
        github_branch) echo "شاخه:" ;;
        github_install) echo "نصب یک‌خطی GitHub:" ;;
        github_note) echo "فايل pooyan.sh را در ريشه repo قرار بده." ;;
        manager_menu) echo "منوی مدیریت" ;;
        already_installed) echo "سرویس از قبل نصب است." ;;
        *) echo "$key" ;;
      esac
      ;;
    en)
      case "$key" in
        app_welcome) echo "Welcome to ${APP_TITLE}" ;;
        quick_desc_1) echo "Quick mode does not require your own Cloudflare domain and uses CF Argo Quick Tunnel." ;;
        quick_desc_2) echo "Quick mode becomes invalid after reboot or after rerunning the script and must be recreated." ;;
        install_desc_1) echo "Service install mode requires a Cloudflare-managed domain and manual Argo binding." ;;
        install_desc_2) echo "After the first Argo login, keep /root/.cloudflared to skip logging in again." ;;
        site_light) echo "Pooyan Light:" ;;
        site_nat) echo "Pooyan NAT:" ;;
        reboot_note) echo "Note: Quick mode stops working after server reboot." ;;
        slogan) echo "Pooyan 0.06" ;;
        menu_1) echo "1. Quick mode" ;;
        menu_2) echo "2. Install service" ;;
        menu_3) echo "3. Uninstall service" ;;
        menu_4) echo "4. Clear cache" ;;
        menu_5) echo "5. Manage service" ;;
        menu_6) echo "6. GitHub info & install" ;;
        menu_0) echo "0. Exit" ;;
        choose_mode) echo "Choose mode (default 1): " ;;
        choose_protocol) echo "Choose xray protocol (default 1=vmess, 2=vless): " ;;
        choose_ip_mode) echo "Choose argo IP mode IPV4 or IPV6 (4 or 6, default 4): " ;;
        invalid_protocol) echo "Invalid xray protocol." ;;
        invalid_ip_mode) echo "Invalid argo IP mode." ;;
        service_installed_jump) echo "Service is already installed. Opening management menu..." ;;
        manage_not_installed) echo "Management service is not installed. Run option 2 first." ;;
        exit_ok) echo "Exited successfully." ;;
        uninstall_done) echo "All services have been removed." ;;
        delete_auth_note_1) echo "To completely remove authorization:" ;;
        delete_auth_note_2) echo "Go to:" ;;
        delete_auth_note_3) echo "and delete the Argo Tunnel API Token." ;;
        no_domain) echo "No domain was entered." ;;
        bad_domain) echo "Invalid domain format." ;;
        unsupported_arch) echo "Unsupported architecture:" ;;
        unsupported_os) echo "Unsupported operating system:" ;;
        fallback_apt) echo "APT will be used by default." ;;
        wait_argo) echo "Waiting for Cloudflare Argo address generation..." ;;
        wait_seconds) echo "seconds elapsed" ;;
        argo_timeout_retry) echo "Argo timed out, retrying..." ;;
        vmess_ready) echo "vmess link generated. cloudflare.182682.xyz can be replaced with a preferred CF IP." ;;
        vless_ready) echo "vless link generated. cloudflare.182682.xyz can be replaced with a preferred CF IP." ;;
        saved_path) echo "Information saved to /root/v2ray.txt. To view again: cat /root/v2ray.txt" ;;
        quick_invalid_after_reboot) echo "Warning: Quick mode becomes invalid after reboot." ;;
        copy_open_auth) echo "Copy the link below, open it in your browser, and authorize the domain." ;;
        auth_continue) echo "After authorization, the next step will continue automatically." ;;
        current_bound_services) echo "Currently bound ARGO TUNNEL services:" ;;
        custom_subdomain) echo "Enter a full subdomain, for example: xxx.example.com" ;;
        domain_must_authorized) echo "The domain must belong to the authorized domains in Cloudflare." ;;
        input_full_domain) echo "Enter the full subdomain: " ;;
        tunnel_create) echo "Creating TUNNEL:" ;;
        tunnel_created) echo "Created:" ;;
        tunnel_exists) echo "Already exists:" ;;
        tunnel_cleanup) echo "Cleaning up TUNNEL:" ;;
        tunnel_delete) echo "Deleting TUNNEL:" ;;
        tunnel_rebuild) echo "Rebuilding TUNNEL:" ;;
        bind_tunnel_domain) echo "Binding TUNNEL to domain:" ;;
        bind_success) echo "Domain bound successfully:" ;;
        install_complete) echo "Service installation completed. Run 'pooyan' to manage it." ;;
        port443_hint) echo "Port 443 can be changed to 2053 2083 2087 2096 8443." ;;
        port80_hint) echo "Port 80 can be changed to 8080 8880 2052 2082 2086 2095." ;;
        cf_https_note1) echo "If ports 80/8080/8880/2052/2082/2086/2095 do not work:" ;;
        cf_https_note2) echo "Go to https://dash.cloudflare.com/" ;;
        cf_https_note3) echo "Disable SSL/TLS > Edge Certificates > Always Use HTTPS." ;;
        github_title) echo "GitHub & install" ;;
        github_repo) echo "Repository:" ;;
        github_branch) echo "Branch:" ;;
        github_install) echo "GitHub one-line installer:" ;;
        github_note) echo "This works after you upload this exact file as pooyan.sh to the repo root." ;;
        manager_menu) echo "Management menu" ;;
        already_installed) echo "Service is already installed." ;;
        *) echo "$key" ;;
      esac
      ;;
    zh)
      case "$key" in
        app_welcome) echo "欢迎使用 ${APP_TITLE}" ;;
        quick_desc_1) echo "快速模式不需要自己的 Cloudflare 域名，使用 CF Argo Quick Tunnel 创建快速链接。" ;;
        quick_desc_2) echo "快速模式在重启或再次运行脚本后会失效，需要重新创建。" ;;
        install_desc_1) echo "安装服务模式需要 Cloudflare 托管域名，并按提示手动绑定 Argo 服务。" ;;
        install_desc_2) echo "首次绑定 Argo 后，保留 /root/.cloudflared 即可跳过再次登录。" ;;
        site_light) echo "Pooyan Light:" ;;
        site_nat) echo "Pooyan NAT:" ;;
        reboot_note) echo "注意：快速模式重启服务器后会失效。" ;;
        slogan) echo "Pooyan 0.06" ;;
        menu_1) echo "1. 快速模式" ;;
        menu_2) echo "2. 安装服务" ;;
        menu_3) echo "3. 卸载服务" ;;
        menu_4) echo "4. 清空缓存" ;;
        menu_5) echo "5. 管理服务" ;;
        menu_6) echo "6. GitHub 信息与安装" ;;
        menu_0) echo "0. 退出" ;;
        choose_mode) echo "请选择模式（默认1）: " ;;
        choose_protocol) echo "请选择 xray 协议（默认1=vmess，2=vless）: " ;;
        choose_ip_mode) echo "请选择 argo 连接模式 IPV4 或 IPV6（4或6，默认4）: " ;;
        invalid_protocol) echo "xray 协议输入错误。" ;;
        invalid_ip_mode) echo "argo 连接模式输入错误。" ;;
        service_installed_jump) echo "服务已安装，正在进入管理菜单..." ;;
        manage_not_installed) echo "管理服务未安装，请先执行模式2。" ;;
        exit_ok) echo "已成功退出。" ;;
        uninstall_done) echo "所有服务都已卸载完成。" ;;
        delete_auth_note_1) echo "如需彻底删除授权：" ;;
        delete_auth_note_2) echo "请访问：" ;;
        delete_auth_note_3) echo "并删除 Argo Tunnel API Token。" ;;
        no_domain) echo "没有输入域名。" ;;
        bad_domain) echo "域名格式不正确。" ;;
        unsupported_arch) echo "当前架构没有适配：" ;;
        unsupported_os) echo "当前系统没有适配：" ;;
        fallback_apt) echo "默认使用 APT 包管理器。" ;;
        wait_argo) echo "等待 Cloudflare Argo 生成地址中..." ;;
        wait_seconds) echo "秒" ;;
        argo_timeout_retry) echo "Argo 获取超时，重试中..." ;;
        vmess_ready) echo "vmess 链接已生成，cloudflare.182682.xyz 可替换为 CF 优选 IP。" ;;
        vless_ready) echo "vless 链接已生成，cloudflare.182682.xyz 可替换为 CF 优选 IP。" ;;
        saved_path) echo "信息已保存在 /root/v2ray.txt，再次查看请运行：cat /root/v2ray.txt" ;;
        quick_invalid_after_reboot) echo "注意：快速模式重启服务器后会失效。" ;;
        copy_open_auth) echo "复制下面的链接，用浏览器打开并授权需要绑定的域名。" ;;
        auth_continue) echo "网页授权完成后会继续下一步设置。" ;;
        current_bound_services) echo "ARGO TUNNEL 当前已经绑定的服务如下：" ;;
        custom_subdomain) echo "请输入一个完整二级域名，例如：xxx.example.com" ;;
        domain_must_authorized) echo "必须是网页中已授权的域名，否则不会生效。" ;;
        input_full_domain) echo "输入绑定域名的完整二级域名: " ;;
        tunnel_create) echo "创建 TUNNEL：" ;;
        tunnel_created) echo "创建成功：" ;;
        tunnel_exists) echo "TUNNEL 已存在：" ;;
        tunnel_cleanup) echo "清理 TUNNEL：" ;;
        tunnel_delete) echo "删除 TUNNEL：" ;;
        tunnel_rebuild) echo "重建 TUNNEL：" ;;
        bind_tunnel_domain) echo "绑定 TUNNEL 到域名：" ;;
        bind_success) echo "绑定成功：" ;;
        install_complete) echo "服务安装完成，管理服务请运行命令 pooyan。" ;;
        port443_hint) echo "443 端口可改为 2053 2083 2087 2096 8443。" ;;
        port80_hint) echo "80 端口可改为 8080 8880 2052 2082 2086 2095。" ;;
        cf_https_note1) echo "如果 80/8080/8880/2052/2082/2086/2095 无法正常使用：" ;;
        cf_https_note2) echo "请前往 https://dash.cloudflare.com/" ;;
        cf_https_note3) echo "关闭 SSL/TLS > 边缘证书 > Always Use HTTPS。" ;;
        github_title) echo "GitHub 与安装" ;;
        github_repo) echo "仓库：" ;;
        github_branch) echo "分支：" ;;
        github_install) echo "GitHub 一键安装命令：" ;;
        github_note) echo "把这个文件以 pooyan.sh 放到仓库根目录后，这个命令就能直接使用。" ;;
        manager_menu) echo "管理菜单" ;;
        already_installed) echo "服务已经安装。" ;;
        *) echo "$key" ;;
      esac
      ;;
    ru)
      case "$key" in
        app_welcome) echo "Добро пожаловать в ${APP_TITLE}" ;;
        quick_desc_1) echo "Быстрый режим не требует собственного домена Cloudflare и использует CF Argo Quick Tunnel." ;;
        quick_desc_2) echo "Быстрый режим перестает работать после перезагрузки или повторного запуска скрипта." ;;
        install_desc_1) echo "Режим установки сервиса требует домен под управлением Cloudflare и ручную привязку Argo." ;;
        install_desc_2) echo "После первого входа в Argo сохраните /root/.cloudflared, чтобы не входить повторно." ;;
        site_light) echo "Pooyan Light:" ;;
        site_nat) echo "Pooyan NAT:" ;;
        reboot_note) echo "Внимание: быстрый режим перестает работать после перезагрузки сервера." ;;
        slogan) echo "Pooyan 0.06" ;;
        menu_1) echo "1. Быстрый режим" ;;
        menu_2) echo "2. Установить сервис" ;;
        menu_3) echo "3. Удалить сервис" ;;
        menu_4) echo "4. Очистить кэш" ;;
        menu_5) echo "5. Управление сервисом" ;;
        menu_6) echo "6. GitHub и установка" ;;
        menu_0) echo "0. Выход" ;;
        choose_mode) echo "Выберите режим (по умолчанию 1): " ;;
        choose_protocol) echo "Выберите протокол xray (по умолчанию 1=vmess, 2=vless): " ;;
        choose_ip_mode) echo "Выберите режим argo IPV4 или IPV6 (4 или 6, по умолчанию 4): " ;;
        invalid_protocol) echo "Неверный протокол xray." ;;
        invalid_ip_mode) echo "Неверный режим argo." ;;
        service_installed_jump) echo "Сервис уже установлен. Открываю меню управления..." ;;
        manage_not_installed) echo "Сервис управления не установлен. Сначала выберите пункт 2." ;;
        exit_ok) echo "Выход выполнен успешно." ;;
        uninstall_done) echo "Все сервисы удалены." ;;
        delete_auth_note_1) echo "Чтобы полностью удалить авторизацию:" ;;
        delete_auth_note_2) echo "Перейдите сюда:" ;;
        delete_auth_note_3) echo "и удалите Argo Tunnel API Token." ;;
        no_domain) echo "Домен не введён." ;;
        bad_domain) echo "Неверный формат домена." ;;
        unsupported_arch) echo "Неподдерживаемая архитектура:" ;;
        unsupported_os) echo "Неподдерживаемая ОС:" ;;
        fallback_apt) echo "По умолчанию будет использоваться APT." ;;
        wait_argo) echo "Ожидание генерации адреса Cloudflare Argo..." ;;
        wait_seconds) echo "секунд прошло" ;;
        argo_timeout_retry) echo "Тайм-аут Argo, повторная попытка..." ;;
        vmess_ready) echo "Ссылка vmess создана. cloudflare.182682.xyz можно заменить на предпочтительный CF IP." ;;
        vless_ready) echo "Ссылка vless создана. cloudflare.182682.xyz можно заменить на предпочтительный CF IP." ;;
        saved_path) echo "Информация сохранена в /root/v2ray.txt. Для просмотра: cat /root/v2ray.txt" ;;
        quick_invalid_after_reboot) echo "Внимание: быстрый режим перестает работать после перезагрузки." ;;
        copy_open_auth) echo "Скопируйте ссылку ниже, откройте её в браузере и авторизуйте домен." ;;
        auth_continue) echo "После завершения авторизации настройка продолжится автоматически." ;;
        current_bound_services) echo "Текущие привязанные сервисы ARGO TUNNEL:" ;;
        custom_subdomain) echo "Введите полный поддомен, например: xxx.example.com" ;;
        domain_must_authorized) echo "Домен должен относиться к уже авторизованным доменам в Cloudflare." ;;
        input_full_domain) echo "Введите полный поддомен: " ;;
        tunnel_create) echo "Создание TUNNEL:" ;;
        tunnel_created) echo "Создано:" ;;
        tunnel_exists) echo "Уже существует:" ;;
        tunnel_cleanup) echo "Очистка TUNNEL:" ;;
        tunnel_delete) echo "Удаление TUNNEL:" ;;
        tunnel_rebuild) echo "Пересоздание TUNNEL:" ;;
        bind_tunnel_domain) echo "Привязка TUNNEL к домену:" ;;
        bind_success) echo "Домен успешно привязан:" ;;
        install_complete) echo "Установка завершена. Для управления выполните команду 'pooyan'." ;;
        port443_hint) echo "Порт 443 можно заменить на 2053 2083 2087 2096 8443." ;;
        port80_hint) echo "Порт 80 можно заменить на 8080 8880 2052 2082 2086 2095." ;;
        cf_https_note1) echo "Если порты 80/8080/8880/2052/2082/2086/2095 не работают:" ;;
        cf_https_note2) echo "Перейдите на https://dash.cloudflare.com/" ;;
        cf_https_note3) echo "Отключите SSL/TLS > Edge Certificates > Always Use HTTPS." ;;
        github_title) echo "GitHub и установка" ;;
        github_repo) echo "Репозиторий:" ;;
        github_branch) echo "Ветка:" ;;
        github_install) echo "Однострочная установка GitHub:" ;;
        github_note) echo "Эта команда заработает после загрузки этого файла как pooyan.sh в корень репозитория." ;;
        manager_menu) echo "Меню управления" ;;
        already_installed) echo "Сервис уже установлен." ;;
        *) echo "$key" ;;
      esac
      ;;
  esac
}

banner() {
  clear
  echo "========================================"
  printf "%20s\n" "${APP_TITLE}"
  echo "========================================"
  echo
}

save_language() {
  mkdir -p "${APP_DIR}" >/dev/null 2>&1 || true
  cat > "${APP_DIR}/lang.conf" <<EOF
LANG_CODE="${LANG_CODE}"
EOF
}

base64_inline() {
  if [ "$(get_os_name)" = "Alpine" ]; then
    base64 | tr -d '\n'
  else
    base64 -w 0
  fi
}

write_manager_script() {
  mkdir -p "${APP_DIR}"
  cat > "${APP_DIR}/pooyan.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
APP_DIR="/opt/pooyan"
LANG_CODE="en"
[ -f "${APP_DIR}/lang.conf" ] && . "${APP_DIR}/lang.conf"

t() {
  local key="$1"
  case "${LANG_CODE}" in
    fa)
      case "$key" in
        argo) echo "argo" ;;
        xray) echo "xray" ;;
        running) echo "در حال اجرا" ;;
        stopped) echo "متوقف" ;;
        menu_title) echo "منوی مدیریت" ;;
        manage_tunnel) echo "1. مدیریت TUNNEL" ;;
        start_service) echo "2. شروع سرویس" ;;
        stop_service) echo "3. توقف سرویس" ;;
        restart_service) echo "4. ری‌استارت سرویس" ;;
        uninstall_service) echo "5. حذف کامل سرویس" ;;
        view_links) echo "6. نمایش لینک‌های فعلی" ;;
        exit) echo "0. خروج" ;;
        select) echo "منو را انتخاب کنید (پیش‌فرض 0): " ;;
        current_services) echo "سرویس‌های متصل فعلی ARGO TUNNEL:" ;;
        delete_tunnel) echo "1. حذف TUNNEL" ;;
        back) echo "0. بازگشت" ;;
        tunnel_name) echo "نام TUNNEL برای حذف: " ;;
        removed) echo "همه سرویس‌ها حذف شدند." ;;
        token1) echo "برای حذف کامل مجوزها به این آدرس برو:" ;;
        token2) echo "https://dash.cloudflare.com/profile/api-tokens" ;;
        token3) echo "و Argo Tunnel API Token را حذف کن." ;;
        bye) echo "خروج با موفقیت انجام شد." ;;
      esac ;;
    en)
      case "$key" in
        argo) echo "argo" ;;
        xray) echo "xray" ;;
        running) echo "running" ;;
        stopped) echo "stopped" ;;
        menu_title) echo "Management menu" ;;
        manage_tunnel) echo "1. Manage TUNNEL" ;;
        start_service) echo "2. Start service" ;;
        stop_service) echo "3. Stop service" ;;
        restart_service) echo "4. Restart service" ;;
        uninstall_service) echo "5. Uninstall service" ;;
        view_links) echo "6. View current links" ;;
        exit) echo "0. Exit" ;;
        select) echo "Choose menu (default 0): " ;;
        current_services) echo "Currently bound ARGO TUNNEL services:" ;;
        delete_tunnel) echo "1. Delete TUNNEL" ;;
        back) echo "0. Back" ;;
        tunnel_name) echo "Enter TUNNEL name to delete: " ;;
        removed) echo "All services have been removed." ;;
        token1) echo "To completely remove authorization go to:" ;;
        token2) echo "https://dash.cloudflare.com/profile/api-tokens" ;;
        token3) echo "and delete the Argo Tunnel API Token." ;;
        bye) echo "Exited successfully." ;;
      esac ;;
    zh)
      case "$key" in
        argo) echo "argo" ;;
        xray) echo "xray" ;;
        running) echo "运行中" ;;
        stopped) echo "已停止" ;;
        menu_title) echo "管理菜单" ;;
        manage_tunnel) echo "1. 管理 TUNNEL" ;;
        start_service) echo "2. 启动服务" ;;
        stop_service) echo "3. 停止服务" ;;
        restart_service) echo "4. 重启服务" ;;
        uninstall_service) echo "5. 卸载服务" ;;
        view_links) echo "6. 查看当前链接" ;;
        exit) echo "0. 退出" ;;
        select) echo "请选择菜单（默认0）: " ;;
        current_services) echo "当前 ARGO TUNNEL 已绑定服务：" ;;
        delete_tunnel) echo "1. 删除 TUNNEL" ;;
        back) echo "0. 返回" ;;
        tunnel_name) echo "输入要删除的 TUNNEL 名称: " ;;
        removed) echo "所有服务都已卸载完成。" ;;
        token1) echo "如需彻底删除授权，请访问：" ;;
        token2) echo "https://dash.cloudflare.com/profile/api-tokens" ;;
        token3) echo "并删除 Argo Tunnel API Token。" ;;
        bye) echo "已成功退出。" ;;
      esac ;;
    ru)
      case "$key" in
        argo) echo "argo" ;;
        xray) echo "xray" ;;
        running) echo "работает" ;;
        stopped) echo "остановлен" ;;
        menu_title) echo "Меню управления" ;;
        manage_tunnel) echo "1. Управление TUNNEL" ;;
        start_service) echo "2. Запустить сервис" ;;
        stop_service) echo "3. Остановить сервис" ;;
        restart_service) echo "4. Перезапустить сервис" ;;
        uninstall_service) echo "5. Удалить сервис" ;;
        view_links) echo "6. Показать текущие ссылки" ;;
        exit) echo "0. Выход" ;;
        select) echo "Выберите пункт (по умолчанию 0): " ;;
        current_services) echo "Текущие привязанные сервисы ARGO TUNNEL:" ;;
        delete_tunnel) echo "1. Удалить TUNNEL" ;;
        back) echo "0. Назад" ;;
        tunnel_name) echo "Введите имя TUNNEL для удаления: " ;;
        removed) echo "Все сервисы удалены." ;;
        token1) echo "Чтобы полностью удалить авторизацию, перейдите:" ;;
        token2) echo "https://dash.cloudflare.com/profile/api-tokens" ;;
        token3) echo "и удалите Argo Tunnel API Token." ;;
        bye) echo "Выход выполнен успешно." ;;
      esac ;;
  esac
}

system_status_line() {
  local service="$1"
  if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet "${service}"; then
      echo "$(t running)"
    else
      echo "$(t stopped)"
    fi
  else
    echo "$(t stopped)"
  fi
}

while true; do
  clear
  echo "$(t menu_title)"
  echo "$(t argo) $(system_status_line cloudflared.service)"
  echo "$(t xray) $(system_status_line xray.service)"
  echo "$(t manage_tunnel)"
  echo "$(t start_service)"
  echo "$(t stop_service)"
  echo "$(t restart_service)"
  echo "$(t uninstall_service)"
  echo "$(t view_links)"
  echo "$(t exit)"
  echo
  read -rp "$(t select)" menu
  menu="${menu:-0}"

  case "$menu" in
    1)
      clear
      while true; do
        echo "$(t current_services)"
        /opt/pooyan/cloudflared-linux tunnel list || true
        echo "$(t delete_tunnel)"
        echo "$(t back)"
        read -rp "$(t select)" tunneladmin
        tunneladmin="${tunneladmin:-0}"
        if [ "$tunneladmin" = "1" ]; then
          read -rp "$(t tunnel_name)" tunnelname
          /opt/pooyan/cloudflared-linux tunnel cleanup "$tunnelname" || true
          /opt/pooyan/cloudflared-linux tunnel delete "$tunnelname" || true
        else
          break
        fi
      done
      ;;
    2)
      systemctl start cloudflared.service || true
      systemctl start xray.service || true
      ;;
    3)
      systemctl stop cloudflared.service || true
      systemctl stop xray.service || true
      ;;
    4)
      systemctl restart cloudflared.service || true
      systemctl restart xray.service || true
      ;;
    5)
      systemctl stop cloudflared.service || true
      systemctl stop xray.service || true
      systemctl disable cloudflared.service || true
      systemctl disable xray.service || true
      rm -rf /opt/pooyan /lib/systemd/system/cloudflared.service /lib/systemd/system/xray.service /usr/bin/pooyan ~/.cloudflared
      systemctl --system daemon-reload || true
      echo "$(t removed)"
      echo "$(t token1)"
      echo "$(t token2)"
      echo "$(t token3)"
      exit 0
      ;;
    6)
      clear
      cat /opt/pooyan/v2ray.txt
      echo
      read -rp "Enter to continue..." dummy
      ;;
    0)
      echo "$(t bye)"
      exit 0
      ;;
  esac
done
EOF
  chmod +x "${APP_DIR}/pooyan.sh"
  ln -sf "${APP_DIR}/pooyan.sh" "${APP_CMD_PATH}"
}

download_binaries() {
  rm -rf xray cloudflared-linux xray.zip
  case "$(uname -m)" in
    x86_64|x64|amd64)
      curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o xray.zip
      curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared-linux
      ;;
    i386|i686)
      curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-32.zip -o xray.zip
      curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386 -o cloudflared-linux
      ;;
    armv8|arm64|aarch64)
      curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-arm64-v8a.zip -o xray.zip
      curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -o cloudflared-linux
      ;;
    armv7l)
      curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-arm32-v7a.zip -o xray.zip
      curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm -o cloudflared-linux
      ;;
    *)
      echo "$(t unsupported_arch) $(uname -m)"
      exit 1
      ;;
  esac
  mkdir -p xray
  unzip -d xray xray.zip >/dev/null 2>&1
  chmod +x cloudflared-linux xray/xray
  rm -rf xray.zip
}

get_isp_name() {
  local value
  value="$(curl -$ips -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18"-"$30}' | sed -e 's/ /_/g' 2>/dev/null || true)"
  if [ -z "${value:-}" ]; then
    value="Pooyan-Argo"
  fi
  echo "$value"
}

write_v2ray_links_quick() {
  if [ "$protocol" = "1" ]; then
    printf "%s\n\n" "$(t vmess_ready)" > /root/v2ray.txt
    echo 'vmess://'$(printf '{"add":"cloudflare.182682.xyz","aid":"0","host":"%s","id":"%s","net":"ws","path":"%s","port":"443","ps":"%s_tls","tls":"tls","type":"none","v":"2"}' "$argo" "$uuid" "$urlpath" "$(echo "$isp" | sed -e 's/_/ /g')" | base64_inline) >> /root/v2ray.txt
    printf "\n%s\n\n" "$(t port443_hint)" >> /root/v2ray.txt
    echo 'vmess://'$(printf '{"add":"cloudflare.182682.xyz","aid":"0","host":"%s","id":"%s","net":"ws","path":"%s","port":"80","ps":"%s","tls":"","type":"none","v":"2"}' "$argo" "$uuid" "$urlpath" "$(echo "$isp" | sed -e 's/_/ /g')" | base64_inline) >> /root/v2ray.txt
    printf "\n%s\n" "$(t port80_hint)" >> /root/v2ray.txt
  else
    printf "%s\n\n" "$(t vless_ready)" > /root/v2ray.txt
    echo "vless://${uuid}@cloudflare.182682.xyz:443?encryption=none&security=tls&type=ws&host=${argo}&path=${urlpath}#$(echo "$isp" | sed -e 's/_/%20/g' -e 's/,/%2C/g')_tls" >> /root/v2ray.txt
    printf "\n%s\n\n" "$(t port443_hint)" >> /root/v2ray.txt
    echo "vless://${uuid}@cloudflare.182682.xyz:80?encryption=none&security=none&type=ws&host=${argo}&path=${urlpath}#$(echo "$isp" | sed -e 's/_/%20/g' -e 's/,/%2C/g')" >> /root/v2ray.txt
    printf "\n%s\n" "$(t port80_hint)" >> /root/v2ray.txt
  fi
}

write_v2ray_links_install() {
  if [ "$protocol" = "1" ]; then
    printf "%s\n\n" "$(t vmess_ready)" > "${APP_DIR}/v2ray.txt"
    echo 'vmess://'$(printf '{"add":"cloudflare.182682.xyz","aid":"0","host":"%s","id":"%s","net":"ws","path":"%s","port":"443","ps":"%s_tls","tls":"tls","type":"none","v":"2"}' "$domain" "$uuid" "$urlpath" "$(echo "$isp" | sed -e 's/_/ /g')" | base64_inline) >> "${APP_DIR}/v2ray.txt"
    printf "\n%s\n\n" "$(t port443_hint)" >> "${APP_DIR}/v2ray.txt"
    echo 'vmess://'$(printf '{"add":"cloudflare.182682.xyz","aid":"0","host":"%s","id":"%s","net":"ws","path":"%s","port":"80","ps":"%s","tls":"","type":"none","v":"2"}' "$domain" "$uuid" "$urlpath" "$(echo "$isp" | sed -e 's/_/ /g')" | base64_inline) >> "${APP_DIR}/v2ray.txt"
    printf "\n%s\n%s\n%s\n%s\n" "$(t port80_hint)" "$(t cf_https_note1)" "$(t cf_https_note2)" "$(t cf_https_note3)" >> "${APP_DIR}/v2ray.txt"
  else
    printf "%s\n\n" "$(t vless_ready)" > "${APP_DIR}/v2ray.txt"
    echo "vless://${uuid}@cloudflare.182682.xyz:443?encryption=none&security=tls&type=ws&host=${domain}&path=${urlpath}#$(echo "$isp" | sed -e 's/_/%20/g' -e 's/,/%2C/g')_tls" >> "${APP_DIR}/v2ray.txt"
    printf "\n%s\n\n" "$(t port443_hint)" >> "${APP_DIR}/v2ray.txt"
    echo "vless://${uuid}@cloudflare.182682.xyz:80?encryption=none&security=none&type=ws&host=${domain}&path=${urlpath}#$(echo "$isp" | sed -e 's/_/%20/g' -e 's/,/%2C/g')" >> "${APP_DIR}/v2ray.txt"
    printf "\n%s\n%s\n%s\n%s\n" "$(t port80_hint)" "$(t cf_https_note1)" "$(t cf_https_note2)" "$(t cf_https_note3)" >> "${APP_DIR}/v2ray.txt"
  fi
}

quicktunnel() {
  download_binaries
  uuid="$(cat /proc/sys/kernel/random/uuid)"
  urlpath="$(echo "$uuid" | awk -F- '{print $1}')"
  port=$((RANDOM+10000))

  if [ "$protocol" = "1" ]; then
    cat > xray/config.json <<EOF
{
  "inbounds": [
    {
      "port": $port,
      "listen": "localhost",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$uuid",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "$urlpath"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
  else
    cat > xray/config.json <<EOF
{
  "inbounds": [
    {
      "port": $port,
      "listen": "localhost",
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "$uuid"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "$urlpath"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
  fi

  ./xray/xray run -config xray/config.json >/dev/null 2>&1 &
  ./cloudflared-linux tunnel --url "http://localhost:${port}" --no-autoupdate --edge-ip-version "$ips" --protocol http2 > argo.log 2>&1 &
  sleep 1

  n=0
  while true; do
    n=$((n+1))
    clear
    echo "$(t wait_argo) $n $(t wait_seconds)"
    argo="$(grep 'trycloudflare.com' argo.log | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}' || true)"
    if [ "$n" = "15" ]; then
      n=0
      kill_matching "cloudflared-linux"
      rm -rf argo.log
      clear
      echo "$(t argo_timeout_retry)"
      ./cloudflared-linux tunnel --url "http://localhost:${port}" --no-autoupdate --edge-ip-version "$ips" --protocol http2 > argo.log 2>&1 &
      sleep 1
    elif [ -z "${argo:-}" ]; then
      sleep 1
    else
      rm -rf argo.log
      break
    fi
  done

  clear
  write_v2ray_links_quick
  cat /root/v2ray.txt
  echo
  echo "$(t saved_path)"
  echo "$(t quick_invalid_after_reboot)"
}

installtunnel() {
  mkdir -p "${APP_DIR}" >/dev/null 2>&1
  download_binaries
  mv cloudflared-linux "${APP_DIR}/"
  mv xray/xray "${APP_DIR}/"
  rm -rf xray

  uuid="$(cat /proc/sys/kernel/random/uuid)"
  urlpath="$(echo "$uuid" | awk -F- '{print $1}')"
  port=$((RANDOM+10000))

  if [ "$protocol" = "1" ]; then
    cat > "${APP_DIR}/config.json" <<EOF
{
  "inbounds": [
    {
      "port": $port,
      "listen": "localhost",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$uuid",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "$urlpath"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
  else
    cat > "${APP_DIR}/config.json" <<EOF
{
  "inbounds": [
    {
      "port": $port,
      "listen": "localhost",
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "$uuid"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "$urlpath"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
  fi

  clear
  echo "$(t copy_open_auth)"
  echo "$(t auth_continue)"
  "${APP_DIR}/cloudflared-linux" --edge-ip-version "$ips" --protocol http2 tunnel login
  clear
  "${APP_DIR}/cloudflared-linux" --edge-ip-version "$ips" --protocol http2 tunnel list > argo.log 2>&1
  echo
  echo "$(t current_bound_services)"
  sed 1,2d argo.log | awk '{print $2}'
  echo
  echo "$(t custom_subdomain)"
  echo "$(t domain_must_authorized)"
  read -rp "$(t input_full_domain)" domain

  if [ -z "${domain:-}" ]; then
    echo "$(t no_domain)"
    exit 1
  elif [ "$(echo "$domain" | grep '\.' | wc -l)" = "0" ]; then
    echo "$(t bad_domain)"
    exit 1
  fi

  name="$(echo "$domain" | awk -F. '{print $1}')"
  if [ "$(sed 1,2d argo.log | awk '{print $2}' | grep -w "$name" | wc -l)" = "0" ]; then
    echo "$(t tunnel_create) $name"
    "${APP_DIR}/cloudflared-linux" --edge-ip-version "$ips" --protocol http2 tunnel create "$name" > argo.log 2>&1
    echo "$(t tunnel_created) $name"
  else
    echo "$(t tunnel_exists) $name"
    existing_uuid="$(sed 1,2d argo.log | awk '{print $1" "$2}' | grep -w "$name" | awk '{print $1}' || true)"
    if [ ! -f "/root/.cloudflared/${existing_uuid}.json" ]; then
      echo "$(t tunnel_cleanup) $name"
      "${APP_DIR}/cloudflared-linux" --edge-ip-version "$ips" --protocol http2 tunnel cleanup "$name" > argo.log 2>&1 || true
      echo "$(t tunnel_delete) $name"
      "${APP_DIR}/cloudflared-linux" --edge-ip-version "$ips" --protocol http2 tunnel delete "$name" > argo.log 2>&1 || true
      echo "$(t tunnel_rebuild) $name"
      "${APP_DIR}/cloudflared-linux" --edge-ip-version "$ips" --protocol http2 tunnel create "$name" > argo.log 2>&1
    else
      echo "$(t tunnel_cleanup) $name"
      "${APP_DIR}/cloudflared-linux" --edge-ip-version "$ips" --protocol http2 tunnel cleanup "$name" > argo.log 2>&1 || true
    fi
  fi

  echo "$(t bind_tunnel_domain) $domain"
  "${APP_DIR}/cloudflared-linux" --edge-ip-version "$ips" --protocol http2 tunnel route dns --overwrite-dns "$name" "$domain" > argo.log 2>&1
  echo "$(t bind_success) $domain"

  tunneluuid="$(cut -d= -f2 argo.log | tr -d '[:space:]')"
  write_v2ray_links_install

  cat > "${APP_DIR}/config.yaml" <<EOF
tunnel: $tunneluuid
credentials-file: /root/.cloudflared/$tunneluuid.json

ingress:
  - hostname: $domain
    service: http://localhost:$port
  - service: http_status:404
EOF

  if [ "$(get_os_name)" = "Alpine" ]; then
    cat > /etc/local.d/cloudflared.start <<EOF
${APP_DIR}/cloudflared-linux --edge-ip-version $ips --protocol http2 tunnel --config ${APP_DIR}/config.yaml run $name &
EOF
    cat > /etc/local.d/xray.start <<EOF
${APP_DIR}/xray run -config ${APP_DIR}/config.json &
EOF
    chmod +x /etc/local.d/cloudflared.start /etc/local.d/xray.start
    rc-update add local >/dev/null 2>&1 || true
    /etc/local.d/cloudflared.start >/dev/null 2>&1
    /etc/local.d/xray.start >/dev/null 2>&1
  else
    cat > /lib/systemd/system/cloudflared.service <<EOF
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
TimeoutStartSec=0
Type=simple
ExecStart=${APP_DIR}/cloudflared-linux --edge-ip-version $ips --protocol http2 tunnel --config ${APP_DIR}/config.yaml run $name
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    cat > /lib/systemd/system/xray.service <<EOF
[Unit]
Description=Xray
After=network.target

[Service]
TimeoutStartSec=0
Type=simple
ExecStart=${APP_DIR}/xray run -config ${APP_DIR}/config.json
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable cloudflared.service >/dev/null 2>&1 || true
    systemctl enable xray.service >/dev/null 2>&1 || true
    systemctl --system daemon-reload || true
    systemctl start cloudflared.service || true
    systemctl start xray.service || true
  fi

  save_language
  write_manager_script
  cat "${APP_DIR}/v2ray.txt"
  echo
  echo "$(t install_complete)"
}

show_github_info() {
  clear
  banner
  if [ "$LANG_CODE" = "fa" ]; then
    echo "GitHub"
    echo "${GITHUB_URL}"
    echo
    echo "Repo"
    echo "${GITHUB_USER}/${GITHUB_REPO}"
    echo
    echo "Branch"
    echo "${GITHUB_BRANCH}"
    echo
    echo "Install"
    echo "bash <(curl -fsSL ${RAW_URL})"
    echo
    echo "$(t github_note)"
    echo
  else
    echo "$(t github_title)"
    echo
    echo "GitHub: ${GITHUB_URL}"
    echo "$(t github_repo) ${GITHUB_USER}/${GITHUB_REPO}"
    echo "$(t github_branch) ${GITHUB_BRANCH}"
    echo
    echo "$(t github_install)"
    echo "bash <(curl -fsSL ${RAW_URL})"
    echo
    echo "$(t github_note)"
    echo
  fi
}


main_menu_ui() {
  banner
  if [ "$LANG_CODE" = "fa" ]; then
    echo "$(t app_welcome)"
    echo
    echo "- $(t quick_desc_1)"
    echo "- $(t quick_desc_2)"
    echo "- $(t install_desc_1)"
    echo "- $(t install_desc_2)"
    echo
    echo "Pooyan Light"
    echo "yoursite.com"
    echo "Pooyan NAT"
    echo "panel.yoursite.com"
    echo
    echo "$(t reboot_note)"
    echo
    echo "$(t menu_1)"
    echo "$(t menu_2)"
    echo "$(t menu_3)"
    echo "$(t menu_4)"
    echo "$(t menu_5)"
    echo "$(t menu_6)"
    echo "$(t menu_0)"
    echo
  else
    echo "$(t app_welcome)"
    echo
    echo "$(t quick_desc_1)"
    echo "$(t quick_desc_2)"
    echo "$(t install_desc_1)"
    echo "$(t install_desc_2)"
    echo
    echo "$(t site_light) yoursite.com"
    echo "$(t site_nat) panel.yoursite.com"
    echo
    echo "$(t reboot_note)"
    echo
    echo "$(t slogan)"
    echo
    echo "$(t menu_1)"
    echo "$(t menu_2)"
    echo "$(t menu_3)"
    echo "$(t menu_4)"
    echo "$(t menu_5)"
    echo "$(t menu_6)"
    echo "$(t menu_0)"
    echo
  fi
}


main() {
  ensure_dependencies
  choose_language
  main_menu_ui

  read -rp "$(t choose_mode)" mode
  mode="${mode:-1}"

  if [ "$mode" = "2" ] && [ -f "${APP_CMD_PATH}" ]; then
    echo "$(t service_installed_jump)"
    "${APP_CMD_NAME}"
    exit 0
  fi

  if [ "$mode" = "1" ] || [ "$mode" = "2" ]; then
    read -rp "$(t choose_protocol)" protocol
    protocol="${protocol:-1}"
    if [ "$protocol" != "1" ] && [ "$protocol" != "2" ]; then
      echo "$(t invalid_protocol)"
      exit 1
    fi

    read -rp "$(t choose_ip_mode)" ips
    ips="${ips:-4}"
    if [ "$ips" != "4" ] && [ "$ips" != "6" ]; then
      echo "$(t invalid_ip_mode)"
      exit 1
    fi

    isp="$(get_isp_name)"
  fi

  case "$mode" in
    1)
      kill_matching "xray"
      kill_matching "cloudflared-linux"
      rm -rf xray cloudflared-linux /root/v2ray.txt
      quicktunnel
      ;;
    2)
      if [ "$(get_os_name)" = "Alpine" ]; then
        kill_matching "xray"
        kill_matching "cloudflared-linux"
        rm -rf "${APP_DIR}" /lib/systemd/system/cloudflared.service /lib/systemd/system/xray.service "${APP_CMD_PATH}"
      else
        systemctl stop cloudflared.service >/dev/null 2>&1 || true
        systemctl stop xray.service >/dev/null 2>&1 || true
        systemctl disable cloudflared.service >/dev/null 2>&1 || true
        systemctl disable xray.service >/dev/null 2>&1 || true
        kill_matching "xray"
        kill_matching "cloudflared-linux"
        rm -rf "${APP_DIR}" /lib/systemd/system/cloudflared.service /lib/systemd/system/xray.service "${APP_CMD_PATH}"
        systemctl --system daemon-reload >/dev/null 2>&1 || true
      fi
      installtunnel
      ;;
    3)
      if [ "$(get_os_name)" = "Alpine" ]; then
        kill_matching "xray"
        kill_matching "cloudflared-linux"
        rm -rf "${APP_DIR}" /lib/systemd/system/cloudflared.service /lib/systemd/system/xray.service "${APP_CMD_PATH}" ~/.cloudflared
      else
        systemctl stop cloudflared.service >/dev/null 2>&1 || true
        systemctl stop xray.service >/dev/null 2>&1 || true
        systemctl disable cloudflared.service >/dev/null 2>&1 || true
        systemctl disable xray.service >/dev/null 2>&1 || true
        kill_matching "xray"
        kill_matching "cloudflared-linux"
        rm -rf "${APP_DIR}" /lib/systemd/system/cloudflared.service /lib/systemd/system/xray.service "${APP_CMD_PATH}" ~/.cloudflared
        systemctl --system daemon-reload >/dev/null 2>&1 || true
      fi
      clear
      echo "$(t uninstall_done)"
      echo "$(t delete_auth_note_1)"
      echo "$(t delete_auth_note_2) https://dash.cloudflare.com/profile/api-tokens"
      echo "$(t delete_auth_note_3)"
      ;;
    4)
      kill_matching "xray"
      kill_matching "cloudflared-linux"
      rm -rf xray cloudflared-linux /root/v2ray.txt
      ;;
    5)
      if [ -f "${APP_CMD_PATH}" ]; then
        "${APP_CMD_NAME}"
      else
        echo "$(t manage_not_installed)"
      fi
      ;;
    6)
      show_github_info
      ;;
    *)
      echo "$(t exit_ok)"
      ;;
  esac
}

main "$@"
