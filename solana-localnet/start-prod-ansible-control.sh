#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
PROFILE="prod"
SERVICE="ansible-control-prod"

echo "Starting prod profile with docker compose..."
docker compose -f "$COMPOSE_FILE" --profile "$PROFILE" up -d

echo "Waiting for $SERVICE container to be ready..."
until docker compose -f "$COMPOSE_FILE" --profile "$PROFILE" exec -T "$SERVICE" true 2>/dev/null; do
  sleep 2
done

echo ""
echo "Prod profile started. Attach to the container with:"
echo "docker compose -f $COMPOSE_FILE --profile $PROFILE exec -w /hayek-validator-kit $SERVICE bash -l"
