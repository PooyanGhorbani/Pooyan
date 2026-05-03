#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_NAME="Pooyan"
PROJECT_VERSION="0.13"
APP_TITLE="${PROJECT_NAME} ${PROJECT_VERSION} - China Stable"
APP_DIR="/opt/pooyan"
APP_CMD="/usr/bin/pooyan"
RAW_URL="https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh"

XRAY_CONFIG="/usr/local/etc/xray/config.json"
XRAY_BIN="/usr/local/bin/xray"
CLOUDFLARED_BIN="/usr/local/bin/cloudflared"
LINK_FILE="/root/v2ray.txt"
IMPORT_FILE="/root/pooyan-v2rayn-import.txt"
SUB_FILE="/root/pooyan-sub.txt"
STATE_FILE="${APP_DIR}/state.env"
ARGO_LOG="/tmp/pooyan-argo.log"
ARGO_PID="${APP_DIR}/cloudflared.pid"

DEFAULT_CF_DOMAIN="cloudflare.182682.xyz"
HTTP_PORTS=(80 8080 8880 2052 2082 2086 2095)
HTTPS_PORTS=(443 2053 2083 2087 2096 8443)

red() { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
cyan() { printf '\033[36m%s\033[0m\n' "$*"; }

pause() { echo; read -r -p "Press Enter / اینتر بزن..." _ || true; }
need_root() { [ "${EUID:-$(id -u)}" -eq 0 ] || { red "Run as root."; exit 1; }; }

banner() {
  clear || true
  echo "============================================================"
  printf "%33s\n" "${APP_TITLE}"
  echo "============================================================"
}

os_id() { . /etc/os-release 2>/dev/null || true; echo "${ID:-linux}"; }
install_pkgs() {
  local os; os="$(os_id)"
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y || true
    apt-get install -y curl wget unzip tar ca-certificates openssl procps iproute2 lsof || true
  elif command -v yum >/dev/null 2>&1; then
    yum install -y curl wget unzip tar ca-certificates openssl procps-ng iproute lsof || true
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y curl wget unzip tar ca-certificates openssl procps-ng iproute lsof || true
  elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache curl wget unzip tar ca-certificates openssl procps iproute2 lsof || true
  else
    yellow "Unknown package manager. Continuing..."
  fi
}

random_port() {
  local p
  p=$((20000 + ($(od -An -N2 -tu2 /dev/urandom | tr -d ' ') % 25000)))
  echo "$p"
}

new_uuid() {
  if command -v xray >/dev/null 2>&1; then
    xray uuid 2>/dev/null | head -n1 || cat /proc/sys/kernel/random/uuid
  else
    cat /proc/sys/kernel/random/uuid
  fi
}

public_ip() {
  curl -4 -fsS --max-time 8 https://api.ipify.org 2>/dev/null \
  || curl -4 -fsS --max-time 8 https://ifconfig.me 2>/dev/null \
  || curl -4 -fsS --max-time 8 https://icanhazip.com 2>/dev/null \
  || hostname -I 2>/dev/null | awk '{print $1}'
}

install_self_manager() {
  mkdir -p "$APP_DIR"
  if [ -r "${0:-}" ]; then
    cp "${0}" "${APP_DIR}/pooyan.sh" 2>/dev/null || true
  fi
  if [ ! -s "${APP_DIR}/pooyan.sh" ]; then
    curl -fsSL "$RAW_URL" -o "${APP_DIR}/pooyan.sh" || true
  fi
  chmod +x "${APP_DIR}/pooyan.sh" 2>/dev/null || true
  cat > "$APP_CMD" <<'EOS'
#!/usr/bin/env bash
exec bash /opt/pooyan/pooyan.sh "$@"
EOS
  chmod +x "$APP_CMD"
}

install_xray() {
  if command -v xray >/dev/null 2>&1 && [ -x "$(command -v xray)" ]; then
    XRAY_BIN="$(command -v xray)"
    return 0
  fi
  cyan "Installing Xray..."
  bash -c "$(curl -LfsS https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install || {
    red "Xray install failed. Check VPS network/GitHub access."
    exit 1
  }
  command -v xray >/dev/null 2>&1 && XRAY_BIN="$(command -v xray)"
}

