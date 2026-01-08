# shadow-aports

Alpine Linux package repository for Shadow Internet infrastructure software.

## Repository Structure

```
shadow-aports/
├── packages/           # Package definitions (APKBUILD + support files)
│   └── shadowdhcp/
├── scripts/            # Build and publish tooling
├── keys/               # Public keys (private keys stored securely elsewhere)
└── .github/workflows/  # CI/CD automation
```

## Builder Setup (Alpine Linux)

### 1. Install Build Environment (as root)

```bash
./scripts/setup-builder.sh
```

This installs the Alpine SDK and creates the `abuild` user with sudo access.

### 2. Switch to Build User

```bash
su - abuild
```

### 3. Clone Repository

```bash
git clone https://github.com/shadowinternet/aports.git ~/aports
cd ~/aports
```

### 4. Generate Signing Keys

```bash
abuild-keygen -a -n
cp ~/.abuild/*.rsa.pub keys/

# Optional: install key locally to test packages on the builder
# doas cp ~/.abuild/*.rsa.pub /etc/apk/keys/
```

Keys are stored in `~/.abuild/` and the public key should be copied to `keys/` for distribution.

### Alternative: Docker

```bash
docker run -it --rm -v $(pwd):/work -w /work alpine:latest sh
apk add alpine-sdk
adduser -D builder
su - builder
# Then generate keys and build as above
```

## Building Packages

### Build a Single Package

Some packages download precompiled binaries automatically. For packages requiring a local binary:
```bash
cp /path/to/shadowdhcp packages/shadowdhcp/
```

Build:
```bash
./scripts/build-package.sh shadowdhcp
```

Output: `~/packages/shadow-aports/x86_64/shadowdhcp-*.apk`

### Build All Packages

```bash
./scripts/build-all.sh
```

### Generate Repository Index

```bash
./scripts/index-repo.sh ~/packages/shadow-aports/x86_64
```

## Publishing

### Publish to Remote

```bash
./scripts/publish.sh stable
```

Publishes to the `stable` channel. Use `edge` for development builds:
```bash
./scripts/publish.sh edge
```

## Adding a New Package

1. Create package directory:
```bash
mkdir -p packages/mypackage
```

2. Create APKBUILD and support files:
```bash
packages/mypackage/
├── APKBUILD
├── mypackage.initd      # OpenRC service (optional)
├── mypackage.confd      # Service config (optional)
├── mypackage.pre-install
└── mypackage.post-install
```

3. Build and test:
```bash
./scripts/build-package.sh mypackage
```

## Repository Hosting

Packages are hosted at `https://apk.shadowinter.net/`

### Channels

| Channel | Purpose |
|---------|---------|
| `stable` | Production releases |
| `edge` | Development/testing |

### Hosting Server Setup

On the hosting server (apk.shadowinter.net):

#### 1. Create Deploy User

```bash
adduser -D apk
mkdir -p /var/www/apk
chown apk:apk /var/www/apk
```

#### 2. Install Caddy

```bash
# Alpine
apk add caddy

# Or download from https://caddyserver.com/download
```

#### 3. Configure Caddy

Edit `/etc/caddy/Caddyfile`:

```
apk.shadowinter.net {
    root * /var/www/apk
    file_server browse
}
```

Enable and start Caddy:

```bash
rc-update add caddy
rc-service caddy start
```

#### 4. Copy Public Signing Key

The repository public key should be accessible at `https://apk.shadowinter.net/keys/shadow.rsa.pub`:

```bash
mkdir -p /var/www/apk/keys
cp shadow.rsa.pub /var/www/apk/keys/
chown -R apk:apk /var/www/apk/keys
```

### SSH Key Setup (Builder to Hoster)

To enable publishing from the builder to the hosting server:

#### On the Builder (as abuild user)

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "abuild@builder"

# Copy to hosting server
ssh-copy-id apk@apk.shadowinter.net

# Test connection
ssh apk@apk.shadowinter.net "echo 'SSH connection working'"
```

#### On the Hosting Server

Ensure the `apk` user's authorized_keys file has the builder's public key:

```bash
cat /home/apk/.ssh/authorized_keys
```

### Client Setup

```bash
# Install public key
wget -O /etc/apk/keys/shadow.rsa.pub \
    https://apk.shadowinter.net/keys/shadow.rsa.pub

# Add repository
echo "https://apk.shadowinter.net/stable" >> /etc/apk/repositories

# Install packages
apk update
apk add shadowdhcp
```

## Packages

| Package | Description |
|---------|-------------|
| shadowdhcp | Reservation-only DHCPv4/DHCPv6 server |

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `setup-builder.sh` | Install Alpine SDK and create build user |
| `build-package.sh` | Build a single package |
| `build-all.sh` | Build all packages |
| `index-repo.sh` | Generate and sign APKINDEX |
| `publish.sh` | Upload to remote repository |
