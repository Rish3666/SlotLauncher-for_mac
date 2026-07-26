#!/bin/bash
set -euo pipefail

PRODUCT_NAME="SlotLauncher"
DEST="./$PRODUCT_NAME.app"

echo "Looking for built $PRODUCT_NAME.app in Xcode DerivedData..."

# Find the most recently built .app in DerivedData
APP=$(find ~/Library/Developer/Xcode/DerivedData \
    -name "$PRODUCT_NAME.app" -type d \
    -not -path "*/SourcePackages/*" \
    -not -path "*/.build/*" \
    -print0 2>/dev/null | xargs -0 ls -dt 2>/dev/null | head -1)

if [ -z "$APP" ]; then
    echo "❌  No $PRODUCT_NAME.app found in DerivedData."
    echo ""
    echo "Build it first in Xcode:"
    echo "  1. open Package.swift"
    echo "  2. Product → Build (⌘B)"
    echo "  3. Run this script again"
    exit 1
fi

rm -rf "$DEST"
cp -R "$APP" "$DEST"

echo "✅  $DEST"
echo "   (from $APP)"
echo ""
echo "Now drag $PRODUCT_NAME.app to Applications, or:"
echo "  cp -R \"$DEST\" /Applications/"
