#!/bin/bash

# Function to get container details with colors
get_container_details() {
    docker ps | awk 'NR>1 {print $NF}'
}

# Use fzf to select a container with preview
selected_container=$(get_container_details | fzf \
    --preview="docker inspect {} | jq '.[0] | {Image, Config, NetworkSettings, HostConfig}'" \
    --preview-window=right:60% \
    --height=80% \
    --layout=reverse \
    --header="Select a Docker Container to exec into")

# Check if a container was selected
if [ -n "$selected_container" ]; then
    echo "Executing /bin/bash in container: $selected_container"
    docker exec -it "$selected_container" /bin/bash
else
    echo "No container selected. Exiting."
fi

