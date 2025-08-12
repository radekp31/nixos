#!/nix/store/lb33m49aslmvkx5l4xrkiy7m6nbh2kqf-bash-interactive-5.3p0/bin/bash
# Check tools
#
# Get windows list in JSON
windows=$(niri msg --json windows | jq -r '.[] | "\(.id)\t\(.app_id // "unknown") \(.title // "no-title")"')

# Show rofi menu
selection=$(echo "$windows" | rofi -dmenu -i -p "Window:")

# Exit if no selection
[ -z "$selection" ] && exit 0

# Extract window ID
win_id=$(echo "$selection" | cut -f1)

# Focus selected window
niri msg action focus-window --id "$win_id"
