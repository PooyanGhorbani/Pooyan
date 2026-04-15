#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="Pooyan"
PROJECT_VERSION="0.07"
APP_TITLE="${PROJECT_NAME} ${PROJECT_VERSION}"
APP_DIR="/opt/pooyan"
BIN_DIR="$APP_DIR/bin"
DATA_DIR="$APP_DIR/data"
Xray_BIN="$BIN_DIR/xray"
CF_BIN="$BIN_DIR/cloudflared"
MANAGER_PY="$APP_DIR/manager.py"
WRAPPER_SH="$APP_DIR/pooyan-menu.sh"
GITHUB_USER="PooyanGhorbani"
GITHUB_REPO="Pooyan"
GITHUB_BRANCH="main"
RAW_INSTALL_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/pooyan.sh"
LANG_CODE="fa"

linux_os=("Debian" "Ubuntu" "CentOS" "Fedora" "Alpine")
linux_update=("apt update" "apt update" "yum -y update" "yum -y update" "apk update")
linux_install=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "apk add -f")

ensure_root() {
  if [ "${EUID}" -ne 0 ]; then
    echo "Please run as root"
    exit 1
  fi
}

get_os_name() {
  grep -i PRETTY_NAME /etc/os-release | cut -d '"' -f2 | awk '{print $1}'
}

get_os_index() {
  local current_os idx=0
  current_os="$(get_os_name)"
  for i in "${linux_os[@]}"; do
    if [ "$i" = "$current_os" ]; then
      echo "$idx"
      return
    fi
    idx=$((idx+1))
  done
  echo 0
}

ensure_deps() {
  local n
  n="$(get_os_index)"
  local pkgs=(curl unzip python3 sqlite3 ca-certificates)
  if [ "$(get_os_name)" != "Alpine" ]; then
    pkgs+=(systemd)
  fi
  if command -v apt >/dev/null 2>&1; then
    apt update
    DEBIAN_FRONTEND=noninteractive apt -y install curl unzip python3 sqlite3 ca-certificates systemd >/dev/null
  elif command -v yum >/dev/null 2>&1; then
    yum -y install curl unzip python3 sqlite ca-certificates systemd >/dev/null || yum -y install curl unzip python3 sqlite3 ca-certificates systemd >/dev/null
  elif command -v dnf >/dev/null 2>&1; then
    dnf -y install curl unzip python3 sqlite ca-certificates systemd >/dev/null || dnf -y install curl unzip python3 sqlite3 ca-certificates systemd >/dev/null
  elif command -v apk >/dev/null 2>&1; then
    apk update >/dev/null
    apk add -f curl unzip python3 sqlite ca-certificates >/dev/null
  else
    echo "Unsupported package manager"
    exit 1
  fi
}

require_systemd() {
  if ! command -v systemctl >/dev/null 2>&1; then
    echo "This multi-user edition currently supports systemd-based servers for service mode."
    exit 1
  fi
}

