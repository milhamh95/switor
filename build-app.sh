#!/bin/bash
set -e

APP_NAME="Switor"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Building $APP_NAME..."

# Build release binary
swift build -c release

echo "Creating app bundle..."

# Clean previous bundle
rm -rf "$APP_BUNDLE"

# Create directory structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/"

# Copy Info.plist
cp "Switor/Info.plist" "$CONTENTS_DIR/"

# Copy app icon
cp "icon/big-screen-icon.icns" "$RESOURCES_DIR/AppIcon.icns"

# Copy menu bar icon
cp "menubar-icon/big-screen.png" "$RESOURCES_DIR/MenuBarIcon.png"

# Create PkgInfo
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Sign the app (ad-hoc signing for local use)
codesign --force --deep --sign - "$APP_BUNDLE"

echo ""
echo "Build complete: $APP_BUNDLE"
echo ""
echo "To run: open $APP_BUNDLE"
echo "To install: cp -r $APP_BUNDLE /Applications/"
