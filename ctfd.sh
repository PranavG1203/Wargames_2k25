#!/bin/bash

set -e

# Configuration
BASE_DIR="$HOME/ctfd_game"             # Base directory for all levels
LEVELS_REPO_LIST=("https://github.com/PranavG1203/meta_wargames_trial_1.git" "https://github.com/PranavG1203/meta_wargames_trial_1.git") # List of level Git repositories
PASSWORDS=("alex" "mike") # Passwords for each level
CURRENT_LEVEL_FILE="$BASE_DIR/current_level.txt" # File to track the current level

# Function to initialize the game
initialize_game() {
  mkdir -p "$BASE_DIR"
  echo 0 > "$CURRENT_LEVEL_FILE"
  echo "Game initialized! Use the 'next_level' command to start."
}

# Function to validate the password for the current level
validate_password() {
  local level_id
  level_id=$(cat "$CURRENT_LEVEL_FILE")

  echo "Enter the password for Level $level_id:"
  read -r user_password

  # Validate the password
  if [[ "$user_password" == "${PASSWORDS[$((level_id - 1))]}" ]]; then
    echo "Password is correct. Proceeding to the next level..."
    return 0
  else
    echo "Incorrect password. Try again."
    return 1
  fi
}

# Function to load the next level
load_next_level() {
  local level_id
  level_id=$(cat "$CURRENT_LEVEL_FILE")
  local next_level=$((level_id + 1))

  if [[ $next_level -gt ${#LEVELS_REPO_LIST[@]} ]]; then
    echo "Congratulations! You have completed all levels."
    return
  fi

  echo "Loading Level $next_level..."

  local repo_url="${LEVELS_REPO_LIST[$((next_level - 1))]}"
  local level_dir="$BASE_DIR/level_$next_level"

  # Clone the repository if not already cloned
  if [[ ! -d "$level_dir" ]]; then
    git clone "$repo_url" "$level_dir" > /dev/null 2>&1
  fi

  # Change to the level directory and run the setup
  cd "$level_dir"
  if [[ -x "./setup.sh" ]]; then
    ./setup.sh
  else
    echo "No setup.sh found for Level $next_level. Skipping setup."
  fi

  echo $next_level > "$CURRENT_LEVEL_FILE"
  echo "Level $next_level is ready. Solve it to get the flag."
}

# Custom command to proceed to the next level
next_level() {
  # Validate password before proceeding to the next level
  if validate_password; then
    load_next_level
  fi
}

# Entry point for the script
case "$1" in
  initialize)
    initialize_game
    ;;
  next_level)
    next_level
    ;;
  *)
    echo "Usage: $0 {initialize|next_level}"
    exit 1
    ;;
esac