choose_language() {
  clear
  echo "========================================"
  printf "%20s\n" "$APP_TITLE"
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
        main_note) echo "نسخه چندکاربره: لینک جدا، محدودیت زمان، محدودیت حجم، و نمایش مصرف" ;;
        menu_install) echo "1. نصب یا به‌روزرسانی سرویس چندکاربره" ;;
        menu_manage) echo "2. مدیریت کاربران" ;;
        menu_sync) echo "3. همگام‌سازی مصرف و اعمال محدودیت" ;;
        menu_status) echo "4. وضعیت سرویس" ;;
        menu_github) echo "5. نصب سریع GitHub" ;;
        menu_uninstall) echo "6. حذف سرویس" ;;
        menu_exit) echo "0. خروج" ;;
        prompt_mode) echo "گزینه را انتخاب کنید [1]: " ;;
        need_install) echo "ابتدا سرویس را نصب کنید." ;;
        install_done) echo "نصب کامل شد." ;;
        enter_domain) echo "دامنه کامل را وارد کنید (مثال: tunnel.example.com): " ;;
        enter_ipmode) echo "حالت IP برای Cloudflared [4/6] (پیش‌فرض 4): " ;;
        enter_tunnel_name) echo "نام tunnel (پیش‌فرض از روی زیردامنه): " ;;
        add_first_user) echo "نام اولین کاربر: " ;;
        days_first_user) echo "تعداد روز اعتبار (خالی = بدون انقضا): " ;;
        quota_first_user) echo "سقف حجم به گیگابایت (خالی = نامحدود): " ;;
        github_line1) echo "بعد از آپلود همین فایل با نام pooyan.sh در ریشه ریپو:" ;;
        github_line2) echo "دستور نصب سریع:" ;;
        sync_done) echo "همگام‌سازی انجام شد." ;;
        uninstall_done) echo "حذف انجام شد." ;;
        user_menu) echo "منوی کاربران" ;;
        um_list) echo "1. لیست کاربران" ;;
        um_add) echo "2. ساخت کاربر" ;;
        um_link) echo "3. نمایش لینک کاربر" ;;
        um_usage) echo "4. نمایش مصرف" ;;
        um_quota) echo "5. تنظیم سقف حجم" ;;
        um_expiry) echo "6. تنظیم انقضا" ;;
        um_enable) echo "7. فعال‌سازی" ;;
        um_disable) echo "8. غیرفعال‌سازی" ;;
        um_delete) echo "9. حذف کاربر" ;;
        um_restart) echo "10. راه‌اندازی دوباره سرویس‌ها" ;;
        um_back) echo "0. بازگشت" ;;
        prompt_user_menu) echo "گزینه [0]: " ;;
        enter_username) echo "نام کاربر: " ;;
        enter_quota) echo "حجم برحسب GB یا none: " ;;
        enter_days) echo "روز از الان یا none: " ;;
        enter_note) echo "توضیح کوتاه (اختیاری): " ;;
        service_status) echo "وضعیت سرویس‌ها" ;;
        not_supported_quick) echo "نسخه 0.07 روی نصب دائمی چندکاربره تمرکز دارد؛ مدیریت کاربر روی Quick Tunnel فعال نیست." ;;
        *) echo "$key" ;;
      esac
      ;;
    en)
      case "$key" in
        welcome) echo "Welcome to ${APP_TITLE}" ;;
        main_note) echo "Multi-user edition: per-user links, expiry, quota, and usage tracking" ;;
        menu_install) echo "1. Install or update multi-user service" ;;
        menu_manage) echo "2. Manage users" ;;
        menu_sync) echo "3. Sync usage and enforce limits" ;;
        menu_status) echo "4. Service status" ;;
        menu_github) echo "5. GitHub quick install" ;;
        menu_uninstall) echo "6. Uninstall service" ;;
        menu_exit) echo "0. Exit" ;;
        prompt_mode) echo "Choose an option [1]: " ;;
        need_install) echo "Install the service first." ;;
        install_done) echo "Installation completed." ;;
        enter_domain) echo "Enter full domain (example: tunnel.example.com): " ;;
        enter_ipmode) echo "Cloudflared IP mode [4/6] (default 4): " ;;
        enter_tunnel_name) echo "Tunnel name (default: first label of subdomain): " ;;
        add_first_user) echo "First username: " ;;
        days_first_user) echo "Expiry days (blank = none): " ;;
        quota_first_user) echo "Quota in GB (blank = unlimited): " ;;
        github_line1) echo "After uploading this file as pooyan.sh to the repo root:" ;;
        github_line2) echo "Quick install command:" ;;
        sync_done) echo "Usage sync completed." ;;
        uninstall_done) echo "Uninstall completed." ;;
        user_menu) echo "User menu" ;;
        um_list) echo "1. List users" ;;
        um_add) echo "2. Add user" ;;
        um_link) echo "3. Show user link" ;;
        um_usage) echo "4. Show usage" ;;
        um_quota) echo "5. Set quota" ;;
        um_expiry) echo "6. Set expiry" ;;
        um_enable) echo "7. Enable user" ;;
        um_disable) echo "8. Disable user" ;;
        um_delete) echo "9. Delete user" ;;
        um_restart) echo "10. Restart services" ;;
        um_back) echo "0. Back" ;;
        prompt_user_menu) echo "Option [0]: " ;;
        enter_username) echo "Username: " ;;
        enter_quota) echo "Quota in GB or none: " ;;
        enter_days) echo "Days from now or none: " ;;
        enter_note) echo "Short note (optional): " ;;
        service_status) echo "Service status" ;;
        not_supported_quick) echo "Version 0.07 focuses on persistent multi-user mode; user management is not enabled for Quick Tunnel." ;;
        *) echo "$key" ;;
      esac
      ;;
    zh)
      case "$key" in
        welcome) echo "欢迎使用 ${APP_TITLE}" ;;
        main_note) echo "多用户版本：每用户独立链接、到期时间、流量配额、使用统计" ;;
        menu_install) echo "1. 安装或更新多用户服务" ;;
        menu_manage) echo "2. 管理用户" ;;
        menu_sync) echo "3. 同步流量并执行限制" ;;
        menu_status) echo "4. 服务状态" ;;
        menu_github) echo "5. GitHub 快速安装" ;;
        menu_uninstall) echo "6. 卸载服务" ;;
        menu_exit) echo "0. 退出" ;;
        prompt_mode) echo "请选择 [1]: " ;;
        need_install) echo "请先安装服务。" ;;
        install_done) echo "安装完成。" ;;
        enter_domain) echo "输入完整域名（例如：tunnel.example.com）：" ;;
        enter_ipmode) echo "Cloudflared IP 模式 [4/6]（默认 4）：" ;;
        enter_tunnel_name) echo "Tunnel 名称（默认使用子域名前缀）：" ;;
        add_first_user) echo "第一个用户名：" ;;
        days_first_user) echo "到期天数（留空=不限）：" ;;
        quota_first_user) echo "流量上限 GB（留空=不限）：" ;;
        github_line1) echo "把本文件作为 pooyan.sh 上传到仓库根目录后：" ;;
        github_line2) echo "快速安装命令：" ;;
        sync_done) echo "流量同步完成。" ;;
        uninstall_done) echo "卸载完成。" ;;
        user_menu) echo "用户菜单" ;;
        um_list) echo "1. 用户列表" ;;
        um_add) echo "2. 添加用户" ;;
        um_link) echo "3. 查看用户链接" ;;
        um_usage) echo "4. 查看流量" ;;
        um_quota) echo "5. 设置配额" ;;
        um_expiry) echo "6. 设置到期" ;;
        um_enable) echo "7. 启用用户" ;;
        um_disable) echo "8. 禁用用户" ;;
        um_delete) echo "9. 删除用户" ;;
        um_restart) echo "10. 重启服务" ;;
        um_back) echo "0. 返回" ;;
        prompt_user_menu) echo "选项 [0]: " ;;
        enter_username) echo "用户名：" ;;
        enter_quota) echo "GB 配额或 none：" ;;
        enter_days) echo "从现在开始的天数或 none：" ;;
        enter_note) echo "备注（可选）：" ;;
        service_status) echo "服务状态" ;;
        not_supported_quick) echo "0.07 版本重点是持久化多用户模式；Quick Tunnel 不提供用户管理。" ;;
        *) echo "$key" ;;
      esac
      ;;
    ru)
      case "$key" in
        welcome) echo "Добро пожаловать в ${APP_TITLE}" ;;
        main_note) echo "Многопользовательская версия: отдельные ссылки, срок, квота и статистика" ;;
        menu_install) echo "1. Установить или обновить многопользовательский сервис" ;;
        menu_manage) echo "2. Управление пользователями" ;;
        menu_sync) echo "3. Синхронизировать трафик и применить лимиты" ;;
        menu_status) echo "4. Статус сервисов" ;;
        menu_github) echo "5. Быстрая установка через GitHub" ;;
        menu_uninstall) echo "6. Удалить сервис" ;;
        menu_exit) echo "0. Выход" ;;
        prompt_mode) echo "Выберите пункт [1]: " ;;
        need_install) echo "Сначала установите сервис." ;;
        install_done) echo "Установка завершена." ;;
        enter_domain) echo "Введите полный домен (например: tunnel.example.com): " ;;
        enter_ipmode) echo "Режим IP для Cloudflared [4/6] (по умолчанию 4): " ;;
        enter_tunnel_name) echo "Имя tunnel (по умолчанию: первый ярлык поддомена): " ;;
        add_first_user) echo "Имя первого пользователя: " ;;
        days_first_user) echo "Срок в днях (пусто = без срока): " ;;
        quota_first_user) echo "Квота в GB (пусто = без лимита): " ;;
        github_line1) echo "После загрузки этого файла как pooyan.sh в корень репозитория:" ;;
        github_line2) echo "Команда быстрой установки:" ;;
        sync_done) echo "Синхронизация трафика завершена." ;;
        uninstall_done) echo "Удаление завершено." ;;
        user_menu) echo "Меню пользователей" ;;
        um_list) echo "1. Список пользователей" ;;
        um_add) echo "2. Добавить пользователя" ;;
        um_link) echo "3. Показать ссылку пользователя" ;;
        um_usage) echo "4. Показать трафик" ;;
        um_quota) echo "5. Установить квоту" ;;
        um_expiry) echo "6. Установить срок" ;;
        um_enable) echo "7. Включить пользователя" ;;
        um_disable) echo "8. Выключить пользователя" ;;
        um_delete) echo "9. Удалить пользователя" ;;
        um_restart) echo "10. Перезапустить сервисы" ;;
        um_back) echo "0. Назад" ;;
        prompt_user_menu) echo "Пункт [0]: " ;;
        enter_username) echo "Имя пользователя: " ;;
        enter_quota) echo "Квота в GB или none: " ;;
        enter_days) echo "Дней от текущего момента или none: " ;;
        enter_note) echo "Краткая заметка (необязательно): " ;;
        service_status) echo "Статус сервисов" ;;
        not_supported_quick) echo "Версия 0.07 ориентирована на постоянный многопользовательский режим; управление пользователями в Quick Tunnel не включено." ;;
        *) echo "$key" ;;
      esac
      ;;
  esac
}

