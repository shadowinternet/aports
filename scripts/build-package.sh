#!/bin/sh
# Build a single package
# Usage: ./scripts/build-package.sh <package-name>
set -eu

if [ $# -lt 1 ]; then
    echo "Usage: $0 <package-name>"
    echo "Example: $0 shadowdhcp"
    exit 1
fi

PACKAGE="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PKG_DIR="$REPO_ROOT/packages/$PACKAGE"

if [ ! -d "$PKG_DIR" ]; then
    echo "Error: Package directory not found: $PKG_DIR"
    exit 1
fi

if [ ! -f "$PKG_DIR/APKBUILD" ]; then
    echo "Error: APKBUILD not found in $PKG_DIR"
    exit 1
fi

echo "Building package: $PACKAGE"
cd "$PKG_DIR"

# Update checksums if sources exist
if ls ./*.initd ./*.confd *.json 2>/dev/null | head -1 >/dev/null; then
    echo "Updating checksums..."
    abuild checksum
fi

# Build the package
abuild -r

echo ""
echo "Build complete. Package location:"
ls -la ~/packages/shadow-aports/*/"$PACKAGE"-*.apk 2>/dev/null || \
ls -la ~/packages/*/"$PACKAGE"-*.apk 2>/dev/null || \
echo "Check ~/packages/ for output"
