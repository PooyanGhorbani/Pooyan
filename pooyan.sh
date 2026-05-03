#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_NAME="Pooyan"
PROJECT_VERSION="0.17"
APP_TITLE="${PROJECT_NAME} ${PROJECT_VERSION} - RackNerd Strong 5 Links"
APP_DIR="/opt/pooyan"
APP_CMD="/usr/bin/pooyan"
RAW_URL="https://raw.githubusercontent.com/PooyanGhorbani/Pooyan/main/pooyan.sh"

XRAY_CONFIG="/usr/local/etc/xray/config.json"
XRAY_BIN="/usr/local/bin/xray"
CLOUDFLARED_BIN="/usr/local/bin/cloudflared"
HYSTERIA_BIN="/usr/local/bin/hysteria"
HYSTERIA_CONFIG="/etc/hysteria/config.yaml"
HYSTERIA_CERT="/etc/hysteria/server.crt"
HYSTERIA_KEY="/etc/hysteria/server.key"
HYSTERIA_PORT="443"
HYSTERIA_SNI="www.bing.com"

LINK_FILE="/root/v2ray.txt"
IMPORT_FILE="/root/pooyan-v2rayn-import.txt"
SUB_FILE="/root/pooyan-sub.txt"
STATE_FILE="${APP_DIR}/state.env"
ARGO_LOG="/tmp/pooyan-argo.log"
ARGO_PID="${APP_DIR}/cloudflared.pid"

# Old China-style Cloudflare front address that was working well in the user's tests.
CF_FRONT_DOMAIN="cloudflare.182682.xyz"

red() { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
cyan() { printf '\033[36m%s\033[0m\n' "$*"; }

need_root() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    red "Run as root. / 请用 root 运行 / با root اجرا کن."
    exit 1
  fi
}

banner() {
  clear || true
  echo "============================================================"
  printf "%45s\n" "$APP_TITLE"
  echo "============================================================"
  echo
}

pause() { echo; read -r -p "Press Enter / اینتر بزن..." _ || true; }

install_pkgs() {
  if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y || true
    apt-get install -y curl wget unzip tar ca-certificates openssl procps iproute2 lsof jq coreutils grep || true
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y curl wget unzip tar ca-certificates openssl procps-ng iproute lsof jq coreutils grep || true
  elif command -v yum >/dev/null 2>&1; then
    yum install -y curl wget unzip tar ca-certificates openssl procps-ng iproute lsof jq coreutils grep || true
  elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache bash curl wget unzip tar ca-certificates openssl procps iproute2 lsof jq coreutils grep || true
  else
    yellow "Unknown package manager. Continuing..."
  fi
}

public_ip() {
  curl -4 -fsS --max-time 8 https://api.ipify.org 2>/dev/null \
  || curl -4 -fsS --max-time 8 https://ifconfig.me 2>/dev/null \
  || curl -4 -fsS --max-time 8 https://icanhazip.com 2>/dev/null \
  || hostname -I 2>/dev/null | awk '{print $1}'
}

random_uuid() {
  if command -v xray >/dev/null 2>&1; then
    xray uuid 2>/dev/null | head -n1 || cat /proc/sys/kernel/random/uuid
  else
    cat /proc/sys/kernel/random/uuid
  fi
}

random_path() { printf 'pooyan-%s' "$(openssl rand -hex 8)"; }
random_secret() { openssl rand -hex 16; }

port_is_free() {
  local p="$1"
  ! ss -lnt 2>/dev/null | awk '{print $4}' | grep -Eq "[:.]${p}$"
}

random_port() {
  local p i
  for i in $(seq 1 80); do
    p=$((20000 + ($(od -An -N2 -tu2 /dev/urandom | tr -d ' ') % 25000)))
    if port_is_free "$p"; then echo "$p"; return 0; fi
  done
  echo "42727"
}

url_label() { printf '%s' "$1" | sed 's/ /%20/g; s/#/%23/g; s/&/%26/g'; }

install_xray() {
  if command -v xray >/dev/null 2>&1; then
    XRAY_BIN="$(command -v xray)"
    return 0
  fi
  cyan "Installing Xray..."
  bash -c "$(curl -LfsS https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install || {
    red "Xray install failed. Check VPS network/GitHub access."
    exit 1
  }
  XRAY_BIN="$(command -v xray || echo /usr/local/bin/xray)"
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

