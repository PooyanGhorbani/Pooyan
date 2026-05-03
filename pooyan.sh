#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_NAME="Pooyan"
PROJECT_VERSION="0.10"
APP_TITLE="${PROJECT_NAME} ${PROJECT_VERSION}"
APP_DIR="/opt/pooyan"
APP_CMD="/usr/bin/pooyan"
XRAY_BIN="${APP_DIR}/xray"
CLOUDFLARED_BIN="${APP_DIR}/cloudflared"
LINK_FILE="${APP_DIR}/v2ray.txt"
ROOT_LINK_FILE="/root/v2ray.txt"

CF_DEFAULT_ADDRESS="cloudflare.182682.xyz"
CF_HTTPS_PORTS="443 2053 2083 2087 2096 8443"
CF_HTTP_PORTS="80 8080 8880 2052 2082 2086 2095"

red(){ printf '\033[31m%s\033[0m\n' "$*"; }
green(){ printf '\033[32m%s\033[0m\n' "$*"; }
yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }
blue(){ printf '\033[36m%s\033[0m\n' "$*"; }
line(){ printf '%*s\n' 54 '' | tr ' ' '='; }

need_root(){
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    red "Please run as root. / 请使用 root 运行 / لطفاً با root اجرا کن."
    exit 1
  fi
}

pause(){ read -r -p "Press Enter to continue..." _ || true; }

banner(){
  clear || true
  line
  printf "%28s\n" "${APP_TITLE}"
  printf "%38s\n" "Auto Domain + Direct IP Edition"
  line
  echo
}

get_os_family(){
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "${ID:-}" in
      debian|ubuntu) echo "debian" ;;
      centos|rhel|rocky|almalinux|fedora) echo "rhel" ;;
      alpine) echo "alpine" ;;
      *)
        case "${ID_LIKE:-}" in
          *debian*) echo "debian" ;;
          *rhel*|*fedora*) echo "rhel" ;;
          *) echo "unknown" ;;
        esac
        ;;
    esac
  else
    echo "unknown"
  fi
}

pkg_install(){
  local family="$1"; shift
  case "$family" in
    debian)
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -y
      apt-get install -y "$@"
      ;;
    rhel)
      if command -v dnf >/dev/null 2>&1; then
        dnf install -y "$@"
      else
        yum install -y "$@"
      fi
      ;;
    alpine)
      apk update
      apk add --no-cache "$@"
      ;;
    *)
      red "Unsupported OS. Please use Debian 12/Ubuntu 22.04+ for best result."
      exit 1
      ;;
  esac
}

ensure_deps(){
  local family
  family="$(get_os_family)"
  local missing=()
  for cmd in curl unzip openssl; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    yellow "Installing dependencies: ${missing[*]}"
    case "$family" in
      debian) pkg_install "$family" curl unzip openssl ca-certificates ;;
      rhel) pkg_install "$family" curl unzip openssl ca-certificates ;;
      alpine) pkg_install "$family" curl unzip openssl ca-certificates bash ;;
      *) pkg_install "$family" "${missing[@]}" ;;
    esac
  fi
}

detect_arch(){
  case "$(uname -m)" in
    x86_64|amd64) echo "amd64" ;;
    aarch64|arm64|armv8*) echo "arm64" ;;
    i386|i686) echo "386" ;;
    armv7l|armv7*) echo "armv7" ;;
    *) red "Unsupported architecture: $(uname -m)"; exit 1 ;;
  esac
}

xray_url(){
  case "$(detect_arch)" in
    amd64) echo "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip" ;;
    386) echo "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-32.zip" ;;
    arm64) echo "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-arm64-v8a.zip" ;;
    armv7) echo "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-arm32-v7a.zip" ;;
  esac
}

cloudflared_url(){
  case "$(detect_arch)" in
    amd64) echo "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64" ;;
    386) echo "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386" ;;
    arm64) echo "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64" ;;
    armv7) echo "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm" ;;
  esac
}

