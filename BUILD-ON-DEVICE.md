# NeoTerm On-Device Build Guide

Build all packages directly in NeoTerm app on your Android device.

## Prerequisites

1. **Storage**: At least 50GB free space (recommended: 100GB+)
2. **RAM**: 4GB+ recommended
3. **Time**: Full build takes 2-10 days depending on device

## Required Packages

Install build dependencies first:

```bash
pkg install -y build-essential python cmake ninja git
```

## Usage

### Build All Packages

```bash
cd ~/neoterm-packages
./build-all-on-device.sh
```

### Options

```bash
./build-all-on-device.sh [OPTIONS]

Options:
  -a ARCH   Architecture (aarch64, arm, i686, x86_64) [default: aarch64]
  -d        Build with debug symbols
  -s        Skip installing dependencies (faster but may fail)
  -o DIR    Output directory [default: output/]
  -c        Continue from last build (resume after failure)
  -h        Show help
```

### Examples

```bash
# Build all packages for aarch64 (default)
./build-all-on-device.sh

# Build with custom output directory
./build-all-on-device.sh -o /sdcard/neoterm-debs

# Resume after failure or interruption
./build-all-on-device.sh -c

# Build without debug symbols (smaller packages)
./build-all-on-device.sh
```

## Build Process

1. **Generate build order**: Uses `buildorder.py` to determine dependency order
2. **Build packages sequentially**: One at a time to avoid conflicts
3. **Install dependencies**: Automatically installs deps with `-i` flag
4. **Output**: .deb files saved to `output/` directory
5. **Resume capability**: Can resume if interrupted

## Monitoring Progress

The script shows:
- Current package being built
- Progress: X/2005 packages
- Success/Failed/Skipped counts
- Build time per package

## Logs

All logs saved to: `~/.termux-build/_buildall-aarch64/`

- `ALL.out` - Combined stdout
- `ALL.err` - Combined stderr
- `{package}.out` - Per-package stdout
- `{package}.err` - Per-package stderr
- `buildstatus.txt` - Successfully built packages
- `failed-packages.txt` - Failed packages list

## Handling Failures

If a package fails:
1. Script asks if you want to continue
2. Failed package logged to `failed-packages.txt`
3. Build continues with next package
4. Use `-c` flag later to skip already-built packages

## Tips

### Save Battery
```bash
# Prevent screen timeout
termux-wake-lock

# When done
termux-wake-unlock
```

### Monitor in Background
```bash
# Start build in tmux/screen
tmux new -s build
./build-all-on-device.sh

# Detach: Ctrl+B, D
# Reattach: tmux attach -t build
```

### Disk Space Management

Check space regularly:
```bash
df -h /data
```

Clean old builds:
```bash
rm -rf ~/.termux-build/_buildall-aarch64/*.{out,err}
```

### Speed Up Build

1. **Skip dependencies**: `-s` flag (risky - may cause failures)
2. **Exclude large packages**: Edit `buildorder.txt` to remove rust, llvm, chromium
3. **Use swap**: Add swap file if low RAM

## Output

After successful build:
- .deb files in `output/` directory
- Can be copied to NeoTerm-repo for distribution
- Or installed locally with `dpkg -i package.deb`

## Estimated Times

Based on device specs:

| Device | CPU | RAM | Time |
|--------|-----|-----|------|
| High-end | Snapdragon 8+ Gen 1 | 12GB | 2-3 days |
| Mid-range | Snapdragon 7+ Gen 2 | 8GB | 4-6 days |
| Low-end | Snapdragon 6 Gen 1 | 4GB | 8-10 days |

## Known Issues

1. **Large packages**: rust, llvm, chromium may fail due to RAM limits
2. **Thermal throttling**: Device may slow down when hot
3. **Storage**: Some packages need 5GB+ free space during build

## Troubleshooting

### Out of Memory
```bash
# Add swap
fallocate -l 4G /sdcard/swapfile
chmod 600 /sdcard/swapfile
mkswap /sdcard/swapfile
swapon /sdcard/swapfile
```

### Build Hangs
- Check logs in `~/.termux-build/_buildall-aarch64/{package}.err`
- Kill stuck build: Ctrl+C, then resume with `-c`

### Package Fails
- Check error log: `~/.termux-build/_buildall-aarch64/{package}.err`
- Try building manually: `./build-package.sh -a aarch64 {package}`
- Report issue if persistent

## Comparison: On-Device vs GitHub Actions

| Feature | On-Device | GitHub Actions |
|---------|-----------|----------------|
| **Speed** | 2-10 days | 4-8 days (200 parallel batches) |
| **Cost** | Free (your device) | Free (limited hours) |
| **Reliability** | Depends on device | More stable |
| **Convenience** | Manual monitoring | Automatic |
| **Resume** | Easy (just restart) | Must retrigger workflow |

## Next Steps

After build completes:
1. Copy .deb files to NeoTerm-repo
2. Generate Packages.gz and Release files
3. Push to GitHub
4. Users can `apt update && apt install` packages

---

**Happy Building!** 🚀
