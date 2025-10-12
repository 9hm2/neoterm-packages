# NeoTerm Packages

Automated package building system for [NeoTerm](https://github.com/9hm2/NeoTerm) terminal emulator.

This is a fork of [termux-packages](https://github.com/termux/termux-packages) configured to build packages with `io.neoterm` prefix instead of `com.termux`.

## Key Differences from Termux

- **Package prefix**: `io.neoterm` instead of `com.termux`
- **Install path**: `/data/data/io.neoterm/files/usr` instead of `/data/data/com.termux/files/usr`
- **Automated daily builds**: Syncs with termux-packages and builds changed packages
- **Direct publishing**: Automatically publishes to [NeoTerm-repo](https://github.com/9hm2/NeoTerm-repo)

## Architecture

```
┌──────────────────────┐
│ termux/termux-packages│
│   (upstream source)   │
└──────────┬────────────┘
           │ daily sync
           ↓
┌──────────────────────┐
│ 9hm2/neoterm-packages│ (this repo)
│ - io.neoterm prefix  │
│ - Automated builds   │
└──────────┬────────────┘
           │ publish
           ↓
┌──────────────────────┐
│ 9hm2/NeoTerm-repo    │
│   (APT repository)   │
└──────────────────────┘
           │
           ↓
       NeoTerm App
       (users install)
```

## Automated Build System

### Daily Sync & Build
Every 24 hours (00:00 UTC):
1. **Sync**: Fetch latest changes from termux-packages
2. **Detect**: Identify modified packages
3. **Build**: Compile changed packages for aarch64
4. **Publish**: Push to NeoTerm-repo

See: `.github/workflows/neoterm-daily-build.yml`

### Configuration

The key configuration change that makes this work:

**File**: `scripts/properties.sh`
```bash
# Changed from:
# TERMUX_APP__PACKAGE_NAME="com.termux"

# To:
TERMUX_APP__PACKAGE_NAME="io.neoterm"
```

This single change ensures all packages are built with NeoTerm paths.

## Using NeoTerm Packages

In the NeoTerm app, packages are automatically available:

```bash
apt update
apt install bash vim git python nodejs
```

No Termux repositories needed - all packages use `io.neoterm` prefix!

## Building Packages Locally

### Prerequisites
- Docker installed
- Linux or macOS (or WSL on Windows)

### Build a package

```bash
# Clone this repository
git clone https://github.com/9hm2/neoterm-packages
cd neoterm-packages

# Build specific package
./scripts/run-docker.sh ./build-package.sh -a aarch64 bash

# Build multiple packages
./scripts/run-docker.sh ./build-package.sh -a aarch64 bash coreutils vim
```

### Build output
Built packages are in `output/` directory:
```
output/
├── bash_5.2.21_aarch64.deb
├── coreutils_9.5_aarch64.deb
└── ...
```

All `.deb` files will have paths configured for `/data/data/io.neoterm/`.

## Package Categories

### Essential packages (always built)
- `bash` - Shell
- `coreutils` - Core utilities
- `dpkg` - Package manager
- `apt` - Package installer
- `grep`, `sed`, `tar`, `gzip` - Text/archive tools

### Additional packages (on-demand)
- `vim`, `nano`, `emacs` - Text editors
- `git`, `openssh`, `rsync` - Development tools
- `python`, `nodejs`, `ruby` - Programming languages
- `ffmpeg`, `imagemagick` - Media tools
- `nginx`, `apache2` - Web servers

## Repository Structure

```
neoterm-packages/
├── .github/
│   └── workflows/
│       ├── neoterm-daily-build.yml    # Daily build automation
│       └── packages.yml                # Standard termux workflow
├── scripts/
│   ├── properties.sh                   # ⭐ Key config: io.neoterm prefix
│   ├── run-docker.sh                   # Docker build wrapper
│   └── ...
├── packages/                           # Package definitions (2000+)
│   ├── bash/build.sh
│   ├── vim/build.sh
│   └── ...
├── build-package.sh                    # Main build script
└── NEOTERM-README.md                   # This file
```

## Maintaining the Fork

### Syncing with upstream

The daily workflow automatically syncs, but you can manually sync:

```bash
git remote add upstream https://github.com/termux/termux-packages.git
git fetch upstream
git merge upstream/master
git push origin master
```

### Adding new packages

No special steps needed! Just sync with upstream and the package will be available.

### Modifying package build

Edit the package's `build.sh` file in `packages/<name>/build.sh` and commit.

## CI/CD Secrets Required

For the automated workflow to work, set these GitHub secrets:

- `GITHUB_TOKEN` - Automatically provided by GitHub Actions
- `NEOTERM_REPO_TOKEN` - Personal access token with write access to NeoTerm-repo

## Technical Details

### Why fork instead of path rewriting?

**Previous approach** (complex):
1. Build with com.termux prefix
2. Extract .deb files
3. Rewrite all paths with sed
4. Repackage .deb files

**Current approach** (simple):
1. Change one line: `TERMUX_APP__PACKAGE_NAME="io.neoterm"`
2. Build normally
3. Packages automatically have correct paths ✅

### Path examples

With `TERMUX_APP__PACKAGE_NAME="io.neoterm"`, packages are built with:

```bash
# Binaries
/data/data/io.neoterm/files/usr/bin/bash

# Libraries
/data/data/io.neoterm/files/usr/lib/libc.so

# Configuration
/data/data/io.neoterm/files/usr/etc/bash.bashrc

# Scripts have correct shebang
#!/data/data/io.neoterm/files/usr/bin/bash
```

### Package format

Standard Debian `.deb` packages:
- **control.tar.gz**: Package metadata
- **data.tar.gz**: Files to install
- All paths under `/data/data/io.neoterm/`

## Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test locally with Docker
5. Submit a pull request

## Links

- [NeoTerm App](https://github.com/9hm2/NeoTerm) - Terminal emulator
- [NeoTerm-repo](https://github.com/9hm2/NeoTerm-repo) - APT repository
- [termux-packages](https://github.com/termux/termux-packages) - Upstream source

## License

Same as termux-packages - varies by package. Most packages are GPL/BSD/MIT licensed.

---

**Automated builds powered by GitHub Actions** 🤖