install_hysteria2() {
  if command -v hysteria >/dev/null 2>&1; then
    HYSTERIA_BIN="$(command -v hysteria)"
    return 0
  fi
  if ! command -v systemctl >/dev/null 2>&1; then
    yellow "No systemd found; skipping Hysteria2. VLESS links will still be generated."
    return 1
  fi
  cyan "Installing Hysteria2..."
  HYSTERIA_USER=root bash <(curl -fsSL https://get.hy2.sh/) || {
    yellow "Hysteria2 install failed; continuing without HY2 link."
    return 1
  }
  HYSTERIA_BIN="$(command -v hysteria || echo /usr/local/bin/hysteria)"
}

enable_network_tuning() {
  cyan "Enabling BBR + RackNerd network tuning if supported..."
  modprobe tcp_bbr >/dev/null 2>&1 || true
  cat >/etc/sysctl.d/99-pooyan-racknerd.conf <<'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_keepalive_time=600
net.ipv4.tcp_keepalive_intvl=30
net.ipv4.tcp_keepalive_probes=5
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
EOF
  sysctl --system >/dev/null 2>&1 || true
}

install_self_manager() {
  mkdir -p "$APP_DIR"
  local src="${BASH_SOURCE[0]:-${0:-}}"
  if [ -n "$src" ] && [ -r "$src" ]; then
    cp "$src" "${APP_DIR}/pooyan.sh" 2>/dev/null || true
  fi
  if [ ! -s "${APP_DIR}/pooyan.sh" ]; then
    curl -fsSL "$RAW_URL" -o "${APP_DIR}/pooyan.sh" || true
  fi
  chmod +x "${APP_DIR}/pooyan.sh" 2>/dev/null || true
  cat > "$APP_CMD" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
APP_DIR="/opt/pooyan"
LINK_FILE="/root/v2ray.txt"
IMPORT_FILE="/root/pooyan-v2rayn-import.txt"
ARGO_LOG="/tmp/pooyan-argo.log"
case "${1:-menu}" in
  renew|install|racknerd)
    exec bash "${APP_DIR}/pooyan.sh" install
    ;;
  links)
    [ -f "$LINK_FILE" ] && cat "$LINK_FILE" || echo "No link file: $LINK_FILE"
    ;;
  import)
    [ -f "$IMPORT_FILE" ] && cat "$IMPORT_FILE" || echo "No import file: $IMPORT_FILE"
    ;;
  test)
    echo "== Listening TCP =="; ss -lntp 2>/dev/null | grep -E 'xray|cloudflared|hysteria|:443|:80' || true
    echo; echo "== Listening UDP =="; ss -lunp 2>/dev/null | grep -E 'hysteria|:443' || true
    echo; echo "== Xray =="; systemctl is-active xray 2>/dev/null || true
    echo; echo "== Hysteria2 =="; systemctl is-active hysteria-server.service 2>/dev/null || true
    echo; echo "== cloudflared host =="; grep -aEo 'https://[-a-zA-Z0-9]+(\.[-a-zA-Z0-9]+)*\.trycloudflare\.com' "$ARGO_LOG" 2>/dev/null | tail -n1 || true
    ;;
  status)
    echo "Xray:"; systemctl status xray --no-pager 2>/dev/null || true
    echo; echo "Hysteria2:"; systemctl status hysteria-server.service --no-pager 2>/dev/null || true
    echo; echo "Listening ports:"; ss -lntup 2>/dev/null | grep -E 'xray|cloudflared|hysteria|:443|:80' || true
    echo; echo "cloudflared process:"; pgrep -af cloudflared || true
    ;;
  logs)
    echo "--- Xray logs ---"; journalctl -u xray --no-pager -n 80 2>/dev/null || true
    echo; echo "--- Hysteria2 logs ---"; journalctl -u hysteria-server.service --no-pager -n 80 2>/dev/null || true
    echo; echo "--- cloudflared quick tunnel log ---"; cat "$ARGO_LOG" 2>/dev/null || true
    ;;
  stop)
    pkill -f 'cloudflared.*tunnel' 2>/dev/null || true
    systemctl stop xray 2>/dev/null || true
    systemctl stop hysteria-server.service 2>/dev/null || true
    ;;
  start)
    systemctl start xray 2>/dev/null || true
    systemctl start hysteria-server.service 2>/dev/null || true
    ;;
  menu|*)
    echo "Pooyan Manager"
    echo "=============================="
    echo "pooyan renew   - rebuild RackNerd strong 5 links"
    echo "pooyan links   - show human-readable links"
    echo "pooyan import  - show clean v2rayN import links"
    echo "pooyan test    - quick local listening/service test"
    echo "pooyan status  - show status"
    echo "pooyan logs    - show logs"
    ;;
