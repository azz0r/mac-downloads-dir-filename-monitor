#!/bin/bash

# SmartOrganizer Build Script
# This script compiles the Swift files directly without using Xcode

echo "Building SmartOrganizer..."

# Create build directory
mkdir -p build

# Compile Swift files
swiftc -o build/SmartOrganizer \
  -target x86_64-apple-macos14.0 \
  -framework Cocoa \
  -framework SwiftUI \
  -framework Vision \
  -framework NaturalLanguage \
  -framework PDFKit \
  -framework CoreML \
  -framework ServiceManagement \
  SmartOrganizer/SmartOrganizerApp.swift \
  SmartOrganizer/AppDelegate.swift \
  SmartOrganizer/FileMonitor.swift \
  SmartOrganizer/IntelligenceManager.swift \
  SmartOrganizer/FileOrganizer.swift \
  SmartOrganizer/PreferencesWindow.swift

if [ $? -eq 0 ]; then
    echo "Build successful! Binary located at: build/SmartOrganizer"
    echo ""
    echo "To run the app:"
    echo "  ./build/SmartOrganizer"
else
    echo "Build failed!"
    exit 1
fi