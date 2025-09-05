#!/bin/bash

APP_NAME="SmartOrganizer"
APP_DIR="$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Building SmartOrganizer app bundle..."

# Clean up any existing app
rm -rf "$APP_DIR"

# Create app bundle structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Build the executable
echo "Compiling executable..."
./build.sh
if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

# Copy the executable to the app bundle
cp "build/$APP_NAME" "$MACOS_DIR/$APP_NAME"

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>SmartOrganizer</string>
    <key>CFBundleIdentifier</key>
    <string>com.fedsim.smartorganizer</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>SmartOrganizer</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

# Create a simple icon (using system icon)
echo "Creating app icon..."
iconutil --convert icns --output "$RESOURCES_DIR/AppIcon.icns" /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/DocumentsFolderIcon.icns 2>/dev/null || \
cp /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericDocumentIcon.icns "$RESOURCES_DIR/AppIcon.icns" 2>/dev/null || \
touch "$RESOURCES_DIR/AppIcon.icns"

# Set icon in Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$CONTENTS_DIR/Info.plist" 2>/dev/null

# Sign the app (ad-hoc signing for local use)
echo "Signing app..."
codesign --force --sign - "$APP_DIR"

echo "✅ App bundle created: $APP_DIR"
echo ""
echo "You can now:"
echo "1. Double-click $APP_DIR to run"
echo "2. Drag $APP_DIR to Applications folder"
echo "3. Run ./create_dmg.sh to create an installer DMG"