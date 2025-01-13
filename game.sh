#!/bin/bash

set -e

# Configuration
HIDDEN_DIR="/.ctfd_game_data"           # Hidden directory in the root directory
CURRENT_LEVEL_FILE="$HIDDEN_DIR/current_level.txt"  # Hidden file to track the current level
PLAYER_NAME_FILE="$HIDDEN_DIR/player_name.txt"      # File to store the player's name
LEVELS_REPO_LIST=("https://github.com/PranavG1203/meta_wargames_trial_1.git" "https://github.com/PranavG1203/meta_wargames_trial_1.git")  # List of level Git repositories
LEVEL_PASSWORDS=("alex" "mike" "1203")   # Passwords for each level

# Function to initialize the game
begin() {
  # Ask for player name
  echo "Enter your name:"
  read -r player_name
  echo "Hello, $player_name! Welcome to the game."

  sudo mkdir -p "$HIDDEN_DIR"  # Create the hidden directory in the root directory
  sudo chmod 700 "$HIDDEN_DIR"  # Restrict access to the hidden directory
  sudo touch "$CURRENT_LEVEL_FILE"
  sudo chmod 600 "$CURRENT_LEVEL_FILE"  # Restrict access to the file
  echo 1 | sudo tee "$CURRENT_LEVEL_FILE" > /dev/null  # Initialize current level to 1

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
      cd -  # Return to the previous directory after setup
    else
      chmod +x "$level_0_dir/setup.sh" > /dev/null  # Make it executable
      if [[ -x "$level_0_dir/setup.sh" ]]; then
        # Change to the level directory before running the setup script
        cd "$level_0_dir"
        bash setup.sh
        cd -  # Return to the previous directory after setup
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

  # Check if setup.sh exists and is executable before running
  if [[ -f "$level_dir/setup.sh" ]]; then
    # Check if setup.sh is executable
    if [[ -x "$level_dir/setup.sh" ]]; then
      # Change to the level directory before running the setup script
      cd "$level_dir"
      echo "Setting up level $next_level..."
      bash setup.sh
      cd -  # Return to the previous directory after setup
    else
      chmod +x "$level_dir/setup.sh"  # Make sure it's executable
      if [[ -x "$level_dir/setup.sh" ]]; then
        cd "$level_dir"
        bash setup.sh
        cd -  # Return to the previous directory after setup
      else
        echo "Error: Could not make setup.sh executable. Exiting."
        exit 1
      fi
    fi
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

# Soft reset function (resets player data but not the level)
reset_soft() {
  echo "Performing a soft reset..."

  # Save the current level before resetting
  local current_level
  current_level=$(sudo cat "$CURRENT_LEVEL_FILE")
  
  # Reset any other player progress or data (if needed)
  # You can add custom code here to clear player-specific data or files
  
  # Re-clone the repository of the current level
  local level_repo="${LEVELS_REPO_LIST[$((current_level - 1))]}"
  local level_dir="./level_$current_level"

  if [[ -d "$level_dir" ]]; then
    rm -rf "$level_dir"  # Remove the existing directory (if any) to re-clone
  fi

  # Clone the repository for the current level
  echo "Cloning repository for Level $current_level..."
  git clone "$level_repo" "$level_dir" > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to clone Level $current_level repository."
    return 1
  fi

  # Run setup.sh for the cloned level
  if [[ -f "$level_dir/setup.sh" ]]; then
    if [[ -x "$level_dir/setup.sh" ]]; then
      cd "$level_dir"
      bash setup.sh  # Run the setup script
      cd -  # Return to the previous directory after setup
    else
      chmod +x "$level_dir/setup.sh"  # Make the script executable if needed
      cd "$level_dir"
      bash setup.sh  # Run the setup script
      cd -  # Return to the previous directory after setup
    fi
  else
    echo "Error: No setup.sh found in Level $current_level. Skipping setup."
  fi
  
  # Restore the current level to the file
  echo "$current_level" | sudo tee "$CURRENT_LEVEL_FILE" > /dev/null

  echo "Soft reset completed. You are back at Level $current_level, and the level is reloaded!"
}

# Hard reset function (resets player data and level progress)
reset_hard() {
  echo "Performing a hard reset..."

  # Remove the current level file (resets progress)
  sudo rm -f "$CURRENT_LEVEL_FILE"
  
  # Remove any cloned levels (clear all progress)
  rm -rf ./level_*
  
  # Reinitialize the game
  begin

  echo "Hard reset completed. The game is now reset to Level 1."
}

# Entry point for the script
case "$1" in
  begin)
    begin
    ;;
  levelup)
    levelup
    ;;
  reset_soft)
    reset_soft
    ;;
  reset_hard)
    reset_hard
    ;;
  *)
    echo "Usage: $0 {begin|levelup|reset_soft|reset_hard}"
    exit 1
    ;;
esac
