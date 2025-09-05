#!/bin/bash

APP_NAME="SmartOrganizer"
DMG_NAME="SmartOrganizer-1.0"
VOLUME_NAME="SmartOrganizer Installer"
DMG_DIR="dmg_temp"

echo "Creating DMG installer for SmartOrganizer..."

# First create the app bundle
if [ ! -d "$APP_NAME.app" ]; then
    echo "App bundle not found. Creating it first..."
    ./create_app.sh
    if [ $? -ne 0 ]; then
        echo "Failed to create app bundle!"
        exit 1
    fi
fi

# Clean up any existing DMG files
rm -f "$DMG_NAME.dmg"
rm -rf "$DMG_DIR"

# Create temporary directory for DMG contents
mkdir -p "$DMG_DIR"

# Copy app to DMG directory
cp -R "$APP_NAME.app" "$DMG_DIR/"

# Create a symbolic link to Applications folder
ln -s /Applications "$DMG_DIR/Applications"

# Create a simple background directory (optional)
mkdir -p "$DMG_DIR/.background"

# Create the DMG
echo "Building DMG..."
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    "$DMG_NAME.dmg"

# Clean up
rm -rf "$DMG_DIR"

if [ -f "$DMG_NAME.dmg" ]; then
    echo "✅ DMG created successfully: $DMG_NAME.dmg"
    echo ""
    echo "File size: $(du -h "$DMG_NAME.dmg" | cut -f1)"
    echo ""
    echo "Users can now:"
    echo "1. Double-click $DMG_NAME.dmg to mount it"
    echo "2. Drag SmartOrganizer to Applications folder"
    echo "3. Eject the DMG and run SmartOrganizer from Applications"
else
    echo "❌ Failed to create DMG"
    exit 1
fi