banner() {
  clear
  echo "========================================"
  printf "%20s\n" "$APP_TITLE"
  echo "========================================"
  echo
}

need_installed() {
  if [ ! -f "$MANAGER_PY" ]; then
    echo "$(t need_install)"
    return 1
  fi
  return 0
}

arch_downloads() {
  case "$(uname -m)" in
    x86_64|x64|amd64)
      XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip"
      CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
      ;;
    i386|i686)
      XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-32.zip"
      CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386"
      ;;
    armv8|arm64|aarch64)
      XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-arm64-v8a.zip"
      CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
      ;;
    armv7l)
      XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-arm32-v7a.zip"
      CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm"
      ;;
    *)
      echo "Unsupported architecture: $(uname -m)"
      exit 1
      ;;
  esac
}

download_binaries() {
  arch_downloads
  mkdir -p "$BIN_DIR" "$DATA_DIR" "$APP_DIR"
  rm -rf /tmp/pooyan-xray /tmp/pooyan-xray.zip
  curl -fsSL "$XRAY_URL" -o /tmp/pooyan-xray.zip
  unzip -oq /tmp/pooyan-xray.zip -d /tmp/pooyan-xray
  install -m 0755 /tmp/pooyan-xray/xray "$Xray_BIN"
  curl -fsSL "$CF_URL" -o "$CF_BIN"
  chmod +x "$CF_BIN"
}

