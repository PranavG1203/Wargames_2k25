#!/bin/bash

# Fetch environment variables
PLAYER_ID=${PLAYER_ID:-"unknown"}
LEVEL=${LEVEL:-1}
SERVER_URL=${SERVER_URL:-"http://localhost:5000/api/flag/submit"}

echo "PLAYER_ID=$PLAYER_ID"
echo "LEVEL=$LEVEL"
echo "SERVER_URL=$SERVER_URL"


# Prompt for the flag
echo "Enter the flag for Level $LEVEL:"
read -r flag

# Validate the flag by sending it to the server
response=$(curl -s -X POST "$SERVER_URL" \
  -H "Content-Type: application/json" \
  -d "{\"username\": \"$PLAYER_ID\", \"level\": \"$LEVEL\", \"submittedEncryptedFlag\": \"$flag\"}")

echo $response

# Check server response
if [[ "$response" == "valid" ]]; then
  echo "Correct flag! Exiting to proceed to the next level..."
  exit 1  # Exit with code 1 to signal success
else
  echo "Incorrect flag. Try again."
fi
