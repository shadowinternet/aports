#!/bin/sh
# Setup an Alpine build environment
set -eu

echo "Installing Alpine SDK, doas, and SSH client..."
apk add --no-cache alpine-sdk doas openssh-client

echo "Creating abuild user if needed..."
if ! id abuild >/dev/null 2>&1; then
    adduser -D -G abuild -s /bin/sh abuild
    echo "permit nopass abuild" >> /etc/doas.d/abuild.conf
fi

echo "Setup complete. Run 'abuild-keygen -a -i -n' to generate signing keys."