install_binaries(){
  mkdir -p "$APP_DIR"
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  if [ ! -x "$XRAY_BIN" ]; then
    yellow "Downloading latest Xray-core..."
    curl -fL --retry 3 "$(xray_url)" -o "$tmp/xray.zip"
    unzip -o "$tmp/xray.zip" -d "$tmp/xray" >/dev/null
    install -m 0755 "$tmp/xray/xray" "$XRAY_BIN"
  fi

  if [ ! -x "$CLOUDFLARED_BIN" ]; then
    yellow "Downloading latest cloudflared..."
    curl -fL --retry 3 "$(cloudflared_url)" -o "$CLOUDFLARED_BIN"
    chmod +x "$CLOUDFLARED_BIN"
  fi
}

random_uuid(){
  if [ -r /proc/sys/kernel/random/uuid ]; then
    cat /proc/sys/kernel/random/uuid
  else
    openssl rand -hex 16 | sed 's/^\(.\{8\}\)\(.\{4\}\)\(.\{4\}\)\(.\{4\}\)\(.\{12\}\)$/\1-\2-\3-\4-\5/'
  fi
}

random_path(){
  openssl rand -hex 8
}

random_port(){
  echo $((20000 + RANDOM % 30000))
}

public_ip(){
  curl -4fsS --max-time 6 https://api.ipify.org 2>/dev/null \
    || curl -4fsS --max-time 6 https://ifconfig.me 2>/dev/null \
    || curl -4fsS --max-time 6 https://icanhazip.com 2>/dev/null \
    || hostname -I 2>/dev/null | awk '{print $1}' \
    || echo "YOUR_SERVER_IP"
}

url_encode_label(){
  printf '%s' "$1" | sed -e 's/ /%20/g' -e 's/,/%2C/g' -e 's/#/%23/g' -e 's/:/%3A/g'
}

enable_bbr(){
  yellow "Trying to enable BBR..."
  modprobe tcp_bbr >/dev/null 2>&1 || true
  cat > /etc/sysctl.d/99-pooyan-bbr.conf <<'BBR'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
BBR
  sysctl --system >/dev/null 2>&1 || sysctl -p /etc/sysctl.d/99-pooyan-bbr.conf >/dev/null 2>&1 || true
  local current
  current="$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || true)"
  if [ "$current" = "bbr" ]; then
    green "BBR: enabled"
  else
    yellow "BBR was requested, but kernel reports: ${current:-unknown}"
  fi
}

write_systemd_service(){
  local name="$1" exec_cmd="$2" desc="$3"
  cat > "/etc/systemd/system/${name}.service" <<EOF_SERVICE
[Unit]
Description=${desc}
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${exec_cmd}
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF_SERVICE
}

reload_systemd(){
  if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload
  fi
}

start_enable_service(){
  local svc="$1"
  if command -v systemctl >/dev/null 2>&1; then
    systemctl enable "$svc" >/dev/null 2>&1 || true
    systemctl restart "$svc" || true
  fi
}

stop_disable_service(){
  local svc="$1"
  if command -v systemctl >/dev/null 2>&1; then
    systemctl stop "$svc" >/dev/null 2>&1 || true
    systemctl disable "$svc" >/dev/null 2>&1 || true
  fi
}

ask_default(){
  local prompt="$1" default="$2" value
  read -r -p "$prompt [$default]: " value || true
  printf '%s' "${value:-$default}"
}

validate_domain(){
  printf '%s' "$1" | grep -Eq '^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$'
}


xray_check_config(){
  local config="$1"
  # Newer Xray-core uses: xray run -test -config file
  if "$XRAY_BIN" run -test -config "$config" >/tmp/pooyan-xray-test.log 2>&1; then
    return 0
  fi
  # Compatibility fallback for older builds/wrappers
  if "$XRAY_BIN" test -config "$config" >/tmp/pooyan-xray-test.log 2>&1; then
    return 0
  fi
  red "Xray config test failed. Last output:"
  cat /tmp/pooyan-xray-test.log 2>/dev/null || true
  exit 1
}

