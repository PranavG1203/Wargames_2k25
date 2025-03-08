#!/bin/bash

set -e

# Configuration
HIDDEN_DIR="/.wlug"              # Directory to store game state
PLAYER_STATE_FILE="$HIDDEN_DIR/player_state.txt"  # File to store player progress
LEVEL_CONTAINERS=("warg1" "warg2" "warg3" "warg4")  # Docker image tags for levels
SERVER_URL="http://172.17.0.1:5000/api/flag/submit"  # Server URL for flag validation
CONTAINER_NAME_PREFIX="CTF"  # Prefix for container names
SUCCESS_LOG_PATTERN="(valid|success|move)"  # Fixed regex pattern

# Check if Docker is installed
if ! command -v docker &>/dev/null; then
  echo "Docker is not installed. Installing Docker..."
  sudo apt update && sudo apt install -y docker.io
  sudo systemctl start docker
  sudo systemctl enable docker
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

  # Save the initial state (Level 0)
  echo "$unique_name:0" | sudo tee "$PLAYER_STATE_FILE" > /dev/null
  echo "Game initialized! Starting Level 0..."
  start_level 0 "$unique_name"
}

# Start a level in a Docker container
start_level() {
  local level=$1
  local player_id=$2
  local container_name="${CONTAINER_NAME_PREFIX}_${player_id}_${level}"

  # Dynamically construct the image name
  local image_name="ghcr.io/walchand-linux-users-group/wildwarrior44/wargame_finals:${LEVEL_CONTAINERS[$level]}"

  echo "Starting Level $level for $player_id. Please wait..."

  # Stop and remove any existing container with the same name
  docker rm -f "$container_name" >/dev/null 2>&1 || true

  # Run the container (without --rm to allow logs retrieval)
  docker run -it --name "$container_name" \
    -e PLAYER_ID="$player_id" \
    -e LEVEL="$level" \
    -e SERVER_URL="$SERVER_URL" \
    "$image_name" bash

  # Get logs AFTER the container stops
  logs=$(docker logs "$container_name" 2>/dev/null || true)

  # Remove the container after checking logs
  docker rm "$container_name" >/dev/null 2>&1 || true

  # Debugging: Print logs to verify correctness
  echo "Container logs: $logs"

  # Check if success pattern is found in logs
  if [[ ! -z "$logs" && "$logs" =~ $SUCCESS_LOG_PATTERN ]]; then
    echo "Congratulations! Proceeding to the next level..."
    local next_level=$((level + 1))
    echo "$player_id:$next_level" | sudo tee "$PLAYER_STATE_FILE" > /dev/null
    start_level "$next_level" "$player_id"
  else
    echo "You exited the level without solving it. Restarting Level $level..."
    start_level "$level" "$player_id"
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

  echo "Resetting $player_id to Level 0..."
  echo "$player_id:0" | sudo tee "$PLAYER_STATE_FILE" > /dev/null
  start_level 0 "$player_id"
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
