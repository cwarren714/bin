#!/bin/bash

# Function to get container details with colors
get_container_details() {
    docker ps | awk 'NR>1 {print $NF}'
}

RUN_AS_ROOT=false
ROOT_STRING=""

# check if the `-r` flag is passed
while getopts ":r" opt; do
    case $opt in
        r)
            RUN_AS_ROOT=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

if [ "$RUN_AS_ROOT" = true ]; then
    ROOT_STRING=" -u root"
fi

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
    docker exec -it $ROOT_STRING $selected_container /bin/bash
else
    echo "No container selected. Exiting."
fi