make_vless_ws_config(){
  local uuid="$1" port="$2" path="$3" listen_addr="${4:-127.0.0.1}"
  cat > "${APP_DIR}/config.json" <<EOF_JSON
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "${listen_addr}",
      "port": ${port},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "level": 0
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/${path}"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
EOF_JSON
}

write_ws_links(){
  local uuid="$1" domain="$2" path="$3" label_prefix="$4"
  mkdir -p "$APP_DIR"
  : > "$LINK_FILE"
  {
    echo "Pooyan ${PROJECT_VERSION} - VLESS WS Cloudflare / Auto Domain"
    echo "UUID: ${uuid}"
    echo "Host/SNI: ${domain}"
    echo "WS Path: /${path}"
    echo
    echo "Standard links - address is your Cloudflare domain:"
    for p in $CF_HTTPS_PORTS; do
      echo "vless://${uuid}@${domain}:${p}?encryption=none&security=tls&type=ws&host=${domain}&path=/${path}#$(url_encode_label "${label_prefix}-TLS-${p}")"
    done
    echo
    for p in $CF_HTTP_PORTS; do
      echo "vless://${uuid}@${domain}:${p}?encryption=none&security=none&type=ws&host=${domain}&path=/${path}#$(url_encode_label "${label_prefix}-HTTP-${p}")"
    done
    echo
    echo "CF Preferred IP style - replace ${CF_DEFAULT_ADDRESS} with a faster Cloudflare preferred IP/domain if you test one:"
    for p in $CF_HTTPS_PORTS; do
      echo "vless://${uuid}@${CF_DEFAULT_ADDRESS}:${p}?encryption=none&security=tls&type=ws&host=${domain}&path=/${path}#$(url_encode_label "${label_prefix}-CFIP-TLS-${p}")"
    done
    echo
    echo "Tip: For China, test 443, 2053, 2083, 8443 first. Keep the fastest stable one."
  } >> "$LINK_FILE"
  cp -f "$LINK_FILE" "$ROOT_LINK_FILE" 2>/dev/null || true
}


open_firewall_port_best_effort(){
  local port="$1"
  yellow "Trying to open TCP port ${port} locally if a firewall is active..."
  if command -v ufw >/dev/null 2>&1; then
    ufw allow "${port}/tcp" >/dev/null 2>&1 || true
  fi
  if command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --permanent --add-port="${port}/tcp" >/dev/null 2>&1 || true
    firewall-cmd --reload >/dev/null 2>&1 || true
  fi
  if command -v iptables >/dev/null 2>&1; then
    iptables -C INPUT -p tcp --dport "${port}" -j ACCEPT >/dev/null 2>&1 || iptables -I INPUT -p tcp --dport "${port}" -j ACCEPT >/dev/null 2>&1 || true
  fi
}

append_direct_ip_links(){
  local uuid="$1" server_ip="$2" port="$3" path="$4" label_prefix="$5"
  {
    echo
    echo "Direct IP link - NO domain / بدون دامنه"
    echo "Use this only for quick speed test. It is faster/simple, but usually less stable for China than Cloudflare/Reality."
    echo "If it cannot connect, open TCP port ${port} in the VPS provider security group/firewall."
    echo "vless://${uuid}@${server_ip}:${port}?encryption=none&security=none&type=ws&path=/${path}#$(url_encode_label "${label_prefix}-DIRECT-IP-${port}")"
  } >> "$LINK_FILE"
  cp -f "$LINK_FILE" "$ROOT_LINK_FILE" 2>/dev/null || true
}

cloudflared_login_if_needed(){
  mkdir -p /root/.cloudflared
  if ls /root/.cloudflared/cert.pem >/dev/null 2>&1; then
    green "Cloudflare login already exists: /root/.cloudflared/cert.pem"
    return 0
  fi
  yellow "Cloudflare login is needed. A browser authorization URL will appear."
  "$CLOUDFLARED_BIN" tunnel login
}

make_tunnel_name(){
  printf '%s' "$1" | awk -F. '{print $1}' | tr -cd 'A-Za-z0-9_-'
}

