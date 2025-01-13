#!/bin/bash

set -e

# Configuration
HIDDEN_DIR="/.ctfd_game_data" # Hidden directory in the root directory
CURRENT_LEVEL_FILE="$HIDDEN_DIR/current_level.txt" # Hidden file to track the current level
PLAYER_NAME_FILE="$HIDDEN_DIR/player_name.txt" # File to store the player's name
LEVELS_REPO_LIST=("https://github.com/PranavG1203/meta_wargames_trial_1.git" "https://github.com/PranavG1203/meta_wargames_trial_1.git") # List of level Git repositories
LEVEL_PASSWORDS=("alex" "mike" "1203") # Passwords for each level

# Function to initialize the game
begin() {
  # Ask for player name
  echo "Enter your name:"
  read -r player_name
  echo "Hello, $player_name! Welcome to the game."

  sudo mkdir -p "$HIDDEN_DIR" # Create the hidden directory in the root directory
  sudo chmod 700 "$HIDDEN_DIR" # Restrict access to the hidden directory
  sudo touch "$CURRENT_LEVEL_FILE"
  sudo chmod 600 "$CURRENT_LEVEL_FILE" # Restrict access to the file
  echo 1 | sudo tee "$CURRENT_LEVEL_FILE" > /dev/null # Initialize current level to 1

  echo "Game initialized! Loading Level 0..."

  # Clone the first level's repository (Level 0)
  local level_0_repo="${LEVELS_REPO_LIST[0]}"
  local level_0_dir="./level_0"

  if [[ ! -d "$level_0_dir" ]]; then
    git clone "$level_0_repo" "$level_0_dir" > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      echo "Error: Failed to load Level 0 template."
      return 1
    fi
  else
    echo "Level 0 template already exists."
  fi

  echo "Level 0 is loaded. Setting up level, Please be patient..."
  
  # Run setup.sh for Level 0 if it exists and is executable
  if [[ -f "$level_0_dir/setup.sh" ]]; then
    if [[ -x "$level_0_dir/setup.sh" ]]; then
      # Change to the level directory before running the setup script
      cd "$level_0_dir"
      bash setup.sh
      cd - # Return to the previous directory after setup
    else
      # echo "Error: setup.sh is not executable for Level 0. Attempting to change permissions..."
      chmod +x "$level_0_dir/setup.sh"  # Make it executable
      if [[ -x "$level_0_dir/setup.sh" ]]; then
        # Change to the level directory before running the setup script
        cd "$level_0_dir"
        bash setup.sh
        cd - # Return to the previous directory after setup
      else
        echo "Template issue."
        exit 1
      fi
    fi
  else
    echo "Error: No setup.sh found in Level 0. Skipping setup."
  fi

  echo "Level 0 is ready. Solve it and use 'levelup' with the correct password to proceed!"
}

# Function to load the next level
load_next_level() {
  local level_id
  level_id=$(sudo cat "$CURRENT_LEVEL_FILE")
  local next_level=$((level_id + 1))

  if [[ $next_level -gt ${#LEVELS_REPO_LIST[@]} ]]; then
    echo "Congratulations! You have completed all levels."
    return
  fi

  echo "Loading Level $next_level..."
  local repo_url="${LEVELS_REPO_LIST[$((next_level - 1))]}"
  local level_dir="./level_$next_level"

  # Clone the repository if not already cloned
  if [[ ! -d "$level_dir" ]]; then
    git clone "$repo_url" "$level_dir" > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      echo "Error: Failed to clone Level $next_level repository."
      return 1
    fi
  fi

  # echo "$level_dir"
  
  # Check if setup.sh exists and is executable before running
  if [[ -f "$level_dir/setup.sh" ]]; then
    # echo "Found setup.sh at $level_dir/setup.sh"

    # Check if setup.sh is executable
    if [[ -x "$level_dir/setup.sh" ]]; then
      # Change to the level directory before running the setup script
      cd "$level_dir"
      echo "Setting up level $next_level..."
      bash setup.sh
      cd - # Return to the previous directory after setup
    else
      # echo "Error: setup.sh is not executable. Attempting to change permissions..."
      chmod +x "$level_dir/setup.sh"  # Make sure it's executable
      if [[ -x "$level_dir/setup.sh" ]]; then
        # echo "Permissions updated. Re-running setup.sh."
        cd "$level_dir"
        bash setup.sh
        cd - # Return to the previous directory after setup
      else
        echo "Error: Could not make setup.sh executable. Exiting."
        exit 1
      fi
    fi
  else
    # echo "Error: No setup.sh found in $level_dir. Skipping setup."
  fi

  echo $next_level | sudo tee "$CURRENT_LEVEL_FILE" > /dev/null
  echo "Level $next_level is ready. Solve it to proceed!"
}

# Custom command to proceed to the next level
levelup() {
  local level_id
  level_id=$(sudo cat "$CURRENT_LEVEL_FILE")

  echo "Enter the password for Level $level_id:"
  read -r password

  if [[ "$password" == "${LEVEL_PASSWORDS[$((level_id - 1))]}" ]]; then
    load_next_level
  else
    echo "Incorrect password. Try again."
  fi
}

# Entry point for the script
case "$1" in
  begin)
    begin
    ;;
  levelup)
    levelup
    ;;
  *)
    echo "Usage: $0 {begin|levelup}"
    exit 1
    ;;
esac
