#git add .
#git commit -m "automatic configuration backup"
#git push -u origin main

# Check if there are any changes
if [[ $(git status --porcelain) ]]; then
    # Stage all changes
    git add .

    # Commit the changes with a timestamp
    git commit -m "Backup NixOS config $(date '+%Y-%m-%d %H:%M:%S')"

    # Push the changes to GitHub
    git push origin main
else
    echo "No changes to NixOS configuration."
fi