setup_vless_cloudflare_service(){
  banner
  blue "Custom Domain Mode: VLESS + WS + Cloudflare Tunnel + service + BBR"
  echo
  local domain uuid path port tunnel_name tunnel_id label
  domain="$(ask_default "Full Cloudflare subdomain / دامنه کامل Cloudflare" "vpn.example.com")"
  if ! validate_domain "$domain"; then
    red "Invalid domain: $domain"
    exit 1
  fi
  uuid="$(random_uuid)"
  path="$(random_path)"
  port="$(random_port)"
  tunnel_name="$(make_tunnel_name "$domain")"
  label="Pooyan-China"

  ensure_deps
  install_binaries
  enable_bbr
  make_vless_ws_config "$uuid" "$port" "$path"

  xray_check_config "${APP_DIR}/config.json"

  cloudflared_login_if_needed
  yellow "Creating or reusing Cloudflare tunnel: ${tunnel_name}"
  if ! "$CLOUDFLARED_BIN" tunnel list 2>/dev/null | awk '{print $2}' | grep -qx "$tunnel_name"; then
    "$CLOUDFLARED_BIN" tunnel create "$tunnel_name"
  fi
  "$CLOUDFLARED_BIN" tunnel route dns --overwrite-dns "$tunnel_name" "$domain" || true

  tunnel_id="$($CLOUDFLARED_BIN tunnel list 2>/dev/null | awk -v n="$tunnel_name" '$2==n {print $1; exit}')"
  if [ -z "${tunnel_id:-}" ]; then
    red "Could not read Cloudflare tunnel UUID. Run: cloudflared tunnel list"
    exit 1
  fi

  cat > "${APP_DIR}/cloudflared.yml" <<EOF_YAML
tunnel: ${tunnel_id}
credentials-file: /root/.cloudflared/${tunnel_id}.json
protocol: http2
edge-ip-version: 4
ingress:
  - hostname: ${domain}
    service: http://127.0.0.1:${port}
  - service: http_status:404
EOF_YAML

  write_systemd_service "xray" "${XRAY_BIN} run -config ${APP_DIR}/config.json" "Pooyan Xray Service"
  write_systemd_service "cloudflared" "${CLOUDFLARED_BIN} tunnel --config ${APP_DIR}/cloudflared.yml run" "Pooyan Cloudflare Tunnel"
  write_manager
  reload_systemd
  start_enable_service xray
  start_enable_service cloudflared
  write_ws_links "$uuid" "$domain" "$path" "$label"

  green "Done. Links saved to ${LINK_FILE} and ${ROOT_LINK_FILE}"
  echo
  cat "$LINK_FILE"
}

quick_tunnel(){
  banner
  blue "Auto Domain Mode: VLESS + WS + trycloudflare.com"
  yellow "No Cloudflare account/domain is needed. The trycloudflare.com address is generated automatically."
  yellow "Note: this automatic address can change after reboot/rerun. For a fixed address, use Custom Domain mode."
  echo
  local uuid path port argo n label
  uuid="$(random_uuid)"
  path="$(random_path)"
  port="$(random_port)"
  label="Pooyan-Quick"

  ensure_deps
  install_binaries
  make_vless_ws_config "$uuid" "$port" "$path" "0.0.0.0"
  xray_check_config "${APP_DIR}/config.json"
  open_firewall_port_best_effort "$port"

  stop_disable_service cloudflared
  stop_disable_service xray
  pkill -f "${XRAY_BIN}" >/dev/null 2>&1 || true
  pkill -f "${CLOUDFLARED_BIN}" >/dev/null 2>&1 || true
  nohup "$XRAY_BIN" run -config "${APP_DIR}/config.json" >/tmp/pooyan-xray.log 2>&1 &
  nohup "$CLOUDFLARED_BIN" tunnel --url "http://127.0.0.1:${port}" --no-autoupdate --edge-ip-version 4 --protocol http2 >/tmp/pooyan-argo.log 2>&1 &

  argo=""
  for n in $(seq 1 30); do
    argo="$(grep -oE 'https://[-a-zA-Z0-9.]+\.trycloudflare\.com' /tmp/pooyan-argo.log 2>/dev/null | head -n1 | sed 's#https://##' || true)"
    [ -n "$argo" ] && break
    sleep 1
  done
  if [ -z "$argo" ]; then
    red "Could not get trycloudflare.com URL. Check /tmp/pooyan-argo.log"
    exit 1
  fi
  write_ws_links "$uuid" "$argo" "$path" "$label"
  server_ip="$(public_ip | tr -d '\n' | tr -d ' ')"
  append_direct_ip_links "$uuid" "$server_ip" "$port" "$path" "$label"
  green "Quick tunnel created: ${argo}"
  green "Direct IP test link was also generated: ${server_ip}:${port}"
  cat "$LINK_FILE"
}