install_cloudflared() {
  if command -v cloudflared >/dev/null 2>&1; then
    CLOUDFLARED_BIN="$(command -v cloudflared)"
    return 0
  fi
  cyan "Installing cloudflared..."
  local arch url
  case "$(uname -m)" in
    x86_64|amd64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    armv7l|armv6l) arch="arm" ;;
    *) red "Unsupported arch for cloudflared: $(uname -m)"; exit 1 ;;
  esac
  url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${arch}"
  curl -LfsS "$url" -o "$CLOUDFLARED_BIN" || {
    red "cloudflared download failed. Check VPS network/GitHub access."
    exit 1
  }
  chmod +x "$CLOUDFLARED_BIN"
}

open_firewall_port() {
  local port="$1"
  yellow "Trying to open TCP port ${port} locally if firewall is active..."
  if command -v ufw >/dev/null 2>&1; then
    ufw allow "${port}/tcp" >/dev/null 2>&1 || true
  fi
  if command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
    firewall-cmd --permanent --add-port="${port}/tcp" >/dev/null 2>&1 || true
    firewall-cmd --reload >/dev/null 2>&1 || true
  fi
  if command -v iptables >/dev/null 2>&1; then
    iptables -C INPUT -p tcp --dport "$port" -j ACCEPT >/dev/null 2>&1 || iptables -I INPUT -p tcp --dport "$port" -j ACCEPT >/dev/null 2>&1 || true
  fi
}

stop_old_pooyan() {
  if [ -f "$ARGO_PID" ]; then
    kill "$(cat "$ARGO_PID")" >/dev/null 2>&1 || true
    rm -f "$ARGO_PID"
  fi
  pkill -f "cloudflared.*127.0.0.1" >/dev/null 2>&1 || true
}

write_xray_config() {
  local uuid="$1" port="$2" path="$3"
  mkdir -p "$(dirname "$XRAY_CONFIG")"
  cat > "$XRAY_CONFIG" <<JSON
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "tag": "pooyan-vless-ws",
      "listen": "0.0.0.0",
      "port": ${port},
      "protocol": "vless",
      "settings": {
        "clients": [ { "id": "${uuid}", "level": 0 } ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "${path}" }
      }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" }
  ]
}
JSON
  if ! "$XRAY_BIN" run -test -config "$XRAY_CONFIG" >/tmp/pooyan-xray-test.log 2>&1; then
    cat /tmp/pooyan-xray-test.log || true
    red "Xray config test failed."
    exit 1
  fi
}

start_xray() {
  if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files | grep -q '^xray\.service'; then
    systemctl enable xray >/dev/null 2>&1 || true
    systemctl restart xray
  else
    pkill -f "xray.*${XRAY_CONFIG}" >/dev/null 2>&1 || true
    nohup "$XRAY_BIN" run -config "$XRAY_CONFIG" >/tmp/pooyan-xray.log 2>&1 &
  fi
}

start_quick_tunnel() {
  local port="$1"
  : > "$ARGO_LOG"
  stop_old_pooyan
  nohup "$CLOUDFLARED_BIN" tunnel --url "http://127.0.0.1:${port}" --edge-ip-version auto --no-autoupdate >"$ARGO_LOG" 2>&1 &
  echo $! > "$ARGO_PID"
}

wait_trycloudflare_host() {
  local host="" i
  for i in $(seq 1 75); do
    host="$(grep -Eo 'https://[-a-zA-Z0-9]+(\.[-a-zA-Z0-9]+)*\.trycloudflare\.com' "$ARGO_LOG" 2>/dev/null | head -n1 | sed 's#https://##')"
    if [ -n "$host" ]; then echo "$host"; return 0; fi
    sleep 1
  done
  return 1
}

