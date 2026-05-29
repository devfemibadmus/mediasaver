#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${APP_NAME:?APP_NAME is required}"
APP_DOMAIN="${APP_DOMAIN:?APP_DOMAIN is required}"
APP_PORT="${APP_PORT:?APP_PORT is required}"
APP_ENV_FILE="${APP_ENV_FILE:-}"
APP_ENV_FILE_PATH="${APP_ENV_FILE_PATH:-}"
APP_BINARY_PATH="${APP_BINARY_PATH:-/tmp/${APP_NAME}}"
APP_HOST="${APP_HOST:-127.0.0.1}"
CERTBOT_EMAIL="${CERTBOT_EMAIL:-admin@${APP_DOMAIN}}"
DEPLOY_MODE="${DEPLOY_MODE:-deploy}"

SERVICE_NAME="${APP_NAME//[^a-zA-Z0-9_-]/-}"
APP_ROOT="/opt/${SERVICE_NAME}"
BIN_PATH="${APP_ROOT}/${SERVICE_NAME}"
ENV_DIR="/etc/${SERVICE_NAME}"
ENV_PATH="${ENV_DIR}/${SERVICE_NAME}.env"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
NGINX_AVAILABLE="/etc/nginx/sites-available/${SERVICE_NAME}.conf"
NGINX_ENABLED="/etc/nginx/sites-enabled/${SERVICE_NAME}.conf"

APT_UPDATED=0

ensure_apt_updated() {
  if [ "$APT_UPDATED" -eq 0 ]; then
    sudo apt-get update
    APT_UPDATED=1
  fi
}

ensure_package() {
  local command_name="$1"
  local package_name="$2"

  if command -v "$command_name" >/dev/null 2>&1; then
    echo "  - $command_name already installed"
    return
  fi

  ensure_apt_updated
  echo "  - Installing $package_name"
  sudo apt-get install -y "$package_name"
}

print_vm_info() {
  echo "VM info"
  echo "  - Hostname: $(hostname)"
  echo "  - Kernel: $(uname -srmo)"
  echo "  - Uptime: $(uptime -p 2>/dev/null || uptime)"

  awk '
    /^MemTotal:/ { total=$2 }
    /^MemAvailable:/ { available=$2 }
    END {
      if (total > 0) {
        used = total - available
        used_percent = used * 100 / total
        free_percent = available * 100 / total
        printf "  - Memory: %.2f GiB used / %.2f GiB total (%.1f%% used, %.1f%% left)\n", used / 1048576, total / 1048576, used_percent, free_percent
      }
    }
  ' /proc/meminfo

  df -h / | awk 'NR == 2 {
    gsub("%", "", $5)
    printf "  - Disk /: %s used / %s total (%s%% used, %s%% left)\n", $3, $2, $5, 100 - $5
  }'
}

ensure_firewall() {
  ensure_package ufw ufw

  local existing_ports
  existing_ports="$(ss -H -tuln 2>/dev/null | awk '
    {
      proto=$1
      local_addr=$5
      sub(/.*:/, "", local_addr)
      if (local_addr ~ /^[0-9]+$/) {
        if (proto ~ /^tcp/) print local_addr "/tcp"
        if (proto ~ /^udp/) print local_addr "/udp"
      }
    }
  ' | sort -u)"

  if [ -n "$existing_ports" ]; then
    echo "  - Preserving currently listening VM ports"
    while IFS= read -r port_rule; do
      sudo ufw allow "$port_rule" >/dev/null || true
    done <<EOF
$existing_ports
EOF
  fi

  sudo ufw allow OpenSSH >/dev/null || true
  sudo ufw allow 80/tcp >/dev/null || true
  sudo ufw allow 443/tcp >/dev/null || true

  if [ "$APP_HOST" != "127.0.0.1" ] && [ "$APP_HOST" != "localhost" ]; then
    sudo ufw allow "${APP_PORT}/tcp" >/dev/null || true
  fi

  if sudo ufw status | grep -qi "Status: active"; then
    echo "  - UFW already active; rules updated"
    return
  fi

  echo "  - UFW is installed and rules are added, but UFW was not active so it was not enabled."
}

ensure_nginx_and_certbot() {
  ensure_package nginx nginx
  ensure_package certbot certbot
  ensure_package openssl openssl

  sudo systemctl enable nginx >/dev/null
  sudo systemctl start nginx
}

ensure_domain_is_available() {
  local matches
  matches="$(sudo grep -RslE "server_name[[:space:]].*(${APP_DOMAIN})([[:space:];]|$)" /etc/nginx/sites-enabled /etc/nginx/conf.d 2>/dev/null || true)"

  if [ -z "$matches" ]; then
    return
  fi

  if printf '%s\n' "$matches" | grep -vxF "$NGINX_ENABLED" >/dev/null; then
    echo "Another nginx config already uses ${APP_DOMAIN}:"
    printf '%s\n' "$matches" | grep -vxF "$NGINX_ENABLED" || true
    echo "Refusing to continue so this deployment does not interrupt another app."
    exit 1
  fi
}

