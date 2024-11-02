
#!/bin/bash
# Script to capture the current screen and save it to a directory

SAVE_DIR=~/Pictures/Screenshots
mkdir -p "$SAVE_DIR"
FILENAME="screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"

flameshot full -p "$SAVE_DIR/$FILENAME"
