#!/bin/bash

# Configuration
COMMANDS_DIR="/usr/local/bin"  # Directory where the commands were installed
COMMANDS=("begin" "reset_soft" "reset_hard")  # List of commands to remove

# Function to remove the command file
remove_command() {
  local command_name=$1
  local command_file="$COMMANDS_DIR/$command_name"

  # Check if the command exists and delete it
  if [[ -f "$command_file" ]]; then
    echo "Removing command: $command_name"
    sudo rm "$command_file"
    echo "Command $command_name removed successfully!"
  else
    echo "Command $command_name not found. Skipping..."
  fi
}

# Ensure the script runs on Linux
if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This script is designed to run only on Linux systems."
  exit 1
fi

# Remove all the listed commands
echo "Removing all game-related commands..."

for command in "${COMMANDS[@]}"; do
  remove_command "$command"
done

sudo rm -rf /.wlug

echo "All game-related commands have been removed successfully!"
echo "Peace out ;)" | figlet || echo "Peace out ;)"