vless_link() {
  local server="$1" port="$2" security="$3" host="$4" path="$5" uuid="$6" remark="$7"
  local enc_path
  enc_path="%2F${path#/}"
  if [ "$security" = "tls" ]; then
    printf 'vless://%s@%s:%s?encryption=none&security=tls&sni=%s&fp=chrome&type=ws&host=%s&path=%s#%s\n' \
      "$uuid" "$server" "$port" "$host" "$host" "$enc_path" "$remark"
  else
    if [ -n "$host" ]; then
      printf 'vless://%s@%s:%s?encryption=none&security=none&type=ws&host=%s&path=%s#%s\n' \
        "$uuid" "$server" "$port" "$host" "$enc_path" "$remark"
    else
      printf 'vless://%s@%s:%s?encryption=none&security=none&type=ws&path=%s#%s\n' \
        "$uuid" "$server" "$port" "$enc_path" "$remark"
    fi
  fi
}

save_links() {
  local uuid="$1" local_port="$2" path="$3" ip="$4" cf_domain="$5" try_host="${6:-}"
  : > "$IMPORT_FILE"

  # Direct IP is always first, because it does not depend on Cloudflare.
  vless_link "$ip" "$local_port" "none" "" "$path" "$uuid" "Pooyan-DIRECT-IP-${local_port}" >> "$IMPORT_FILE"

  if [ -n "$try_host" ]; then
    # Direct trycloudflare hostname, then old China-style front-domain variants.
    vless_link "$try_host" 443 "tls" "$try_host" "$path" "$uuid" "Pooyan-TRY-TLS-443" >> "$IMPORT_FILE"

    for p in "${HTTP_PORTS[@]}"; do
      vless_link "$cf_domain" "$p" "none" "$try_host" "$path" "$uuid" "Pooyan-OLD-HTTP-${p}" >> "$IMPORT_FILE"
    done
    for p in "${HTTPS_PORTS[@]}"; do
      vless_link "$cf_domain" "$p" "tls" "$try_host" "$path" "$uuid" "Pooyan-OLD-TLS-${p}" >> "$IMPORT_FILE"
    done
  fi

  base64 "$IMPORT_FILE" | tr -d '\n' > "$SUB_FILE" || true

  cat > "$LINK_FILE" <<EOF2
Pooyan ${PROJECT_VERSION} - China Stable Links
==============================================

VPS IP: ${ip}
Local VLESS WS port: ${local_port}
UUID: ${uuid}
WS path: ${path}
CF front domain: ${cf_domain}
TryCloudflare host: ${try_host:-FAILED / not generated}

IMPORTANT:
- For v2rayN, import from this file only:
  ${IMPORT_FILE}
- Do NOT paste VLESS links into Linux/PuTTY command line. The & characters will break the link.
- Direct IP link is first. It has no domain and no TLS.
- Old-style China links use ${cf_domain} as address and trycloudflare.com as Host/SNI.

Files:
- Human readable: ${LINK_FILE}
- v2rayN import:  ${IMPORT_FILE}
- Base64 sub:     ${SUB_FILE}

Links:
$(cat "$IMPORT_FILE")
EOF2
}

print_links() {
  if [ -f "$LINK_FILE" ]; then
    cat "$LINK_FILE"
  else
    red "No links yet. Run option 1 first."
  fi
}