write_manager_py() {
  cat > "$MANAGER_PY" <<'PYEOF'
#!/usr/bin/env python3
import argparse, json, os, sqlite3, subprocess, sys, time, uuid
from pathlib import Path
from urllib.parse import quote

APP_DIR = Path("/opt/pooyan")
DATA_DIR = APP_DIR / "data"
DB_PATH = DATA_DIR / "users.db"
CONFIG_PATH = APP_DIR / "config.json"
XRAY_BIN = APP_DIR / "bin" / "xray"


def conn():
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(DB_PATH)
    db.row_factory = sqlite3.Row
    return db


def init_db():
    db = conn()
    db.executescript(
        """
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT
        );
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            uuid TEXT UNIQUE NOT NULL,
            status TEXT NOT NULL DEFAULT 'active',
            created_at INTEGER NOT NULL,
            expire_at INTEGER,
            quota_bytes INTEGER,
            used_bytes INTEGER NOT NULL DEFAULT 0,
            last_live_bytes INTEGER NOT NULL DEFAULT 0,
            note TEXT
        );
        """
    )
    db.commit()
    db.close()


def get_setting(key, default=None):
    db = conn()
    row = db.execute("SELECT value FROM settings WHERE key=?", (key,)).fetchone()
    db.close()
    return row[0] if row else default


def set_setting(key, value):
    db = conn()
    db.execute("INSERT INTO settings(key, value) VALUES(?, ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value", (key, str(value)))
    db.commit()
    db.close()


def bytes_fmt(v):
    if v is None:
        return "-"
    v = int(v)
    units = ["B", "KB", "MB", "GB", "TB"]
    size = float(v)
    for u in units:
        if size < 1024 or u == units[-1]:
            return f"{size:.2f} {u}"
        size /= 1024


def parse_days(s):
    if s in (None, "", "none", "None"):
        return None
    return int(s)


def parse_quota_gb(s):
    if s in (None, "", "none", "None"):
        return None
    return int(float(s) * (1024 ** 3))


def user_exists(username):
    db = conn()
    row = db.execute("SELECT 1 FROM users WHERE username=?", (username,)).fetchone()
    db.close()
    return row is not None


def active_user_rows():
    now = int(time.time())
    db = conn()
    rows = db.execute(
        "SELECT * FROM users WHERE status='active' AND (expire_at IS NULL OR expire_at > ?) AND (quota_bytes IS NULL OR used_bytes < quota_bytes) ORDER BY username",
        (now,),
    ).fetchall()
    db.close()
    return rows


def all_rows():
    db = conn()
    rows = db.execute("SELECT * FROM users ORDER BY username").fetchall()
    db.close()
    return rows


def render_config():
    port = int(get_setting("local_port", "18080"))
    path_prefix = get_setting("path_prefix", uuid.uuid4().hex[:8])
    clients = []
    for r in active_user_rows():
        clients.append({
            "id": r["uuid"],
            "email": r["username"],
            "level": 0,
        })
    cfg = {
        "log": {"loglevel": "warning"},
        "api": {
            "tag": "api",
            "services": ["HandlerService", "StatsService", "LoggerService"],
        },
        "stats": {},
        "policy": {
            "levels": {
                "0": {
                    "handshake": 4,
                    "connIdle": 300,
                    "uplinkOnly": 2,
                    "downlinkOnly": 5,
                    "statsUserUplink": True,
                    "statsUserDownlink": True,
                }
            },
            "system": {
                "statsInboundUplink": True,
                "statsInboundDownlink": True,
                "statsOutboundUplink": True,
                "statsOutboundDownlink": True,
            },
        },
        "inbounds": [
            {
                "tag": "api-in",
                "listen": "127.0.0.1",
                "port": 10085,
                "protocol": "dokodemo-door",
                "settings": {"address": "127.0.0.1"},
            },
            {
                "tag": "ws-in",
                "listen": "127.0.0.1",
                "port": port,
                "protocol": "vless",
                "settings": {
                    "decryption": "none",
                    "clients": clients,
                },
                "streamSettings": {
                    "network": "ws",
                    "wsSettings": {"path": f"/{path_prefix}/ws"},
                },
                "sniffing": {
                    "enabled": True,
                    "destOverride": ["http", "tls", "quic"],
                },
            },
        ],
        "outbounds": [
            {"tag": "direct", "protocol": "freedom", "settings": {}},
            {"tag": "block", "protocol": "blackhole", "settings": {}},
        ],
        "routing": {
            "domainStrategy": "AsIs",
            "rules": [
                {"type": "field", "inboundTag": ["api-in"], "outboundTag": "api"}
            ],
        },
    }
    CONFIG_PATH.write_text(json.dumps(cfg, ensure_ascii=False, indent=2), encoding="utf-8")


def restart_services(*names):
    if not shutil_which("systemctl"):
        return
    for n in names:
        subprocess.run(["systemctl", "restart", n], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def shutil_which(name):
    for p in os.environ.get("PATH", "").split(os.pathsep):
        candidate = Path(p) / name
        if candidate.exists() and os.access(candidate, os.X_OK):
            return str(candidate)
    return None


def add_user(username, days=None, quota_gb=None, note=None):
    init_db()
    if user_exists(username):
        raise SystemExit(f"User already exists: {username}")
    now = int(time.time())
    expire_at = now + int(days) * 86400 if days not in (None, "", "none", "None") else None
    quota_bytes = parse_quota_gb(quota_gb)
    db = conn()
    db.execute(
        "INSERT INTO users(username, uuid, status, created_at, expire_at, quota_bytes, used_bytes, last_live_bytes, note) VALUES(?, ?, 'active', ?, ?, ?, 0, 0, ?)",
        (username, str(uuid.uuid4()), now, expire_at, quota_bytes, note),
    )
    db.commit()
    db.close()
    render_config()
    restart_services("xray.service")


def set_quota(username, quota_gb):
    quota_bytes = parse_quota_gb(quota_gb)
    db = conn()
    db.execute("UPDATE users SET quota_bytes=? WHERE username=?", (quota_bytes, username))
    db.commit()
    db.close()
    render_config()
    restart_services("xray.service")


def set_expiry(username, days):
    expire_at = None if days in (None, "", "none", "None") else int(time.time()) + int(days) * 86400
    db = conn()
    db.execute("UPDATE users SET expire_at=? WHERE username=?", (expire_at, username))
    db.commit()
    db.close()
    render_config()
    restart_services("xray.service")


def set_status(username, status):
    db = conn()
    db.execute("UPDATE users SET status=? WHERE username=?", (status, username))
    db.commit()
    db.close()
    render_config()
    restart_services("xray.service")


def delete_user(username):
    db = conn()
    db.execute("DELETE FROM users WHERE username=?", (username,))
    db.commit()
    db.close()
    render_config()
    restart_services("xray.service")


def build_link(username):
    db = conn()
    row = db.execute("SELECT * FROM users WHERE username=?", (username,)).fetchone()
    db.close()
    if not row:
        raise SystemExit(f"User not found: {username}")
    domain = get_setting("domain")
    path_prefix = get_setting("path_prefix")
    label = quote(username)
    path_q = quote(f"/{path_prefix}/ws", safe="")
    return f"vless://{row['uuid']}@{domain}:443?encryption=none&security=tls&type=ws&host={domain}&path={path_q}#{label}"


def list_users():
    rows = all_rows()
    print(f"{'USER':<18} {'STATUS':<10} {'USED':>12} {'QUOTA':>12} {'EXPIRES':<20}")
    print("-" * 78)
    now = int(time.time())
    for r in rows:
        exp = '-' if r['expire_at'] is None else time.strftime('%Y-%m-%d %H:%M', time.localtime(r['expire_at']))
        quota = bytes_fmt(r['quota_bytes'])
        used = bytes_fmt(r['used_bytes'])
        status = r['status']
        if r['expire_at'] and r['expire_at'] <= now and status == 'active':
            status = 'expired'
        elif r['quota_bytes'] is not None and r['used_bytes'] >= r['quota_bytes'] and status == 'active':
            status = 'quota-hit'
        print(f"{r['username']:<18} {status:<10} {used:>12} {quota:>12} {exp:<20}")


def show_usage(username=None):
    db = conn()
    if username:
        rows = db.execute("SELECT * FROM users WHERE username=?", (username,)).fetchall()
    else:
        rows = db.execute("SELECT * FROM users ORDER BY used_bytes DESC, username").fetchall()
    db.close()
    for r in rows:
        rem = '-' if r['quota_bytes'] is None else bytes_fmt(max(r['quota_bytes'] - r['used_bytes'], 0))
        print(f"user={r['username']} used={bytes_fmt(r['used_bytes'])} quota={bytes_fmt(r['quota_bytes'])} remaining={rem}")


def sync_usage(apply_changes=True):
    init_db()
    before = {r['username'] for r in active_user_rows()}
    stats = []
    if XRAY_BIN.exists():
        try:
            raw = subprocess.check_output([str(XRAY_BIN), 'api', 'statsquery', '--server=127.0.0.1:10085'], stderr=subprocess.DEVNULL, timeout=20)
            payload = json.loads(raw.decode('utf-8', errors='ignore'))
            stats = payload.get('stat', []) or []
        except Exception:
            stats = []
    live = {}
    for item in stats:
        name = item.get('name', '')
        val = int(item.get('value', '0'))
        parts = name.split('>>>')
        if len(parts) >= 4 and parts[0] == 'user':
            user = parts[1]
            live[user] = live.get(user, 0) + val
    db = conn()
    rows = db.execute("SELECT * FROM users").fetchall()
    now = int(time.time())
    changed = False
    for r in rows:
        current = int(live.get(r['username'], 0))
        last_live = int(r['last_live_bytes'])
        delta = current - last_live if current >= last_live else current
        if delta < 0:
            delta = 0
        used = int(r['used_bytes']) + delta
        status = r['status']
        if r['expire_at'] is not None and int(r['expire_at']) <= now and status == 'active':
            status = 'disabled'
            changed = True
        if r['quota_bytes'] is not None and used >= int(r['quota_bytes']) and status == 'active':
            status = 'disabled'
            changed = True
        if delta != 0 or current != last_live or status != r['status']:
            db.execute("UPDATE users SET used_bytes=?, last_live_bytes=?, status=? WHERE username=?", (used, current, status, r['username']))
    db.commit()
    db.close()
    after = {r['username'] for r in active_user_rows()}
    if apply_changes and (before != after or changed):
        render_config()
        restart_services("xray.service")


def status_info():
    domain = get_setting('domain', '-')
    path_prefix = get_setting('path_prefix', '-')
    local_port = get_setting('local_port', '-')
    print(f"domain: {domain}")
    print(f"path: /{path_prefix}/ws")
    print(f"local_port: {local_port}")
    print(f"users_total: {len(all_rows())}")
    print(f"users_active: {len(active_user_rows())}")


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    sub.add_parser('init-db')
    sp = sub.add_parser('set-setting'); sp.add_argument('key'); sp.add_argument('value')
    sub.add_parser('render-config')
    sp = sub.add_parser('add'); sp.add_argument('username'); sp.add_argument('--days'); sp.add_argument('--quota-gb'); sp.add_argument('--note', default='')
    sp = sub.add_parser('quota'); sp.add_argument('username'); sp.add_argument('quota_gb')
    sp = sub.add_parser('expiry'); sp.add_argument('username'); sp.add_argument('days')
    sp = sub.add_parser('enable'); sp.add_argument('username')
    sp = sub.add_parser('disable'); sp.add_argument('username')
    sp = sub.add_parser('delete'); sp.add_argument('username')
    sp = sub.add_parser('link'); sp.add_argument('username')
    sub.add_parser('list')
    sp = sub.add_parser('usage'); sp.add_argument('username', nargs='?')
    sub.add_parser('sync')
    sub.add_parser('status')
    args = ap.parse_args()
    if args.cmd == 'init-db':
        init_db()
    elif args.cmd == 'set-setting':
        set_setting(args.key, args.value)
    elif args.cmd == 'render-config':
        render_config()
    elif args.cmd == 'add':
        add_user(args.username, days=args.days, quota_gb=args.quota_gb, note=args.note)
        print(build_link(args.username))
    elif args.cmd == 'quota':
        set_quota(args.username, args.quota_gb)
    elif args.cmd == 'expiry':
        set_expiry(args.username, args.days)
    elif args.cmd == 'enable':
        set_status(args.username, 'active')
    elif args.cmd == 'disable':
        set_status(args.username, 'disabled')
    elif args.cmd == 'delete':
        delete_user(args.username)
    elif args.cmd == 'link':
        print(build_link(args.username))
    elif args.cmd == 'list':
        list_users()
    elif args.cmd == 'usage':
        show_usage(args.username)
    elif args.cmd == 'sync':
        sync_usage(True)
    elif args.cmd == 'status':
        status_info()

if __name__ == '__main__':
    main()
PYEOF
  chmod +x "$MANAGER_PY"
}

write_wrapper() {
  cat > "$WRAPPER_SH" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
APP_DIR="/opt/pooyan"
MANAGER="$APP_DIR/manager.py"
while true; do
  clear
  echo "========================================"
  printf "%20s\n" "Pooyan 0.07"
  echo "========================================"
  echo
  echo "1) List users"
  echo "2) Add user"
  echo "3) Show user link"
  echo "4) Show usage"
  echo "5) Set quota"
  echo "6) Set expiry"
  echo "7) Enable user"
  echo "8) Disable user"
  echo "9) Delete user"
  echo "10) Sync usage & enforce"
  echo "11) Restart xray/cloudflared"
  echo "12) Service status"
  echo "13) Quick install command"
  echo "0) Exit"
  echo
  read -rp "Option [0]: " opt
  opt="${opt:-0}"
  case "$opt" in
    1) python3 "$MANAGER" list ;;
    2)
      read -rp "Username: " u
      read -rp "Expiry days (blank=none): " d
      read -rp "Quota GB (blank=none): " q
      read -rp "Note (optional): " n
      args=("add" "$u")
      [ -n "$d" ] && args+=("--days" "$d")
      [ -n "$q" ] && args+=("--quota-gb" "$q")
      [ -n "$n" ] && args+=("--note" "$n")
      python3 "$MANAGER" "${args[@]}"
      ;;
    3) read -rp "Username: " u; python3 "$MANAGER" link "$u" ;;
    4) read -rp "Username (blank=all): " u; if [ -n "$u" ]; then python3 "$MANAGER" usage "$u"; else python3 "$MANAGER" usage; fi ;;
    5) read -rp "Username: " u; read -rp "Quota GB or none: " q; python3 "$MANAGER" quota "$u" "$q" ;;
    6) read -rp "Username: " u; read -rp "Days from now or none: " d; python3 "$MANAGER" expiry "$u" "$d" ;;
    7) read -rp "Username: " u; python3 "$MANAGER" enable "$u" ;;
    8) read -rp "Username: " u; python3 "$MANAGER" disable "$u" ;;
    9) read -rp "Username: " u; python3 "$MANAGER" delete "$u" ;;
    10) python3 "$MANAGER" sync ;;
    11) systemctl restart xray.service cloudflared.service ;;
    12) systemctl --no-pager --full status xray.service cloudflared.service pooyan-sync.timer | sed -n '1,80p'; python3 "$MANAGER" status ;;
    13) echo "bash <(curl -fsSL https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh)" ;;
    0) exit 0 ;;
    *) echo "Invalid option" ;;
  esac
  echo
  read -rp "Press Enter to continue..." _
