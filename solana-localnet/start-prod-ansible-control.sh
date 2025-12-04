#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="./docker-compose.yml"
PROFILE="prod"
SERVICE="ansible-control-prod"

echo "Starting prod profile with docker compose..."
docker compose -f "$COMPOSE_FILE" --profile "$PROFILE" up -d

echo "Waiting for $SERVICE container to be ready..."
until docker compose -f "$COMPOSE_FILE" --profile "$PROFILE" exec -T "$SERVICE" true 2>/dev/null; do
  sleep 2
done

echo "Docker Compose version:"
docker compose --version

echo "Prod profile started. Attach to the container with:"
echo "docker compose -f $COMPOSE_FILE --profile $PROFILE exec -w /hayek-validator-kit $SERVICE bash -l"