write_nginx_config() {
  local cert_path="/etc/letsencrypt/live/${APP_DOMAIN}/fullchain.pem"
  local key_path="/etc/letsencrypt/live/${APP_DOMAIN}/privkey.pem"

  if sudo test -f "$cert_path" && sudo test -f "$key_path"; then
    sudo tee "$NGINX_AVAILABLE" >/dev/null <<EOF
server {
    listen 80;
    server_name ${APP_DOMAIN};

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name ${APP_DOMAIN};

    ssl_certificate ${cert_path};
    ssl_certificate_key ${key_path};

    location / {
        proxy_pass http://${APP_HOST}:${APP_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
  else
    sudo tee "$NGINX_AVAILABLE" >/dev/null <<EOF
server {
    listen 80;
    server_name ${APP_DOMAIN};

    location / {
        proxy_pass http://${APP_HOST}:${APP_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
  fi

  sudo ln -sfn "$NGINX_AVAILABLE" "$NGINX_ENABLED"
  sudo nginx -t
  sudo systemctl reload nginx
}

port_80_owner() {
  sudo ss -H -ltnp "sport = :80" 2>/dev/null || true
}

restart_nginx_after_certbot() {
  sudo systemctl start nginx
}

run_standalone_certbot() {
  local action="$1"

  local owner
  owner="$(port_80_owner)"

  if [ -n "$owner" ] && ! printf '%s\n' "$owner" | grep -qi 'nginx'; then
    echo "Port 80 is used by a non-nginx process:"
    printf '%s\n' "$owner"
    echo "Refusing to stop it so this deployment does not interrupt another app."
    exit 1
  fi

  echo "  - ${action} standalone SSL certificate for ${APP_DOMAIN}"
  sudo systemctl stop nginx || true
  trap restart_nginx_after_certbot EXIT
  sudo certbot certonly \
    --standalone \
    --non-interactive \
    --agree-tos \
    --email "${CERTBOT_EMAIL}" \
    --cert-name "${APP_DOMAIN}" \
    -d "${APP_DOMAIN}"
  trap - EXIT
  restart_nginx_after_certbot
}

ensure_standalone_certificate() {
  local cert_path="/etc/letsencrypt/live/${APP_DOMAIN}/fullchain.pem"
  local renew_window_seconds=2592000

  if sudo test -f "$cert_path" && sudo openssl x509 -checkend "$renew_window_seconds" -noout -in "$cert_path" >/dev/null 2>&1; then
    echo "  - SSL certificate for ${APP_DOMAIN} is valid for more than 30 days"
    return
  fi

  if sudo test -f "$cert_path"; then
    run_standalone_certbot "Renewing"
  else
    run_standalone_certbot "Requesting"
  fi
}

install_binary() {
  if [ ! -f "$APP_BINARY_PATH" ]; then
    echo "Binary not found at ${APP_BINARY_PATH}"
    exit 1
  fi

  sudo mkdir -p "$APP_ROOT"
  sudo install -m 755 "$APP_BINARY_PATH" "$BIN_PATH"
}

write_env_file() {
  sudo mkdir -p "$ENV_DIR"
  {
    echo "APP_NAME=${APP_NAME}"
    echo "APP_DOMAIN=${APP_DOMAIN}"
    echo "APP_HOST=${APP_HOST}"
    echo "APP_PORT=${APP_PORT}"
    if [ -n "$APP_ENV_FILE_PATH" ] && [ -f "$APP_ENV_FILE_PATH" ]; then
      cat "$APP_ENV_FILE_PATH"
    fi
    if [ -n "$APP_ENV_FILE" ]; then
      printf '%s\n' "$APP_ENV_FILE"
    fi
  } | sudo tee "$ENV_PATH" >/dev/null
  sudo chmod 600 "$ENV_PATH"
}

write_systemd_service() {
  sudo tee "$SERVICE_PATH" >/dev/null <<EOF
[Unit]
Description=${APP_NAME}
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${APP_ROOT}
EnvironmentFile=${ENV_PATH}
ExecStart=${BIN_PATH}
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable "${SERVICE_NAME}.service" >/dev/null
}

wait_for_service() {
  for _ in {1..20}; do
    if curl -fsS "http://${APP_HOST}:${APP_PORT}/" >/dev/null 2>&1; then
      return
    fi
    sleep 1
  done

  echo "Service did not respond on http://${APP_HOST}:${APP_PORT}/"
  sudo systemctl --no-pager --full status "${SERVICE_NAME}.service" || true
  exit 1
}

echo "[1/10] VM information"
print_vm_info

echo "[2/10] Checking VM packages and firewall"
ensure_firewall

echo "[3/10] Checking nginx and certbot"
ensure_nginx_and_certbot

echo "[4/10] Checking nginx domain ownership"
ensure_domain_is_available

echo "[5/10] Checking standalone SSL certificate"
ensure_standalone_certificate

echo "[6/10] Writing app-scoped nginx config"
write_nginx_config

if [ "$DEPLOY_MODE" = "requirements" ]; then
  echo "Server requirements are satisfied."
  exit 0
fi

echo "[7/10] Installing binary"
install_binary

echo "[8/10] Writing environment"
write_env_file

echo "[9/10] Writing systemd service"
write_systemd_service

echo "[10/10] Restarting and verifying service"
sudo systemctl restart "${SERVICE_NAME}.service"
wait_for_service
sudo systemctl --no-pager --full status "${SERVICE_NAME}.service" | sed -n '1,14p'
