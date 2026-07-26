#!/bin/bash
set -euo pipefail

PRODUCT_NAME="SlotLauncher"
CONFIG="${1:-release}"

swift build -c "$CONFIG"

BUILD_DIR=".build/$CONFIG"
APP_BUNDLE="$BUILD_DIR/$PRODUCT_NAME.app"

mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$PRODUCT_NAME" "$APP_BUNDLE/Contents/MacOS/$PRODUCT_NAME"

PLIST="Sources/$PRODUCT_NAME/Info.plist"
if [ -f "$PLIST" ]; then
    cp "$PLIST" "$APP_BUNDLE/Contents/Info.plist"
else
    cat > "$APP_BUNDLE/Contents/Info.plist" <<- EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$PRODUCT_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.slotlauncher.app</string>
    <key>CFBundleName</key>
    <string>$PRODUCT_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF
fi

echo ""
echo "✅  $APP_BUNDLE"
echo "cp -R \"$APP_BUNDLE\" /Applications/"
