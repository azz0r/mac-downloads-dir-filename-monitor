#!/bin/bash

# Kill any existing instances
pkill -f SmartOrganizer 2>/dev/null

# Create test files with generic names
echo "Creating test files in Downloads..."

# Create a test invoice
echo "Invoice #12345
From: Microsoft Corporation
Bill To: John Smith
Date: $(date '+%Y-%m-%d')
Amount: \$1,299.00
Product: Surface Pro 9
Description: Purchase of Surface Pro 9 with keyboard" > ~/Downloads/download.txt

# Create a test receipt  
echo "RECEIPT
Store: Best Buy Electronics
Date: $(date '+%Y-%m-%d')
Transaction ID: BB-2025-0105
Items:
- USB-C Cable: \$19.99
- Wireless Mouse: \$49.99
Total: \$69.98
Thank you for shopping at Best Buy!" > ~/Downloads/temp.txt

# Create a test document with meeting notes
echo "Meeting Notes
Date: $(date '+%Y-%m-%d')
Attendees: Sarah Johnson, Mike Chen, Emily Davis
Topic: Q1 Product Roadmap Planning
Action Items:
- Update timeline for feature release
- Schedule follow-up with engineering team
- Review budget allocation
Next Meeting: Next Tuesday 2pm" > ~/Downloads/untitled.txt

# Set creation times to be older than 1 minute
touch -t $(date -v-2H '+%Y%m%d%H%M') ~/Downloads/download.txt
touch -t $(date -v-2H '+%Y%m%d%H%M') ~/Downloads/temp.txt
touch -t $(date -v-2H '+%Y%m%d%H%M') ~/Downloads/untitled.txt

echo "Test files created:"
ls -la ~/Downloads/download.txt ~/Downloads/temp.txt ~/Downloads/untitled.txt

# Build and run SmartOrganizer
echo "Building SmartOrganizer..."
./build.sh

echo "Running SmartOrganizer..."
./build/SmartOrganizer &
APP_PID=$!

# Wait a moment for app to start
sleep 3

echo "Waiting for file monitoring to process files..."
# The app checks every minute, so we wait
sleep 65

echo "Checking if files were renamed..."
ls -la ~/Downloads/*.txt | grep -E "(Invoice|Receipt|Document|Meeting)" | head -10

# Kill the app
kill $APP_PID 2>/dev/null

echo "Test complete!"