done
SH
  chmod +x "$WRAPPER_SH"
  ln -sf "$WRAPPER_SH" /usr/bin/pooyan
}

write_cloudflared_config() {
  local tunnel_uuid="$1" domain="$2" local_port="$3"
  cat > "$APP_DIR/config.yaml" <<EOF
 tunnel: $tunnel_uuid
 credentials-file: /root/.cloudflared/$tunnel_uuid.json
 ingress:
   - hostname: $domain
     service: http://127.0.0.1:$local_port
   - service: http_status:404
EOF
  sed -i 's/^ //g' "$APP_DIR/config.yaml"
}

write_systemd_units() {
  cat > /etc/systemd/system/xray.service <<EOF
[Unit]
Description=Pooyan Xray
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$Xray_BIN run -config $APP_DIR/config.json
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

  cat > /etc/systemd/system/cloudflared.service <<EOF
[Unit]
Description=Pooyan Cloudflared Tunnel
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$CF_BIN tunnel --edge-ip-version auto --protocol http2 --config $APP_DIR/config.yaml run
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

  cat > /etc/systemd/system/pooyan-sync.service <<EOF
[Unit]
Description=Pooyan usage sync
After=xray.service

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 $MANAGER_PY sync
EOF

  cat > /etc/systemd/system/pooyan-sync.timer <<EOF
[Unit]
Description=Run Pooyan usage sync every minute

[Timer]
OnBootSec=2min
OnUnitActiveSec=1min
Unit=pooyan-sync.service

[Install]
WantedBy=timers.target
EOF

  systemctl daemon-reload
  systemctl enable xray.service cloudflared.service pooyan-sync.timer >/dev/null
}

