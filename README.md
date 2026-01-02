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

## Quick Start

### Prerequisites

On Alpine Linux:
```bash
./scripts/setup-builder.sh
```

Or use Docker:
```bash
docker run -it --rm -v $(pwd):/work -w /work alpine:latest sh
apk add alpine-sdk
```

### Generate Signing Keys (first time only)

```bash
abuild-keygen -a -i -n
# Keys created at ~/.abuild/
# Copy public key to keys/ directory
cp ~/.abuild/*.rsa.pub keys/
```

### Build a Package

1. Copy the pre-built binary into the package directory. Some packages will download precompiled binaries and can skip this step.
```bash
cp /path/to/shadowdhcp packages/shadowdhcp/
```

2. Build:
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

### Publish to Remote

```bash
./scripts/publish.sh stable
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
