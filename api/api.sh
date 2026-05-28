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
ENABLE_UFW="${ENABLE_UFW:-false}"

SERVICE_NAME="${APP_NAME//[^a-zA-Z0-9_-]/-}"
APP_ROOT="/opt/${SERVICE_NAME}"
BIN_PATH="${APP_ROOT}/${SERVICE_NAME}"
ENV_DIR="/etc/${SERVICE_NAME}"
ENV_PATH="${ENV_DIR}/${SERVICE_NAME}.env"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
ACME_ROOT="/var/www/${SERVICE_NAME}"
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

  if [ "$ENABLE_UFW" = "true" ]; then
    sudo ufw --force enable >/dev/null
    echo "  - UFW enabled"
  else
    echo "  - UFW is installed and rules are added, but not enabled. Set ENABLE_UFW=true to enable it on a new VM."
  fi
}

ensure_nginx_and_certbot() {
  ensure_package nginx nginx
  ensure_package certbot certbot

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

  sudo mkdir -p "${ACME_ROOT}/.well-known/acme-challenge"

  if sudo test -f "$cert_path" && sudo test -f "$key_path"; then
    sudo tee "$NGINX_AVAILABLE" >/dev/null <<EOF
server {
    listen 80;
    server_name ${APP_DOMAIN};

    location /.well-known/acme-challenge/ {
        root ${ACME_ROOT};
    }

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

    location /.well-known/acme-challenge/ {
        root ${ACME_ROOT};
    }

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

ensure_webroot_certificate() {
  if sudo test -f "/etc/letsencrypt/live/${APP_DOMAIN}/fullchain.pem"; then
    echo "  - SSL certificate already exists for ${APP_DOMAIN}"
    return
  fi

  echo "  - Requesting webroot SSL certificate for ${APP_DOMAIN}"
  sudo certbot certonly \
    --webroot \
    -w "$ACME_ROOT" \
    --non-interactive \
    --agree-tos \
    --email "${CERTBOT_EMAIL}" \
    -d "${APP_DOMAIN}"
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

echo "[1/9] Checking VM packages and firewall"
ensure_firewall

echo "[2/9] Checking nginx and certbot"
ensure_nginx_and_certbot

echo "[3/9] Checking nginx domain ownership"
ensure_domain_is_available

echo "[4/9] Writing app-scoped nginx config"
write_nginx_config

echo "[5/9] Checking webroot SSL certificate"
ensure_webroot_certificate
write_nginx_config

if [ "$DEPLOY_MODE" = "requirements" ]; then
  echo "Server requirements are satisfied."
  exit 0
fi

echo "[6/9] Installing binary"
install_binary

echo "[7/9] Writing environment"
write_env_file

echo "[8/9] Writing systemd service"
write_systemd_service

echo "[9/9] Restarting and verifying service"
sudo systemctl restart "${SERVICE_NAME}.service"
wait_for_service
sudo systemctl --no-pager --full status "${SERVICE_NAME}.service" | sed -n '1,14p'