install_multiuser_service() {
  ensure_root
  ensure_deps
  require_systemd
  download_binaries
  write_manager_py
  write_wrapper
  python3 "$MANAGER_PY" init-db

  local domain ip_mode tunnel_name first_user days quota local_port path_prefix tunnel_uuid create_out
  read -rp "$(t enter_domain)" domain
  if [ -z "$domain" ] || ! grep -q '\.' <<<"$domain"; then
    echo "Invalid domain"
    exit 1
  fi
  read -rp "$(t enter_ipmode)" ip_mode
  ip_mode="${ip_mode:-4}"
  tunnel_name_default="$(echo "$domain" | awk -F. '{print $1}')"
  read -rp "$(t enter_tunnel_name)" tunnel_name
  tunnel_name="${tunnel_name:-$tunnel_name_default}"
  local_port="$((RANDOM + 10000))"
  path_prefix="$(cat /proc/sys/kernel/random/uuid | cut -d- -f1)"

  echo
  echo "Cloudflared login will open a browser authorization step."
  "$CF_BIN" --edge-ip-version "$ip_mode" --protocol http2 tunnel login

  create_out="$($CF_BIN --edge-ip-version "$ip_mode" --protocol http2 tunnel create "$tunnel_name" 2>&1 || true)"
  tunnel_uuid="$(grep -Eo '[0-9a-fA-F-]{36}' <<<"$create_out" | head -n1 || true)"
  if [ -z "$tunnel_uuid" ]; then
    tunnel_uuid="$($CF_BIN tunnel list 2>/dev/null | awk -v name="$tunnel_name" '$2==name{print $1}' | head -n1 || true)"
  fi
  if [ -z "$tunnel_uuid" ]; then
    echo "Unable to determine tunnel UUID."
    echo "$create_out"
    exit 1
  fi

  "$CF_BIN" --edge-ip-version "$ip_mode" --protocol http2 tunnel route dns "$tunnel_name" "$domain"

  python3 "$MANAGER_PY" set-setting domain "$domain"
  python3 "$MANAGER_PY" set-setting local_port "$local_port"
  python3 "$MANAGER_PY" set-setting path_prefix "$path_prefix"
  python3 "$MANAGER_PY" set-setting tunnel_name "$tunnel_name"
  python3 "$MANAGER_PY" set-setting tunnel_uuid "$tunnel_uuid"
  python3 "$MANAGER_PY" set-setting ip_mode "$ip_mode"
  python3 "$MANAGER_PY" render-config

  write_cloudflared_config "$tunnel_uuid" "$domain" "$local_port"
  write_systemd_units
  systemctl restart xray.service
  systemctl restart cloudflared.service
  systemctl restart pooyan-sync.timer

  read -rp "$(t add_first_user)" first_user
  if [ -n "$first_user" ]; then
    read -rp "$(t days_first_user)" days
    read -rp "$(t quota_first_user)" quota
    args=(add "$first_user")
    [ -n "$days" ] && args+=(--days "$days")
    [ -n "$quota" ] && args+=(--quota-gb "$quota")
    first_link="$(python3 "$MANAGER_PY" "${args[@]}" | tail -n1)"
    echo
    echo "$(t install_done)"
    echo "$first_link"
  else
    echo "$(t install_done)"
  fi
}

