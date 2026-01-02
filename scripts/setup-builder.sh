#!/bin/sh
# Setup an Alpine build environment
set -eu

echo "Installing Alpine SDK..."
apk add --no-cache alpine-sdk sudo

echo "Creating abuild user if needed..."
if ! id abuild >/dev/null 2>&1; then
    adduser -D abuild
    addgroup abuild abuild
    echo "abuild ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/abuild
fi

echo "Setup complete. Run 'abuild-keygen -a -i -n' to generate signing keys."
