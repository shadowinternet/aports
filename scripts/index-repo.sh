#!/bin/sh
# Generate and sign APKINDEX for a repository
# Usage: ./scripts/index-repo.sh <repo-path> [signing-key]
set -eu

if [ $# -lt 1 ]; then
    echo "Usage: $0 <repo-path> [signing-key]"
    echo "Example: $0 ~/packages/shadow-aports/x86_64"
    echo "Example: $0 ~/packages/shadow-aports/x86_64 ~/.abuild/key.rsa"
    exit 1
fi

REPO_PATH="$1"
SIGNING_KEY="${2:-}"

if [ ! -d "$REPO_PATH" ]; then
    echo "Error: Repository path not found: $REPO_PATH"
    exit 1
fi

cd "$REPO_PATH"

# Check for packages
if ! ls *.apk >/dev/null 2>&1; then
    echo "Error: No .apk files found in $REPO_PATH"
    exit 1
fi

echo "Generating APKINDEX for $REPO_PATH..."
apk index -o APKINDEX.tar.gz *.apk

if [ -n "$SIGNING_KEY" ]; then
    echo "Signing with key: $SIGNING_KEY"
    abuild-sign -k "$SIGNING_KEY" APKINDEX.tar.gz
else
    echo "Signing with default key..."
    abuild-sign APKINDEX.tar.gz
fi

echo ""
echo "Repository index created:"
ls -la APKINDEX.tar.gz
echo ""
echo "Packages in index:"
tar -tzf APKINDEX.tar.gz
