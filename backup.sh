#!/run/current-system/sw/bin/bash

REPO_PATH="/home/radekp/.dotfiles"

# Change to the Git repository directory
cd $REPO_PATH || exit 1  # Exit if the directory does not exist

$GIT config --global --add safe.directory $REPO_PATH

# Check if there are any changes
if [[ $($GIT status --porcelain) ]]; then
    # Stage all changes
    $GIT add .

    # Commit the changes with a timestamp
    $GIT commit -m "Backup NixOS config $(date '+%Y-%m-%d %H:%M:%S')"

    # Push the changes to GitHub
    $GIT push origin main
else
    exit 0
fi
