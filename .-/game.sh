#!/bin/bash

set -e

# Configuration
HIDDEN_DIR="/.wlug"              # Directory to store game state
PLAYER_STATE_FILE="$HIDDEN_DIR/player_state.txt"  # File to store player progress
LEVEL_CONTAINERS=("meta_base_temp" "meta_base_temp" "meta_base_temp")     # Docker image tags for levels
SERVER_URL="http://172.17.0.1:5000/api/flag/submit"  # Server URL for flag validation
CONTAINER_NAME_PREFIX="Meta2k25"        # Prefix for container names
SUCCESS_LOG_PATTERN="(valid|success)"

# Check if Docker is installed
if ! command -v docker &>/dev/null; then
  echo "Docker is not installed. Please install Docker to play the game."
  exit 1
fi

# Check if a user exists
check_existing_user() {
  if [[ -f "$PLAYER_STATE_FILE" ]]; then
    echo "Existing user found. Resuming game..."
    local player_state
    player_state=$(sudo cat "$PLAYER_STATE_FILE")
    local player_id
    player_id=$(echo "$player_state" | cut -d':' -f1)
    local current_level
    current_level=$(echo "$player_state" | cut -d':' -f2)
    echo "Welcome back, $player_id! Resuming at Level $current_level."
    start_level "$current_level" "$player_id"
    exit 0
  fi
}

# Initialize the game
begin() {
  check_existing_user  # Check for existing user state

  echo "Enter your name:"
  read -r player_name

  # Generate a unique ID for the player
  local salt
  salt=$(date +%s%N | sha256sum | head -c 10)
  local unique_name="${player_name}_${salt}"

  echo "Hello, $player_name! Your unique ID is $unique_name."

  # Create hidden directory and state file
  sudo mkdir -p "$HIDDEN_DIR"
  sudo chmod 700 "$HIDDEN_DIR"
  sudo touch "$PLAYER_STATE_FILE"
  sudo chmod 600 "$PLAYER_STATE_FILE"

  # Save the initial state (Level 1)
  echo "$unique_name:1" | sudo tee "$PLAYER_STATE_FILE" > /dev/null
  echo "Game initialized! Starting Level 1..."
  start_level 1 "$unique_name"
}

# Start a level in a Docker container
start_level() {
  local level=$1
  local player_id=$2
  local container_name="${CONTAINER_NAME_PREFIX}_${player_id}_${level}"

  # Dynamically construct the image name
  # local image_name="pranavg1203/meta2k25:${LEVEL_CONTAINERS[$((level - 1))]}"

  local image_name="alex"

  echo "Starting Level $level for $player_id. Please wait..."

  # Check if the container already exists
  if docker ps -a --format "{{.Names}}" | grep -q "^$container_name$"; then
    # If the container is running, attach to it
    if docker ps --format "{{.Names}}" | grep -q "^$container_name$"; then
      echo "Container for Level $level is already running. Attaching..."
      docker attach "$container_name"
    else
      # If the container exists but is stopped, restart and attach
      echo "Restarting stopped container for Level $level..."
      docker start -ai "$container_name"
    fi
  else
    # If the container does not exist, create and run it
    docker run -it \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v $(which docker):/usr/bin/docker \
      --name "$container_name" \
      -e PLAYER_ID="$player_id" \
      -e LEVEL="$level" \
      -e SERVER_URL="$SERVER_URL" \
      "$image_name" bash
  fi

  # Check container logs after it exits
  local logs
  logs=$(docker logs "$container_name" 2>/dev/null || true) # Avoid error if logs are unavailable

  # Check for success pattern in logs
  if [[ $logs =~ $SUCCESS_LOG_PATTERN ]]; then
    echo "Congratulations! Proceeding to the next level..."
    local next_level=$((level + 1))
    echo "$player_id:$next_level" | sudo tee "$PLAYER_STATE_FILE" > /dev/null
    start_level "$next_level" "$player_id"  # Start the next level
  else
    echo "You exited the level without solving it. Restarting Level $level..."
    start_level "$level" "$player_id"  # Restart the current level
  fi
}

# Reset to Level 1 but keep user data
reset_soft() {
  echo "Performing a soft reset..."

  if [[ ! -f "$PLAYER_STATE_FILE" ]]; then
    echo "No existing user found. Use 'begin' to start a new game."
    exit 1
  fi

  local player_state
  player_state=$(sudo cat "$PLAYER_STATE_FILE")
  local player_id
  player_id=$(echo "$player_state" | cut -d':' -f1)

  echo "Resetting $player_id to Level 1..."
  echo "$player_id:1" | sudo tee "$PLAYER_STATE_FILE" > /dev/null
  start_level 1 "$player_id"
}

# Completely reset the game, deleting all user data
reset_hard() {
  echo "Performing a hard reset..."

  if [[ -f "$PLAYER_STATE_FILE" ]]; then
    sudo rm -f "$PLAYER_STATE_FILE"
    echo "User data deleted. Starting a fresh game."
  fi

  begin
}

# Entry point for the script
case "$1" in
  begin)
    begin
    ;;
  reset_soft)
    reset_soft
    ;;
  reset_hard)
    reset_hard
    ;;
  *)
    echo "Usage: $0 {begin|reset_soft|reset_hard}"
    exit 1
    ;;
esac