quick_china_stable() {
  need_root
  banner
  cyan "Quick China Stable mode"
  yellow "برمی‌گردیم به مدل قدیمی خوب: trycloudflare + cloudflare.182682.xyz + پورت‌های رسمی Cloudflare."
  echo

  install_self_manager
  install_pkgs
  install_xray
  install_cloudflared

  local uuid path local_port ip cf_domain try_host
  uuid="$(new_uuid)"
  path="/${uuid}"
  local_port="$(random_port)"
  ip="$(public_ip)"
  [ -n "$ip" ] || ip="YOUR_SERVER_IP"

  read -r -p "CF front domain [${DEFAULT_CF_DOMAIN}]: " cf_domain || true
  cf_domain="${cf_domain:-$DEFAULT_CF_DOMAIN}"

  write_xray_config "$uuid" "$local_port" "$path"
  start_xray
  open_firewall_port "$local_port"

  mkdir -p "$APP_DIR"
  cat > "$STATE_FILE" <<EOF2
UUID='${uuid}'
PATH_VALUE='${path}'
LOCAL_PORT='${local_port}'
SERVER_IP='${ip}'
CF_DOMAIN='${cf_domain}'
EOF2

  start_quick_tunnel "$local_port"
  yellow "Waiting for trycloudflare.com address..."
  if try_host="$(wait_trycloudflare_host)"; then
    green "trycloudflare host: ${try_host}"
    echo "TRY_HOST='${try_host}'" >> "$STATE_FILE"
  else
    red "Could not get trycloudflare.com URL. Direct IP link will still be generated."
    yellow "Check: cat ${ARGO_LOG}"
    try_host=""
  fi

  save_links "$uuid" "$local_port" "$path" "$ip" "$cf_domain" "$try_host"

  echo
  green "Done. / آماده شد."
  echo
  cyan "Use this for v2rayN import:"
  echo "cat ${IMPORT_FILE}"
  echo
  print_links
}

status_view() {
  echo "Pooyan ${PROJECT_VERSION} status"
  echo "---------------------------"
  if command -v xray >/dev/null 2>&1; then xray version | head -n1 || true; fi
  if pgrep -x xray >/dev/null 2>&1 || pgrep -f "xray.*${XRAY_CONFIG}" >/dev/null 2>&1; then green "Xray: running"; else red "Xray: not running"; fi
  if [ -f "$ARGO_PID" ] && kill -0 "$(cat "$ARGO_PID")" >/dev/null 2>&1; then green "cloudflared: running"; else red "cloudflared: not running"; fi
  if [ -f "$STATE_FILE" ]; then echo; cat "$STATE_FILE"; fi
}

logs_view() {
  echo "--- cloudflared log: ${ARGO_LOG} ---"
  tail -n 80 "$ARGO_LOG" 2>/dev/null || true
  echo
  echo "--- xray log: /tmp/pooyan-xray.log ---"
  tail -n 80 /tmp/pooyan-xray.log 2>/dev/null || true
}

uninstall_pooyan() {
  red "Removing Pooyan quick tunnel and links..."
  stop_old_pooyan
  rm -f "$LINK_FILE" "$IMPORT_FILE" "$SUB_FILE" "$STATE_FILE" "$ARGO_LOG" "$ARGO_PID"
  rm -f "$APP_CMD"
  rm -rf "$APP_DIR"
  green "Pooyan removed. Xray package itself was kept."
}

menu() {
  need_root
  install_self_manager >/dev/null 2>&1 || true
  while true; do
    banner
    echo "1) Quick China Stable - old good configs + Direct IP"
    echo "2) Show links / نمایش لینک‌ها"
    echo "3) Status / وضعیت"
    echo "4) Logs / لاگ‌ها"
    echo "5) Uninstall Pooyan files / حذف فایل‌های Pooyan"
    echo "0) Exit"
    echo
    read -r -p "Choose [1]: " c || true
    case "${c:-1}" in
      1) quick_china_stable; pause ;;
      2) banner; print_links; pause ;;
      3) banner; status_view; pause ;;
      4) banner; logs_view; pause ;;
      5) banner; uninstall_pooyan; pause ;;
      0) exit 0 ;;
      *) echo "Invalid"; sleep 1 ;;
    esac
  done
}

case "${1:-menu}" in
  quick) quick_china_stable ;;
  links) print_links ;;
  status) status_view ;;
  logs) logs_view ;;
  uninstall) uninstall_pooyan ;;
  menu|*) menu ;;
esac
