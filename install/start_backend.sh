#!/bin/bash
# Start backend servers for ATP
echo "Starting ATP backend servers..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v docker-compose &>/dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif docker compose version &>/dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "Error: neither 'docker-compose' nor 'docker compose' found. Please install Docker Compose." >&2
    exit 1
fi
echo "Find $DOCKER_COMPOSE_CMD installed"


prepare_pulsar() {
	rm -rf "$SCRIPT_DIR/binaries/backend/pulsar/data/"
	mkdir -p "$SCRIPT_DIR/binaries/backend/release/pulsar/data/zookeeper/version-2" "$SCRIPT_DIR/binaries/backend/release/pulsar/data/bookkeeper"
	sudo chmod -R 777 "$SCRIPT_DIR/binaries/backend/release/pulsar/data/"
}

COMPOSE_FILE="$SCRIPT_DIR/binaries/backend/release/docker-compose.yml"
# Detect host IP for DOCKER_HOST_IP if not already set
if [ -z "$DOCKER_HOST_IP" ]; then
	if command -v ipconfig &> /dev/null; then
		DOCKER_HOST_IP=$(ipconfig getifaddr en0 2>/dev/null)
	fi
	if [ -z "$DOCKER_HOST_IP" ]; then
		DOCKER_HOST_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
	fi
	if [ -z "$DOCKER_HOST_IP" ]; then
		DOCKER_HOST_IP=$(ifconfig | awk '/inet / && $2 != "127.0.0.1" {print $2; exit}')
	fi
	if [ -z "$DOCKER_HOST_IP" ]; then
		echo "Could not detect DOCKER_HOST_IP. Please set it manually." >&2
		exit 1
	fi
	export DOCKER_HOST_IP
	export PULSAR_BROKERS="$DOCKER_HOST_IP"
	echo "Detected DOCKER_HOST_IP: $DOCKER_HOST_IP"
fi

prepare_pulsar
$DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" up -d
echo "Waiting for 'broker' container to start..."



while true; do
	BROKER_ID=$($DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" ps -q broker)
	if [ -n "$BROKER_ID" ]; then
		STATE=$(docker inspect --format='{{.State.Status}}' "$BROKER_ID" 2>/dev/null)
		if [ "$STATE" = "running" ]; then
			break
		fi
	fi
	sleep 2
done
echo "Waiting for 'broker' service to become healthy (if healthcheck is defined)..."

while true; do
	BROKER_ID=$($DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" ps -q broker)
	HEALTH=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' "$BROKER_ID" 2>/dev/null)
	if [ "$HEALTH" = "healthy" ] || [ "$HEALTH" = "no-healthcheck" ]; then
		break
	fi
	sleep 2
done
echo "'broker' service is ready. Booting up master..."

master_dir="$SCRIPT_DIR/binaries/backend/release/master"
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$HOME/.dotnet:$PATH"
cd "$master_dir" || { echo "Failed to change directory to $master_dir"; exit 1; }

echo "Building master server..."
if ! dotnet build; then
	echo "dotnet build failed. Exiting."
	exit 1
fi


dotnet run &
MASTER_PID=$!
cleanup() {
	echo "Shutting down master server and docker-compose..."
	if [ -n "$MASTER_PID" ] && kill -0 "$MASTER_PID" 2>/dev/null; then
		kill "$MASTER_PID"
		wait "$MASTER_PID"
	fi
	# Kill any remaining dotnet processes from the master directory
	DOTNET_PIDS=$(pgrep -f "dotnet.*$master_dir")
	for pid in $DOTNET_PIDS; do
		if [ "$pid" != "$MASTER_PID" ]; then
			kill "$pid" 2>/dev/null
		fi
	done
	$DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" down
}

trap 'cleanup; exit 0' SIGINT SIGTERM EXIT

# Forward signals to child and wait
while true; do
	wait $MASTER_PID
	status=$?
	# If exited due to signal, cleanup will be called by trap
	exit $status
done
