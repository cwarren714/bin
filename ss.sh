#!/bin/bash
#Ssh Select - Select a host from your SSH config and connect to it using fzf

# Check if fzf is installed
if ! command -v fzf &> /dev/null; then
    echo "fzf is not installed. Please install it to use this script."
    exit 1
fi
fdl;

# Path to SSH config file
SSH_CONFIG="$HOME/.ssh/config"

# Extract host entries from SSH config
hosts=$(grep -i '^host ' "$SSH_CONFIG" | awk '{print $2}' | sort)

# Use fzf to select a host
selected_host=$(echo "$hosts" | fzf --height=50% --layout=reverse --prompt="Select SSH host: ")

# Check if a host was selected
if [ -z "$selected_host" ]; then
    echo "No host selected. Exiting."
    exit 0
fi

# Connect to the selected host
ssh "$selected_host"