reality_keys(){
  local out private public
  out="$($XRAY_BIN x25519 2>/dev/null || true)"
  private="$(printf '%s\n' "$out" | awk -F': ' '/Private key/ {print $2}')"
  public="$(printf '%s\n' "$out" | awk -F': ' '/Public key/ {print $2}')"
  if [ -z "$private" ] || [ -z "$public" ]; then
    red "Could not generate Reality x25519 keys. Is Xray installed correctly?"
    exit 1
  fi
  printf '%s\n%s\n' "$private" "$public"
}

setup_reality_vision(){
  banner
  blue "Advanced: VLESS + REALITY + Vision direct"
  yellow "Use this only on a good CN2/CMI/AS9929 VPS, not through Cloudflare Tunnel."
  echo
  local uuid port sni dest sid private public server_ip label
  uuid="$(random_uuid)"
  port="$(ask_default "Reality port" "443")"
  sni="$(ask_default "Reality SNI/serverName" "www.microsoft.com")"
  dest="$(ask_default "Reality dest" "${sni}:443")"
  sid="$(openssl rand -hex 4)"
  label="Pooyan-Reality"

  ensure_deps
  install_binaries
  enable_bbr
  mapfile -t keys < <(reality_keys)
  private="${keys[0]}"
  public="${keys[1]}"

  cat > "${APP_DIR}/config.json" <<EOF_JSON
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": ${port},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "${dest}",
          "xver": 0,
          "serverNames": ["${sni}"],
          "privateKey": "${private}",
          "shortIds": ["${sid}"]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
EOF_JSON
  xray_check_config "${APP_DIR}/config.json"

  write_systemd_service "xray" "${XRAY_BIN} run -config ${APP_DIR}/config.json" "Pooyan Xray Reality Service"
  rm -f /etc/systemd/system/cloudflared.service
  write_manager
  reload_systemd
  stop_disable_service cloudflared
  start_enable_service xray

  server_ip="$(public_ip | tr -d '\n' | tr -d ' ')"
  mkdir -p "$APP_DIR"
  cat > "$LINK_FILE" <<EOF_LINK
Pooyan ${PROJECT_VERSION} - VLESS REALITY Vision Direct
Server IP: ${server_ip}
Port: ${port}
UUID: ${uuid}
SNI: ${sni}
PublicKey: ${public}
ShortID: ${sid}

vless://${uuid}@${server_ip}:${port}?encryption=none&security=reality&sni=${sni}&fp=chrome&pbk=${public}&sid=${sid}&type=tcp&flow=xtls-rprx-vision#$(url_encode_label "${label}")
EOF_LINK
  cp -f "$LINK_FILE" "$ROOT_LINK_FILE" 2>/dev/null || true
  green "Done. Reality link saved to ${LINK_FILE} and ${ROOT_LINK_FILE}"
  echo
  cat "$LINK_FILE"
}

