#!/bin/bash

# Function to check a file for echo statements
check_file() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "Checking $file..."
        grep -n "echo.*ANDROID_HOME\|echo.*HOME\|echo.*HOMEBREW" "$file"
        if [ $? -eq 0 ]; then
            echo "Found potential issue in $file. Do you want to comment out these lines? (y/n)"
            read answer
            if [ "$answer" = "y" ]; then
                sed -i '.bak' '/echo.*ANDROID_HOME/s/^/# /' "$file"
                sed -i '.bak' '/echo.*HOME/s/^/# /' "$file"
                sed -i '.bak' '/echo.*HOMEBREW/s/^/# /' "$file"
                echo "Lines commented out in $file. A backup has been created as ${file}.bak"
            fi
        else
            echo "No issues found in $file."
        fi
    fi
}

# Check common Zsh startup files
check_file "$HOME/.zshrc"
check_file "$HOME/.zprofile"
check_file "$HOME/.zshenv"
check_file "$HOME/.zlogin"

echo "Script completed. If you commented out any lines, restart your terminal or run 'source ~/.zshrc' to apply changes."
echo "If the issue persists, there might be other files sourced by your Zsh configuration that are causing this output."