#!/bin/bash

set -e

# Configuration
HIDDEN_DIR="/.wlug"              # Directory to store game state
PLAYER_STATE_FILE="$HIDDEN_DIR/player_state.txt"  # File to store player progress
LEVEL_CONTAINERS=("ghcr.io/pranavg1203/meta:warg0" "ghcr.io/pranavg1203/meta:warg01" "ghcr.io/pranavg1203/meta:warg02" "ghcr.io/pranavg1203/meta:warg03" "image5")  # Docker image names
SERVER_URL="http://172.17.0.1:5000/api/flag/submit"  # Server URL for flag validation
CONTAINER_NAME_PREFIX="Meta2k25"        # Prefix for container names
SUCCESS_LOG_PATTERN="(valid|success)"

# Check if Docker is installed
if ! command -v docker &>/dev/null; then
  echo "Docker is not installed. Please install Docker to play the game."
  exit 1
fi

# Cleanup Docker environment before each level
cleanup_docker() {
  echo "Cleaning up Docker environment..."
  docker rm -f $(docker ps -aq) 2>/dev/null || true
  docker rmi -f $(docker images -q) 2>/dev/null || true
  docker volume rm $(docker volume ls -q) 2>/dev/null || true
  docker network prune -f 2>/dev/null || true
}

# Start levels sequentially
start_levels() {
  for level in "${!LEVEL_CONTAINERS[@]}"; do
    local image_name="${LEVEL_CONTAINERS[$level]}"
    local container_name="${CONTAINER_NAME_PREFIX}_Level${level}"
    
    cleanup_docker
    echo "Starting Level $level with image: $image_name"
    
    docker run -it --rm \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v $(which docker):/usr/bin/docker \
      -v /var/lib/docker/volumes:/var/lib/docker/volumes \
      -e LEVEL="$level" \
      -e SERVER_URL="$SERVER_URL" \
      --name "$container_name" \
      "$image_name" bash
  done
  
  echo "All levels completed!"
}

# Entry point for the script
case "$1" in
  start)
    start_levels
    ;;
  *)
    echo "Usage: $0 start"
    exit 1
    ;;
esac
