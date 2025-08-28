#!/bin/bash
# filepath: ./start-localnet-from-outside-ide.sh

set -e

# Path to your docker-compose file
COMPOSE_FILE="./docker-compose.yml"
SERVICE="ansible-control"
WORKSPACE_FOLDER="$(pwd)"

# Start docker compose in detached mode
docker compose -f "$COMPOSE_FILE" up -d

# Wait for the ansible-control container to be healthy/up
echo "Waiting for $SERVICE container to be ready..."
until docker compose -f "$COMPOSE_FILE" exec -T $SERVICE true 2>/dev/null; do
  sleep 2
done

# Run the postStartCommand inside the container
docker compose -f "$COMPOSE_FILE" exec $SERVICE bash -l -c "cd /hayek-validator-kit && ./solana-localnet/start-localnet.sh"

echo "Localnet started. Attach to the container with:"
echo "docker compose -f $COMPOSE_FILE exec -w /hayek-validator-kit $SERVICE bash -l"
