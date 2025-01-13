#!/bin/bash

# Configuration
GAME_SCRIPT_PATH="$(pwd)/game.sh"  # Use the current directory for the game script
COMMANDS_DIR="/usr/local/bin"             # Directory to store the standalone commands

# Function to create the command file
create_command() {
  local command_name=$1
  local command_content=$2

  # Create a new command file in the commands directory
  local command_file="$COMMANDS_DIR/$command_name"

  echo "Creating command for: $command_name"

  # Check if the command already exists
  if [[ -f "$command_file" ]]; then
    echo "Error: $command_file already exists. Skipping..."
    return
  fi

  # Write the command to the file
  echo "#!/bin/bash" > "$command_file"
  echo "$command_content" >> "$command_file"

  # Make the command file executable
  chmod +x "$command_file"
  echo "Command $command_name created successfully!"
}

# Function to create the standalone commands
install_game_commands() {
  echo "Setting up standalone commands for the game..."

  # Ensure the game script exists
  if [[ ! -f "$GAME_SCRIPT_PATH" ]]; then
    echo "Error: Game script not found at $GAME_SCRIPT_PATH"
    exit 1
  fi

  # Create individual commands by adding specific arguments to the main script

  # Command for starting the game (begin)
  create_command "begin" "bash $GAME_SCRIPT_PATH begin"

  # Command for leveling up (levelup)
  create_command "levelup" "bash $GAME_SCRIPT_PATH levelup"

  # Command for soft reset (reset_soft)
  create_command "reset_soft" "bash $GAME_SCRIPT_PATH reset_soft"

  # Command for hard reset (reset_hard)
  create_command "reset_hard" "bash $GAME_SCRIPT_PATH reset_hard"

  echo "Standalone commands set up successfully!"
}

# Run the installation process
install_game_commands