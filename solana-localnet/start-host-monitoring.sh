#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Usage: ./start-host-monitoring.sh [podman|docker]
ENGINE="${1:-docker}"
PROFILE="monitor"
COMPOSE_BASE="$SCRIPT_DIR/docker-compose.yml"

case "$ENGINE" in
  podman)
    OVERRIDE="$SCRIPT_DIR/docker-compose.podman.yml"
    COMPOSE_BIN="podman compose"
    export BUILDAH_FORMAT=${BUILDAH_FORMAT:-docker}
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

echo "Starting $SERVICE with $ENGINE..."
compose up -d "$SERVICE"

echo "Waiting for $SERVICE container to be ready..."
until compose exec -T "$SERVICE" true >/dev/null 2>&1; do
  sleep 2
done

echo "$SERVICE started. Attach with:"
echo "$COMPOSE_BIN -f $COMPOSE_BASE -f $OVERRIDE --profile $PROFILE exec -w /hayek-validator-kit $SERVICE bash -l"
