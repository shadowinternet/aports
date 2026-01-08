#!/bin/sh
# Build all packages in the repository
set -eu

# Verify abuild is configured (signing key exists)
if ! ls "$HOME"/.abuild/*.rsa >/dev/null 2>&1; then
    echo "Error: abuild not configured. Run 'abuild-keygen -a -n' first." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Building all packages..."

for pkg_dir in "$REPO_ROOT"/packages/*/; do
    if [ -f "$pkg_dir/APKBUILD" ]; then
        pkg_name="$(basename "$pkg_dir")"
        echo ""
        echo "=== Building $pkg_name ==="
        "$SCRIPT_DIR/build-package.sh" "$pkg_name"
    fi
done

echo ""
echo "All packages built successfully."
