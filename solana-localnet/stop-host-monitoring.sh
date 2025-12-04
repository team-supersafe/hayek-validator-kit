#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENGINE="${1:-docker}"
PROFILE="monitor"
COMPOSE_BASE="$SCRIPT_DIR/docker-compose.yml"

case "$ENGINE" in
  podman)
    OVERRIDE="$SCRIPT_DIR/docker-compose.podman.yml"
    COMPOSE_BIN="podman compose"
    ;;
  docker)
    OVERRIDE="$SCRIPT_DIR/docker-compose.docker.yml"
    COMPOSE_BIN="docker compose"
    ;;
  *)
    echo "Unknown engine '$ENGINE' (use podman or docker)" >&2
    exit 1
    ;;
esac

SERVICE="host-monitoring"
compose() { $COMPOSE_BIN -f "$COMPOSE_BASE" -f "$OVERRIDE" --profile localnet --profile "$PROFILE" "$@"; }

echo "Stopping $SERVICE with $ENGINE..."
compose stop "$SERVICE" || true
compose rm -f "$SERVICE" || true

echo "$SERVICE stopped."
