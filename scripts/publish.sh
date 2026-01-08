#!/bin/sh
# Publish packages to the remote repository
# Usage: ./scripts/publish.sh [channel]
set -eu

CHANNEL="${1:-stable}"
REMOTE_HOST="apk.shadowinter.net"
REMOTE_USER="apk"
REMOTE_BASE="/var/www/apk"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_REPO="$HOME/packages/shadow-aports/packages"

echo "Publishing to channel: $CHANNEL"

for arch_dir in "$LOCAL_REPO"/*/; do
    if [ -d "$arch_dir" ]; then
        arch="$(basename "$arch_dir")"

        if [ ! -f "$arch_dir/APKINDEX.tar.gz" ]; then
            echo "Warning: No APKINDEX.tar.gz in $arch_dir, generating..."
            "$SCRIPT_DIR/index-repo.sh" "$arch_dir"
        fi

        echo "Uploading $arch packages..."

        # Create remote directory
        ssh "${REMOTE_USER}@${REMOTE_HOST}" \
            "mkdir -p ${REMOTE_BASE}/${CHANNEL}/${arch}"

        # Sync packages (trailing slash on source copies contents into dest)
        rsync -avz --delete \
            "$arch_dir" \
            "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BASE}/${CHANNEL}/${arch}/"
    fi
done

echo ""
echo "Publish complete. Repository available at:"
echo "  https://${REMOTE_HOST}/${CHANNEL}"
