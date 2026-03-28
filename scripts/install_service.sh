#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="app.service"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"

APP_NAME="echo-app"
APP_USER="${SUDO_USER:-$USER}"
APP_GROUP="$(id -gn "$APP_USER")"

INSTALL_DIR="/opt/${APP_NAME}"
CONFIG_DIR="/etc/${APP_NAME}"
ENV_FILE="${CONFIG_DIR}/app.env"
BINARY_SOURCE="build/echo_server"
BINARY_TARGET="${INSTALL_DIR}/echo_server"

if [[ ! -f "${BINARY_SOURCE}" ]]; then
  echo "ERROR: ${BINARY_SOURCE} not found. Build the app first:"
  echo "  ./scripts/build.sh"
  exit 1
fi

echo "Installing/updating ${APP_NAME}..."

sudo mkdir -p "${INSTALL_DIR}"
sudo mkdir -p "${CONFIG_DIR}"

sudo install -m 0755 "${BINARY_SOURCE}" "${BINARY_TARGET}"

if ! id "${APP_USER}" >/dev/null 2>&1; then
  echo "ERROR: user '${APP_USER}' does not exist"
  exit 1
fi

sudo chown -R "${APP_USER}:${APP_GROUP}" "${INSTALL_DIR}"
sudo chown -R "${APP_USER}:${APP_GROUP}" "${CONFIG_DIR}"

echo "Writing ${ENV_FILE} ..."
sudo tee "${ENV_FILE}" >/dev/null <<EOF
APP_BIND_ADDRESS=0.0.0.0
APP_PORT=8080
APP_ENV=dev
APP_NODE_ID=node-local
EOF

sudo chown "${APP_USER}:${APP_GROUP}" "${ENV_FILE}"
sudo chmod 0644 "${ENV_FILE}"

echo "Writing ${SERVICE_PATH} ..."
sudo tee "${SERVICE_PATH}" >/dev/null <<EOF
[Unit]
Description=Echo C++ REST API service
After=network.target

[Service]
Type=simple
User=${APP_USER}
Group=${APP_GROUP}
WorkingDirectory=${INSTALL_DIR}
EnvironmentFile=${ENV_FILE}
ExecStart=${BINARY_TARGET}
Restart=always
RestartSec=3

# Hardening-lite
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd ..."
sudo systemctl daemon-reload

echo "Enabling ${SERVICE_NAME} ..."
sudo systemctl enable "${SERVICE_NAME}" >/dev/null

if systemctl list-unit-files | grep -q "^${SERVICE_NAME}"; then
  echo "Restarting ${SERVICE_NAME} ..."
  sudo systemctl restart "${SERVICE_NAME}"
else
  echo "Starting ${SERVICE_NAME} ..."
  sudo systemctl start "${SERVICE_NAME}"
fi

echo
echo "Done."
echo "Useful commands:"
echo "  systemctl status ${SERVICE_NAME}"
echo "  journalctl -u ${SERVICE_NAME} -f"
echo "  curl http://127.0.0.1:8080/health"
