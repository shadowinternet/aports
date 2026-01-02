# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is an Alpine Linux package repository (aports-style) for Shadow infrastructure software. Packages are built using Alpine's `abuild` system and published to `apk.shadowinter.net`.

## Build Commands

```bash
# Setup build environment (Alpine only)
./scripts/setup-builder.sh

# Generate signing keys (first time)
abuild-keygen -a -i -n
cp ~/.abuild/*.rsa.pub keys/

# Build a single package
./scripts/build-package.sh <package-name>

# Build all packages
./scripts/build-all.sh

# Generate repository index
./scripts/index-repo.sh ~/packages/shadow-aports/x86_64

# Publish to remote (stable or edge channel)
./scripts/publish.sh stable
```

## Architecture

Packages follow Alpine's aports structure:

- `packages/<name>/APKBUILD` - Package build definition
- `packages/<name>/<name>.initd` - OpenRC init script (optional)
- `packages/<name>/<name>.confd` - Service configuration (optional)
- `packages/<name>/<name>.pre-install` - Pre-install hook
- `packages/<name>/<name>.post-install` - Post-install hook

Binary packages require copying the pre-built binary into the package directory before building:
```bash
cp /path/to/binary packages/<name>/
./scripts/build-package.sh <name>
```

Built packages output to `~/packages/shadow-aports/<arch>/`.

## APKBUILD Notes

- `options="!check"` is used for binary packages without test suites
- `REPODEST` is set to `$HOME/packages/shadow-aports` for consistent output
- Checksums are auto-updated by `build-package.sh` when support files exist