esac
EOF
  chmod +x "$APP_CMD"
}

open_firewall_port() {
  local port="$1" proto="${2:-tcp}"
  yellow "Opening ${proto^^} ${port} locally if firewall is active..."
  if command -v ufw >/dev/null 2>&1; then ufw allow "${port}/${proto}" >/dev/null 2>&1 || true; fi
  if command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
    firewall-cmd --permanent --add-port="${port}/${proto}" >/dev/null 2>&1 || true
    firewall-cmd --reload >/dev/null 2>&1 || true
  fi
  if command -v iptables >/dev/null 2>&1; then
    if [ "$proto" = "udp" ]; then
      iptables -C INPUT -p udp --dport "$port" -j ACCEPT >/dev/null 2>&1 || iptables -I INPUT -p udp --dport "$port" -j ACCEPT >/dev/null 2>&1 || true
    else
      iptables -C INPUT -p tcp --dport "$port" -j ACCEPT >/dev/null 2>&1 || iptables -I INPUT -p tcp --dport "$port" -j ACCEPT >/dev/null 2>&1 || true
    fi
  fi
}

write_xray_config() {
  local uuid="$1" port="$2" path="$3"
  mkdir -p "$(dirname "$XRAY_CONFIG")"
  cat > "$XRAY_CONFIG" <<JSON
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "tag": "pooyan-racknerd-vless-ws",
      "listen": "0.0.0.0",
      "port": ${port},
      "protocol": "vless",
      "settings": {
        "clients": [ { "id": "${uuid}", "level": 0 } ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/${path}" }
      }
    }
  ],
  "outbounds": [ { "protocol": "freedom", "tag": "direct" } ]
}
JSON
  if "$XRAY_BIN" run -test -config "$XRAY_CONFIG" >/tmp/pooyan-xray-test.log 2>&1; then
    return 0
  fi
  if "$XRAY_BIN" test -config "$XRAY_CONFIG" >/tmp/pooyan-xray-test.log 2>&1; then
    return 0
  fi
  red "Xray config test failed:"
  cat /tmp/pooyan-xray-test.log || true
  exit 1
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

write_hysteria_config() {
  local password="$1" obfs_password="$2"
  mkdir -p /etc/hysteria
  if [ ! -s "$HYSTERIA_CERT" ] || [ ! -s "$HYSTERIA_KEY" ]; then
    cyan "Generating self-signed TLS certificate for Hysteria2..."
    openssl req -x509 -newkey rsa:2048 -nodes \
      -keyout "$HYSTERIA_KEY" \
      -out "$HYSTERIA_CERT" \
      -days 3650 \
      -subj "/CN=${HYSTERIA_SNI}" \
      -addext "subjectAltName=DNS:${HYSTERIA_SNI}" >/dev/null 2>&1 || {
        red "Failed to generate Hysteria2 certificate."
        return 1
      }
    chmod 644 "$HYSTERIA_CERT" || true
    chmod 600 "$HYSTERIA_KEY" || true
  fi
  cat > "$HYSTERIA_CONFIG" <<YAML
listen: :${HYSTERIA_PORT}

tls:
  cert: ${HYSTERIA_CERT}
  key: ${HYSTERIA_KEY}
  sniGuard: disable

auth:
  type: password
  password: ${password}

obfs:
  type: salamander
  salamander:
    password: ${obfs_password}

quic:
  initStreamReceiveWindow: 8388608
  maxStreamReceiveWindow: 8388608
  initConnReceiveWindow: 20971520
  maxConnReceiveWindow: 20971520
  maxIdleTimeout: 30s
  maxIncomingStreams: 1024
  disablePathMTUDiscovery: false

masquerade:
  type: proxy
  proxy:
    url: https://${HYSTERIA_SNI}/
    rewriteHost: true
YAML
}

