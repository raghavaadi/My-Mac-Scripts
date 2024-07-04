#!/bin/bash

# Check if dialog is installed
if ! command -v dialog &> /dev/null; then
    echo "dialog is not installed. Please install it using Homebrew:"
    echo "brew install dialog"
    exit 1
fi

# Function to convert bytes to human-readable format
human_readable_size() {
    local size=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local unit_index=0
    while (( size > 1024 && unit_index < ${#units[@]} - 1 ))
    do
        size=$(( size / 1024 ))
        (( unit_index++ ))
    done
    echo "${size}${units[$unit_index]}"
}

# Function to get app size including supporting files
get_app_size() {
    local app_path="$1"
    local app_name=$(basename "$app_path" .app)
    local total_size=0

    # Calculate sizes
    local app_size=$(du -sk "$app_path" 2>/dev/null | cut -f1)
    local cache_size=$(du -sk ~/Library/Caches/*"$app_name"* 2>/dev/null | awk '{sum+=$1} END {print sum}')
    local support_size=$(du -sk ~/Library/Application\ Support/*"$app_name"* 2>/dev/null | awk '{sum+=$1} END {print sum}')
    local preferences_size=$(du -sk ~/Library/Preferences/*"$app_name"* 2>/dev/null | awk '{sum+=$1} END {print sum}')

    # Sum up total size
    total_size=$((app_size + cache_size + support_size + preferences_size))

    # Convert to human-readable format
    human_readable_size $((total_size * 1024))
}

# Get list of apps and their sizes
app_list=$(find /Applications -maxdepth 1 -name "*.app" | sort)
options=()
while IFS= read -r app; do
    app_name=$(basename "$app" .app)
    app_size=$(get_app_size "$app")
    options+=("$app_name" "$app_size" "off")
done <<< "$app_list"

# Display the list of apps with sizes and allow selection
selected_apps=$(dialog --stdout --separate-output --checklist "Select apps to uninstall (use space to select, enter to confirm):" 0 0 0 "${options[@]}")

# Check if user selected any apps
if [ -z "$selected_apps" ]; then
    echo "No apps selected for uninstallation."
    exit 0
fi

# Confirm uninstallation
dialog --yesno "Are you sure you want to uninstall the selected apps and ALL associated files?" 0 0
confirmation=$?

if [ $confirmation -eq 0 ]; then
    # Uninstall selected apps
    echo "$selected_apps" | while read -r app; do
        echo "Uninstalling $app and all associated files..."
        
        # Remove the main app
        sudo rm -rf "/Applications/${app}.app"
        
        # Remove associated files
        sudo find /Library/Application\ Support -name "*${app}*" -exec rm -rf {} +
        sudo find ~/Library/Application\ Support -name "*${app}*" -exec rm -rf {} +
        sudo find ~/Library/Caches -name "*${app}*" -exec rm -rf {} +
        sudo find ~/Library/Preferences -name "*${app}*" -exec rm -rf {} +
        sudo find ~/Library/Saved\ Application\ State -name "*${app}*" -exec rm -rf {} +
        sudo find ~/Library/WebKit -name "*${app}*" -exec rm -rf {} +
        sudo find ~/Library/Containers -name "*${app}*" -exec rm -rf {} +
        
        # Remove app-specific folders that might not be caught by the above
        sudo rm -rf ~/Library/Application\ Support/"$app"
        sudo rm -rf ~/Library/Caches/"$app"
        sudo rm -rf ~/Library/Preferences/"$app"
        
        echo "Uninstallation of $app and its associated files is complete."
        echo "----------------------------------------"
    done
    
    echo "Uninstallation process completed."
    echo "Note: Some apps may have additional hidden files or components. For mission-critical systems, always consult the app's official uninstallation instructions."
else
    echo "Uninstallation cancelled."
fi