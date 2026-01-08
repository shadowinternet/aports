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
abuild-keygen -a -i -n
cp ~/.abuild/*.rsa.pub keys/
```

The `-i` flag installs the public key to `/etc/apk/keys/` (required for index generation). Keys are also stored in `~/.abuild/`.

### 5. Configure Git Authentication

To push changes (e.g., updated checksums) from the builder to GitHub:

#### Option A: Deploy Key (recommended)

Deploy keys are repository-specific and don't require a personal GitHub account.

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "abuild@builder" -f ~/.ssh/aports_deploy

# Show public key
cat ~/.ssh/aports_deploy.pub
```

Add the public key to the repository: **Repository → Settings → Deploy keys → Add deploy key** (enable "Allow write access")

Configure SSH to use the deploy key:
```bash
cat >> ~/.ssh/config << 'EOF'
Host github.com
    IdentityFile ~/.ssh/aports_deploy
    IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config
```

Switch the remote to SSH:
```bash
git remote set-url origin git@github.com:shadowinternet/aports.git
```

#### Option B: Personal SSH Key

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "abuild@builder"

# Show public key to add to GitHub
cat ~/.ssh/id_ed25519.pub
```

Add the public key to your GitHub account: **Settings → SSH and GPG keys → New SSH key**

Then switch the remote to SSH:
```bash
git remote set-url origin git@github.com:shadowinternet/aports.git
```

#### Option C: Personal Access Token (HTTPS)

1. On GitHub: **Settings → Developer settings → Personal access tokens → Generate new token** with `repo` scope
2. On the builder:
```bash
git config --global credential.helper store
git push
# Enter username and paste token as password
```

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

Output: `~/packages/shadow-aports/packages/x86_64/shadowdhcp-*.apk`

### Build All Packages

```bash
./scripts/build-all.sh
```

### Generate Repository Index

```bash
./scripts/index-repo.sh ~/packages/shadow-aports/packages/x86_64
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
passwd apk  # Set a password to unlock the account (required for SSH key auth)
mkdir -p /var/www/apk
chown apk:apk /var/www/apk
```

#### 2. Install and Enable SSH Server

```bash
apk add openssh rsync
rc-update add sshd
rc-service sshd start
```

Ensure `PubkeyAuthentication yes` is set in `/etc/ssh/sshd_config`.

#### 3. Install Caddy

```bash
apk add caddy
```

#### 4. Configure Caddy

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

#### 5. Copy Public Signing Key

The repository public key should be accessible at `https://apk.shadowinter.net/keys/shadowinternet.rsa.pub`:

```bash
mkdir -p /var/www/apk/keys
cp shadowinternet.rsa.pub /var/www/apk/keys/
chown -R apk:apk /var/www/apk/keys
```

### SSH Key Setup (Builder to Hoster)

To enable publishing from the builder to the hosting server, use the same deploy key from step 5.

#### On the Builder (as abuild user)

Show the public key:
```bash
cat ~/.ssh/aports_deploy.pub
```

Copy the output (starts with `ssh-ed25519 ...`).

Add the hosting server to your SSH config:
```bash
cat >> ~/.ssh/config << 'EOF'

Host apk.shadowinter.net
    IdentityFile ~/.ssh/aports_deploy
    User apk
EOF
```

#### On the Hosting Server (as root)

```bash
# Create .ssh directory for apk user
mkdir -p /home/apk/.ssh
chmod 700 /home/apk/.ssh

# Add the builder's public key (paste the key from above)
echo "ssh-ed25519 AAAA... abuild@builder" >> /home/apk/.ssh/authorized_keys
chmod 600 /home/apk/.ssh/authorized_keys
chown -R apk:apk /home/apk/.ssh
```

#### Test Connection (from builder)

```bash
ssh apk.shadowinter.net "echo 'SSH connection working'"
```

### Client Setup

```bash
# Install public key
wget -O /etc/apk/keys/shadowinternet.rsa.pub \
    https://apk.shadowinter.net/keys/shadowinternet.rsa.pub

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
