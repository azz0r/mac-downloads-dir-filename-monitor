#!/bin/bash

# Kill any existing instances
pkill -f SmartOrganizer 2>/dev/null

echo "Setting all generic files in Downloads to be old enough..."

# Find and update timestamps for generic pattern files
for file in ~/Downloads/IMG_*.* ~/Downloads/DSC*.* ~/Downloads/Screenshot*.* ~/Downloads/screencapture*.* ~/Downloads/download*.* ~/Downloads/temp*.* ~/Downloads/untitled*.* ~/Downloads/document*.* ~/Downloads/Invoice-*.* ~/Downloads/NXT*.png ~/Downloads/ChatGPT*.png; do
    if [ -f "$file" ]; then
        # Set file to be 2 hours old
        touch -t $(date -v-2H '+%Y%m%d%H%M') "$file"
        echo "Made eligible: $(basename "$file")"
    fi
done

echo ""
echo "Building and running SmartOrganizer..."
./build.sh

echo "Starting SmartOrganizer..."
./build/SmartOrganizer &
APP_PID=$!

sleep 3

echo "Triggering immediate rename check..."
# Wait for the timer to fire
sleep 65

echo ""
echo "Checking renamed files..."
ls -la ~/Downloads/*.{png,pdf,jpg,txt} 2>/dev/null | grep "2025-09-05" | head -20

kill $APP_PID 2>/dev/null
echo "Done!"