start_hysteria2() {
  if ! command -v systemctl >/dev/null 2>&1; then return 1; fi
  systemctl enable hysteria-server.service >/dev/null 2>&1 || true
  systemctl restart hysteria-server.service >/dev/null 2>&1 || {
    yellow "Hysteria2 service did not start. Check: journalctl -u hysteria-server.service -n 80 --no-pager"
    return 1
  }
  return 0
}

stop_old_cloudflared() {
  if [ -f "$ARGO_PID" ]; then kill "$(cat "$ARGO_PID")" >/dev/null 2>&1 || true; rm -f "$ARGO_PID"; fi
  pkill -f 'cloudflared.*tunnel.*--url' >/dev/null 2>&1 || true
}

start_cloudflared_mode() {
  local port="$1" mode="$2"
  : > "$ARGO_LOG"
  stop_old_cloudflared
  case "$mode" in
    http2-v4) nohup "$CLOUDFLARED_BIN" tunnel --url "http://127.0.0.1:${port}" --no-autoupdate --edge-ip-version 4 --protocol http2 >"$ARGO_LOG" 2>&1 & ;;
    http2-auto) nohup "$CLOUDFLARED_BIN" tunnel --url "http://127.0.0.1:${port}" --no-autoupdate --edge-ip-version auto --protocol http2 >"$ARGO_LOG" 2>&1 & ;;
    quic-v4) nohup "$CLOUDFLARED_BIN" tunnel --url "http://127.0.0.1:${port}" --no-autoupdate --edge-ip-version 4 --protocol quic >"$ARGO_LOG" 2>&1 & ;;
    default) nohup "$CLOUDFLARED_BIN" tunnel --url "http://127.0.0.1:${port}" --no-autoupdate >"$ARGO_LOG" 2>&1 & ;;
  esac
  echo $! > "$ARGO_PID"
}

extract_try_host() {
  grep -aEo 'https://[-a-zA-Z0-9]+(\.[-a-zA-Z0-9]+)*\.trycloudflare\.com' "$ARGO_LOG" 2>/dev/null | head -n1 | sed 's#https://##'
}

get_trycloudflare_host() {
  local port="$1" mode i host
  for mode in http2-v4 http2-auto quic-v4 default; do
    yellow "Trying cloudflared quick tunnel mode: ${mode}" >&2
    start_cloudflared_mode "$port" "$mode"
    host=""
    for i in $(seq 1 90); do
      host="$(extract_try_host || true)"
      if printf '%s' "$host" | grep -Eq '^[-a-zA-Z0-9]+(\.[-a-zA-Z0-9]+)*\.trycloudflare\.com$'; then
        printf '%s\n' "$host"
        return 0
      fi
      if ! kill -0 "$(cat "$ARGO_PID" 2>/dev/null)" >/dev/null 2>&1; then break; fi
      sleep 1
    done
    yellow "No URL from ${mode}. Last log:" >&2
    tail -n 12 "$ARGO_LOG" 2>/dev/null >&2 || true
  done
  return 1
}

vless_ws_link() {
  local addr="$1" port="$2" security="$3" host="$4" path="$5" uuid="$6" remark="$7"
  local enc_path="%2F${path#/}"
  if [ "$security" = "tls" ]; then
    printf 'vless://%s@%s:%s?encryption=none&security=tls&sni=%s&fp=chrome&type=ws&host=%s&path=%s#%s\n' \
      "$uuid" "$addr" "$port" "$host" "$host" "$enc_path" "$(url_label "$remark")"
  else
    if [ -n "$host" ]; then
      printf 'vless://%s@%s:%s?encryption=none&security=none&type=ws&host=%s&path=%s#%s\n' \
        "$uuid" "$addr" "$port" "$host" "$enc_path" "$(url_label "$remark")"
    else
      printf 'vless://%s@%s:%s?encryption=none&security=none&type=ws&path=%s#%s\n' \
        "$uuid" "$addr" "$port" "$enc_path" "$(url_label "$remark")"
    fi
  fi
}

