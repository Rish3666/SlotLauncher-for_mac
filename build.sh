#!/bin/bash
set -euo pipefail

PRODUCT_NAME="SlotLauncher"
CONFIG="${1:-release}"

# Find Xcode's Swift toolchain (needed for macro plugins)
SWIFT=""
for candidate in \
    "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift" \
    "/Users/rishvarma/Downloads/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift"; do
    if [ -x "$candidate" ]; then
        SWIFT="$candidate"
        break
    fi
done

if [ -z "$SWIFT" ]; then
    SWIFT=$(xcrun -f swift 2>/dev/null || echo "")
fi

if [ -z "$SWIFT" ] || ! "$SWIFT" build --version &>/dev/null; then
    echo "❌  Swift toolchain not found. Install Xcode from the Mac App Store."
    exit 1
fi

echo "Building with: $SWIFT"
"$SWIFT" build -c "$CONFIG"

APP_BUNDLE="./$PRODUCT_NAME.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp ".build/$CONFIG/$PRODUCT_NAME" "$APP_BUNDLE/Contents/MacOS/$PRODUCT_NAME"

PLIST="Sources/$PRODUCT_NAME/Info.plist"
if [ -f "$PLIST" ]; then
    cp "$PLIST" "$APP_BUNDLE/Contents/Info.plist"
else
    /usr/libexec/PlistBuddy -c "Add CFBundleIdentifier string com.slotlauncher.app" \
        -c "Add CFBundleName string $PRODUCT_NAME" \
        -c "Add CFBundleExecutable string $PRODUCT_NAME" \
        -c "Add CFBundlePackageType string APPL" \
        -c "Add CFBundleVersion string 1" \
        -c "Add CFBundleShortVersionString string 1.0.0" \
        -c "Add LSUIElement bool false" \
        -c "Add NSHighResolutionCapable bool true" \
        "$APP_BUNDLE/Contents/Info.plist" >/dev/null 2>&1
fi

xattr -cr "$APP_BUNDLE" 2>/dev/null || true

echo ""
echo "✅  $APP_BUNDLE ($(du -sh "$APP_BUNDLE" | cut -f1))"
echo ""
echo "   cp -R \"$APP_BUNDLE\" /Applications/"