manage_users_menu() {
  ensure_root
  if ! need_installed; then
    return
  fi
  while true; do
    banner
    echo "$(t user_menu)"
    echo
    echo "$(t um_list)"
    echo "$(t um_add)"
    echo "$(t um_link)"
    echo "$(t um_usage)"
    echo "$(t um_quota)"
    echo "$(t um_expiry)"
    echo "$(t um_enable)"
    echo "$(t um_disable)"
    echo "$(t um_delete)"
    echo "$(t um_restart)"
    echo "$(t um_back)"
    echo
    read -rp "$(t prompt_user_menu)" uo
    uo="${uo:-0}"
    case "$uo" in
      1) python3 "$MANAGER_PY" list ;;
      2)
        read -rp "$(t enter_username)" username
        read -rp "$(t enter_days)" days
        read -rp "$(t enter_quota)" quota
        read -rp "$(t enter_note)" note
        args=(add "$username")
        [ -n "$days" ] && [ "$days" != "none" ] && args+=(--days "$days")
        [ -n "$quota" ] && [ "$quota" != "none" ] && args+=(--quota-gb "$quota")
        [ -n "$note" ] && args+=(--note "$note")
        python3 "$MANAGER_PY" "${args[@]}"
        ;;
      3) read -rp "$(t enter_username)" username; python3 "$MANAGER_PY" link "$username" ;;
      4) read -rp "$(t enter_username)" username; if [ -n "$username" ]; then python3 "$MANAGER_PY" usage "$username"; else python3 "$MANAGER_PY" usage; fi ;;
      5) read -rp "$(t enter_username)" username; read -rp "$(t enter_quota)" quota; python3 "$MANAGER_PY" quota "$username" "${quota:-none}" ;;
      6) read -rp "$(t enter_username)" username; read -rp "$(t enter_days)" days; python3 "$MANAGER_PY" expiry "$username" "${days:-none}" ;;
      7) read -rp "$(t enter_username)" username; python3 "$MANAGER_PY" enable "$username" ;;
      8) read -rp "$(t enter_username)" username; python3 "$MANAGER_PY" disable "$username" ;;
      9) read -rp "$(t enter_username)" username; python3 "$MANAGER_PY" delete "$username" ;;
      10) systemctl restart xray.service cloudflared.service ;;
      0) return ;;
      *) echo "Invalid option" ;;
    esac
    echo
    read -rp "Press Enter to continue..." _
  done
}