write_manager(){
  cat > "$APP_CMD" <<'EOF_MANAGER'
#!/usr/bin/env bash
set -Eeuo pipefail
APP_DIR="/opt/pooyan"
LINK_FILE="${APP_DIR}/v2ray.txt"
status_one(){
  local svc="$1"
  if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files "${svc}.service" >/dev/null 2>&1; then
    printf '%-12s %s\n' "$svc" "$(systemctl is-active "$svc" 2>/dev/null || echo missing)"
  else
    printf '%-12s missing\n' "$svc"
  fi
}
while true; do
  clear || true
  echo "Pooyan Manager"
  echo "=============================="
  status_one xray
  status_one cloudflared
  echo
  echo "1) Start services"
  echo "2) Stop services"
  echo "3) Restart services"
  echo "4) Show links"
  echo "5) Show logs"
  echo "6) Uninstall Pooyan"
  echo "0) Exit"
  echo
  read -r -p "Choose [0]: " c || true
  c="${c:-0}"
  case "$c" in
    1)
      systemctl start xray 2>/dev/null || true
      systemctl start cloudflared 2>/dev/null || true
      ;;
    2)
      systemctl stop cloudflared 2>/dev/null || true
      systemctl stop xray 2>/dev/null || true
      ;;
    3)
      systemctl restart xray 2>/dev/null || true
      systemctl restart cloudflared 2>/dev/null || true
      ;;
    4)
      clear || true
      if [ -f "$LINK_FILE" ]; then cat "$LINK_FILE"; else echo "No link file: $LINK_FILE"; fi
      read -r -p "Enter to continue..." _ || true
      ;;
    5)
      clear || true
      journalctl -u xray -u cloudflared --no-pager -n 80 2>/dev/null || true
      read -r -p "Enter to continue..." _ || true
      ;;
    6)
      systemctl stop cloudflared xray 2>/dev/null || true
      systemctl disable cloudflared xray 2>/dev/null || true
      rm -f /etc/systemd/system/cloudflared.service /etc/systemd/system/xray.service /usr/bin/pooyan
      rm -rf /opt/pooyan
      systemctl daemon-reload 2>/dev/null || true
      echo "Removed. Cloudflare auth files in /root/.cloudflared were kept intentionally."
      exit 0
      ;;
    0) exit 0 ;;
  esac
done
EOF_MANAGER
  chmod +x "$APP_CMD"
}

uninstall_pooyan(){
  banner
  yellow "Removing Pooyan services and files..."
  stop_disable_service cloudflared
  stop_disable_service xray
  rm -f /etc/systemd/system/cloudflared.service /etc/systemd/system/xray.service "$APP_CMD"
  rm -rf "$APP_DIR"
  reload_systemd
  green "Removed. /root/.cloudflared was kept, so your Cloudflare login is not deleted."
}

show_links(){
  if [ -f "$LINK_FILE" ]; then
    cat "$LINK_FILE"
  elif [ -f "$ROOT_LINK_FILE" ]; then
    cat "$ROOT_LINK_FILE"
  else
    red "No links found. Install first."
  fi
}

main_menu(){
  banner
  echo "1) Quick Mode - Auto trycloudflare.com + Direct IP link  (بدون دامنه اختیاری)"
  echo "2) Custom Domain - VLESS + Cloudflare Tunnel + service + BBR"
  echo "3) Advanced - VLESS + REALITY + Vision direct"
  echo "4) Show current links"
  echo "5) Manager menu"
  echo "6) Uninstall"
  echo "0) Exit"
  echo
  echo "建议中国用户：先选 1，不需要域名；如果你有 Cloudflare 域名，再选 2。"
  echo "پیشنهاد برای چین: اول گزینه 1؛ لینک trycloudflare می‌دهد و یک لینک Direct IP بدون دامنه هم برای تست سرعت می‌سازد."
  echo
  read -r -p "Select [1]: " choice || true
  choice="${choice:-1}"
  case "$choice" in
    1) quick_tunnel ;;
    2) setup_vless_cloudflare_service ;;
    3) setup_reality_vision ;;
    4) show_links ;;
    5) if [ -x "$APP_CMD" ]; then "$APP_CMD"; else red "Manager is not installed yet."; fi ;;
    6) uninstall_pooyan ;;
    0) exit 0 ;;
    *) red "Invalid choice"; exit 1 ;;
  esac
}

need_root
main_menu "$@"
