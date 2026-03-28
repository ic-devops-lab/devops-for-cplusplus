#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="app.service"

usage() {
  echo "Usage: $0 {start|stop|restart|status|logs|enable|disable}"
  exit 1
}

cmd="${1:-}"
case "${cmd}" in
  start)
    sudo systemctl start "${SERVICE_NAME}"
    ;;
  stop)
    sudo systemctl stop "${SERVICE_NAME}"
    ;;
  restart)
    sudo systemctl restart "${SERVICE_NAME}"
    ;;
  status)
    systemctl status "${SERVICE_NAME}" --no-pager
    ;;
  logs)
    journalctl -u "${SERVICE_NAME}" -f
    ;;
  enable)
    sudo systemctl enable "${SERVICE_NAME}"
    ;;
  disable)
    sudo systemctl disable "${SERVICE_NAME}"
    ;;
  *)
    usage
    ;;
esac