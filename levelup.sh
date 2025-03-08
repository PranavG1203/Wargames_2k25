#!/bin/bash

# Fetch environment variables
PLAYER_ID=${PLAYER_ID:-"unknown"}
LEVEL=${LEVEL:-1}
SERVER_URL=${SERVER_URL:-"http://172.17.0.1:5000/api/flag/submit"}


# Prompt for the flag
echo "Enter the flag for Level $LEVEL:"
read -r flag

# Validate the flag
response=$(curl -s -X POST "$SERVER_URL" \
  -H "Content-Type: application/json" \
  -d "{\"username\": \"$PLAYER_ID\", \"level\": \"$LEVEL\", \"submittedEncryptedFlag\": \"$flag\"}")

# echo $response

# Handle the response
if [[ "$response" == "valid" ]]; then
  echo "Correct flag! To proceed to the next level press \"Ctrl+D\"."
else
  echo "Incorrect flag. Try again."
fi