hysteria2_link() {
  local ip="$1" password="$2" obfs_password="$3" remark="$4"
  printf 'hysteria2://%s@%s:%s/?insecure=1&sni=%s&obfs=salamander&obfs-password=%s#%s\n' \
    "$password" "$ip" "$HYSTERIA_PORT" "$HYSTERIA_SNI" "$obfs_password" "$(url_label "$remark")"
}

write_links() {
  local uuid="$1" ip="$2" local_port="$3" path="$4" try_host="${5:-}" hy2_password="${6:-}" hy2_obfs="${7:-}" hy2_ok="${8:-0}"
  mkdir -p "$APP_DIR"
  : > "$IMPORT_FILE"
  : > "$LINK_FILE"

  {
    echo "Pooyan ${PROJECT_VERSION} - RackNerd Strong 5 Links"
    echo "VPS IP: ${ip}"
    echo "Local VLESS WS port: ${local_port}"
    echo "UUID: ${uuid}"
    echo "WS path: /${path}"
    echo "Cloudflare front address: ${CF_FRONT_DOMAIN}"
    if [ -n "$try_host" ]; then echo "TryCloudflare host: ${try_host}"; else echo "TryCloudflare host: FAILED"; fi
    if [ "$hy2_ok" = "1" ]; then echo "Hysteria2 UDP: ${ip}:${HYSTERIA_PORT}"; else echo "Hysteria2 UDP: SKIPPED/FAILED"; fi
    echo
    echo "Only RackNerd-friendly links are generated:"
    echo "1) CF-443 main"
    echo "2) CF-80 backup"
    echo "3) HY2-443 UDP speed test"
    echo "4) DIRECT-IP emergency/test"
    echo
    echo "Clean v2rayN import file: ${IMPORT_FILE}"
    echo "Do NOT paste VLESS links into Linux/PuTTY command line. Use the import file."
    echo
    echo "Links:"
  } >> "$LINK_FILE"

  if printf '%s' "$try_host" | grep -Eq '^[-a-zA-Z0-9]+(\.[-a-zA-Z0-9]+)*\.trycloudflare\.com$'; then
    # Same connection style as the user's fastest link: direct trycloudflare host + TLS 443.
    vless_ws_link "$try_host" 443 tls "$try_host" "$path" "$uuid" "Pooyan-TRY-TLS-443" | tee -a "$IMPORT_FILE" >> "$LINK_FILE"
    vless_ws_link "$CF_FRONT_DOMAIN" 443 tls "$try_host" "$path" "$uuid" "Pooyan-RN-CF-443" | tee -a "$IMPORT_FILE" >> "$LINK_FILE"
    vless_ws_link "$CF_FRONT_DOMAIN" 80 none "$try_host" "$path" "$uuid" "Pooyan-RN-CF-80" | tee -a "$IMPORT_FILE" >> "$LINK_FILE"
  fi

  if [ "$hy2_ok" = "1" ] && [ -n "$hy2_password" ] && [ -n "$hy2_obfs" ]; then
    hysteria2_link "$ip" "$hy2_password" "$hy2_obfs" "Pooyan-RN-HY2-443" | tee -a "$IMPORT_FILE" >> "$LINK_FILE"
  fi

  vless_ws_link "$ip" "$local_port" none "" "$path" "$uuid" "Pooyan-RN-DIRECT-IP-${local_port}" | tee -a "$IMPORT_FILE" >> "$LINK_FILE"

  if command -v base64 >/dev/null 2>&1; then
    base64 -w0 "$IMPORT_FILE" > "$SUB_FILE" 2>/dev/null || base64 "$IMPORT_FILE" > "$SUB_FILE" 2>/dev/null || true
  fi

  cp -f "$IMPORT_FILE" "${APP_DIR}/pooyan-v2rayn-import.txt" 2>/dev/null || true
  cp -f "$LINK_FILE" "${APP_DIR}/v2ray.txt" 2>/dev/null || true
}