show_status() {
  ensure_root
  if ! need_installed; then
    return
  fi
  echo "$(t service_status)"
  echo
  systemctl --no-pager --full status xray.service cloudflared.service pooyan-sync.timer | sed -n '1,80p' || true
  echo
  python3 "$MANAGER_PY" status
}

github_install_info() {
  banner
  echo "$(t github_line1)"
  echo
  echo "$(t github_line2)"
  echo "bash <(curl -fsSL $RAW_INSTALL_URL)"
  echo
  echo "pooyan command after install:"
  echo "pooyan"
}

sync_now() {
  ensure_root
  if ! need_installed; then
    return
  fi
  python3 "$MANAGER_PY" sync
  echo "$(t sync_done)"
}

uninstall_service() {
  ensure_root
  systemctl disable --now xray.service cloudflared.service pooyan-sync.timer >/dev/null 2>&1 || true
  rm -f /etc/systemd/system/xray.service /etc/systemd/system/cloudflared.service /etc/systemd/system/pooyan-sync.service /etc/systemd/system/pooyan-sync.timer
  systemctl daemon-reload >/dev/null 2>&1 || true
  rm -f /usr/bin/pooyan
  rm -rf "$APP_DIR"
  echo "$(t uninstall_done)"
}

main_menu() {
  while true; do
    banner
    echo "$(t welcome)"
    echo
    echo "$(t main_note)"
    echo
    echo "$(t menu_install)"
    echo "$(t menu_manage)"
    echo "$(t menu_sync)"
    echo "$(t menu_status)"
    echo "$(t menu_github)"
    echo "$(t menu_uninstall)"
    echo "$(t menu_exit)"
    echo
    read -rp "$(t prompt_mode)" mode
    mode="${mode:-1}"
    case "$mode" in
      1) install_multiuser_service ;;
      2) manage_users_menu ;;
      3) sync_now ;;
      4) show_status ;;
      5) github_install_info ;;
      6) uninstall_service ;;
      0) exit 0 ;;
      *) echo "Invalid option" ;;
    esac
    echo
    read -rp "Press Enter to continue..." _
  done
}

ensure_root
choose_language
main_menu
