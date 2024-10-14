#!/bin/bash

# Check if fzf and ripgrep are installed
if ! command -v fzf &> /dev/null || ! command -v rg &> /dev/null; then
    echo "Error: This script requires both fzf and ripgrep to be installed."
    exit 1
fi

# Function to print usage
print_usage() {
    echo "Usage: $0 [-o] [-n] [-p] [-e EXCLUDE] [-l DIR] [-h|--help]"
    echo "ripfuz: Interactive search using ripgrep and fzf"
    echo
    echo "Options:"
    echo "  -o         Open the selected file in Vim"
    echo "  -n         Open the selected file in Neovim"
    echo "  -p         Turn off the preview window (on by default)"
    echo "  -e EXCLUDE Comma-separated list of glob patterns to exclude (e.g. '*.php,*.js')"
    echo "  -l DIR     Search in the specified directory instead of current directory"
    echo "  -h, --help Display this help message"
}

# Default values
open_in_vim=false
open_in_neovim=false
preview=true
exclude_patterns=""
search_dir="."

# Parse command line arguments
while getopts ":onpe:l:h-:" opt; do
    case $opt in
        o)
            open_in_vim=true
            ;;
        n)
            open_in_neovim=true
            ;;
        p)
            preview=false
            ;;
        e)
            exclude_patterns=$OPTARG
            ;;
        l)
            search_dir=$OPTARG
            ;;
        h)
            print_usage
            exit 0
            ;;
        -)
            case "${OPTARG}" in
                help)
                    print_usage
                    exit 0
                    ;;
                *)
                    echo "Invalid option: --${OPTARG}" >&2
                    print_usage
                    exit 1
                    ;;
            esac
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            print_usage
            exit 1
            ;;
    esac
done

# Function to perform the search
perform_search() {
    RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
    
    # Add exclude patterns if specified
    if [ -n "$exclude_patterns" ]; then
        IFS=',' read -ra ADDR <<< "$exclude_patterns"
        for i in "${ADDR[@]}"; do
            RG_PREFIX+="--glob '!$i' "
        done
    fi
    
    INITIAL_QUERY="${*:-}"
    FZF_DEFAULT_COMMAND="$RG_PREFIX '$INITIAL_QUERY' $search_dir"
    
    if $preview; then
        fzf --ansi --disabled --query "$INITIAL_QUERY" \
            --bind "change:reload:$RG_PREFIX {q} $search_dir || true" \
            --delimiter : \
            --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
            --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'
    else
        fzf --ansi --disabled --query "$INITIAL_QUERY" \
            --bind "change:reload:$RG_PREFIX {q} $search_dir || true" \
            --delimiter :
    fi
}

# Perform the search and get the selected file
selected=$(perform_search)

# Check if a file was selected
if [ -n "$selected" ]; then
    # Extract the file path and line number
    file_path=$(echo "$selected" | cut -d: -f1)
    line_number=$(echo "$selected" | cut -d: -f2)

    # Open the file based on the flags
    if $open_in_vim; then
        vim "+$line_number" "$file_path"
    elif $open_in_neovim; then
        nvim "+$line_number" "$file_path"
    else
        echo "Selected: $file_path (Line $line_number)"
    fi
else
    echo "No file selected."
fi