save_state() {
  local uuid="$1" ip="$2" port="$3" path="$4" try_host="${5:-}" hy2_password="${6:-}" hy2_obfs="${7:-}" hy2_ok="${8:-0}"
  mkdir -p "$APP_DIR"
  cat > "$STATE_FILE" <<EOF
PROJECT_VERSION='${PROJECT_VERSION}'
UUID='${uuid}'
SERVER_IP='${ip}'
LOCAL_PORT='${port}'
WS_PATH='${path}'
TRY_HOST='${try_host}'
CF_FRONT_DOMAIN='${CF_FRONT_DOMAIN}'
HYSTERIA_PORT='${HYSTERIA_PORT}'
HYSTERIA_SNI='${HYSTERIA_SNI}'
HYSTERIA_PASSWORD='${hy2_password}'
HYSTERIA_OBFS='${hy2_obfs}'
HYSTERIA_OK='${hy2_ok}'
EOF
  chmod 600 "$STATE_FILE" 2>/dev/null || true
}

install_racknerd_strong() {
  banner
  cyan "RackNerd Strong Mode: TRY-TLS-443 + CF-443 + CF-80 + HY2-443 + Direct IP"
  echo "This mode stays clean: maximum 5 links."
  echo

  local uuid path port ip try_host hy2_password hy2_obfs hy2_ok
  install_pkgs
  install_xray
  install_cloudflared
  install_self_manager
  enable_network_tuning

  uuid="$(random_uuid)"
  path="$(random_path)"
  port="$(random_port)"
  ip="$(public_ip | tr -d '\n' | tr -d ' ')"
  [ -n "$ip" ] || ip="YOUR_SERVER_IP"

  write_xray_config "$uuid" "$port" "$path"
  open_firewall_port "$port" tcp
  start_xray
  sleep 2

  hy2_ok="0"
  hy2_password="$(random_secret)"
  hy2_obfs="$(random_secret)"
  if install_hysteria2; then
    if write_hysteria_config "$hy2_password" "$hy2_obfs"; then
      open_firewall_port "$HYSTERIA_PORT" udp
      if start_hysteria2; then
        hy2_ok="1"
        green "Hysteria2 ready on UDP ${HYSTERIA_PORT}."
      fi
    fi
  fi

  try_host=""
  if try_host="$(get_trycloudflare_host "$port")" && [ -n "$try_host" ]; then
    green "TryCloudflare created: ${try_host}"
  else
    red "Could not get trycloudflare.com URL. Direct IP/HY2 links will still be generated."
    yellow "Check log: cat ${ARGO_LOG}"
    try_host=""
  fi

  write_links "$uuid" "$ip" "$port" "$path" "$try_host" "$hy2_password" "$hy2_obfs" "$hy2_ok"
  save_state "$uuid" "$ip" "$port" "$path" "$try_host" "$hy2_password" "$hy2_obfs" "$hy2_ok"

  green "Done. / آماده شد."
  echo
  yellow "Important: for HY2, RackNerd/firewall panel must allow UDP ${HYSTERIA_PORT}."
  echo
  cyan "Use this for v2rayN import:"
  echo "cat ${IMPORT_FILE}"
  echo
  cat "$LINK_FILE"
}

show_links() {
  if [ -f "$LINK_FILE" ]; then cat "$LINK_FILE"; else red "No links found. Run: pooyan renew"; fi
}

main_menu() {
  banner
  echo "1) Build RackNerd strong 5 links only  (recommended)"
  echo "2) Show links"
  echo "3) Show v2rayN import links"
  echo "4) Test local services"
  echo "5) Status"
  echo "6) Logs"
  echo "0) Exit"
  echo
  read -r -p "Select [1]: " c || true
  c="${c:-1}"
  case "$c" in
    1) install_racknerd_strong ;;
    2) show_links ;;
    3) [ -f "$IMPORT_FILE" ] && cat "$IMPORT_FILE" || red "No import file." ;;
    4) "$APP_CMD" test 2>/dev/null || true ;;
    5) "$APP_CMD" status 2>/dev/null || true ;;
    6) "$APP_CMD" logs 2>/dev/null || true ;;
    0) exit 0 ;;
    *) red "Invalid choice"; exit 1 ;;
  esac
}

need_root
if [ "${1:-}" = "install" ] || [ "${1:-}" = "racknerd" ]; then
  install_racknerd_strong
else
  main_menu
fi
