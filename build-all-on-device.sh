#!/data/data/com.termux/files/usr/bin/bash
# build-all-on-device.sh - Build all packages locally in NeoTerm
# This is a modified version of build-all.sh for on-device execution

set -e -u -o pipefail

TERMUX_SCRIPTDIR=$(cd "$(realpath "$(dirname "$0")")"; pwd)

# On-device build - no Docker needed
echo "🤖 NeoTerm On-Device Build"
echo "Building all packages locally..."

# Settings
: ${TERMUX_TOPDIR:="$HOME/.termux-build"}
: ${TERMUX_ARCH:="aarch64"}
: ${TERMUX_DEBUG_BUILD:=""}
: ${TERMUX_INSTALL_DEPS:="-i"}  # Install dependencies by default

_show_usage() {
	echo "Usage: ./build-all-on-device.sh [-a ARCH] [-d] [-s] [-o DIR] [-c]"
	echo "Build all packages on-device in NeoTerm."
	echo "  -a The architecture to build for: aarch64(default), arm, i686, x86_64."
	echo "  -d Build with debug symbols."
	echo "  -s Skip dependencies (don't install deps)."
	echo "  -o Specify deb directory. Default: output/."
	echo "  -c Continue from last build (resume)."
	exit 1
}

CONTINUE_BUILD=false
while getopts :a:dhsco: option; do
case "$option" in
	a) TERMUX_ARCH="$OPTARG";;
	d) TERMUX_DEBUG_BUILD='-d';;
	s) TERMUX_INSTALL_DEPS='-s';;
	o) TERMUX_OUTPUT_DIR="$(realpath -m "$OPTARG")";;
	c) CONTINUE_BUILD=true;;
	h) _show_usage;;
	*) _show_usage >&2 ;;
esac
done
shift $((OPTIND-1))
if [ "$#" -ne 0 ]; then _show_usage; fi

if [[ ! "$TERMUX_ARCH" =~ ^(aarch64|arm|i686|x86_64)$ ]]; then
	echo "ERROR: Invalid arch '$TERMUX_ARCH'" 1>&2
	exit 1
fi

# Use output/ directory instead of debs/
: ${TERMUX_OUTPUT_DIR:="$TERMUX_SCRIPTDIR/output"}
mkdir -p "$TERMUX_OUTPUT_DIR"

BUILDSCRIPT="$TERMUX_SCRIPTDIR/build-package.sh"
BUILDALL_DIR="$TERMUX_TOPDIR/_buildall-$TERMUX_ARCH"
BUILDORDER_FILE="$BUILDALL_DIR/buildorder.txt"
BUILDSTATUS_FILE="$BUILDALL_DIR/buildstatus.txt"
BUILD_FAILED_FILE="$BUILDALL_DIR/failed-packages.txt"

# Create build directory
mkdir -p "$BUILDALL_DIR"

# Generate build order if not exists
if [ -e "$BUILDORDER_FILE" ]; then
	echo "✅ Using existing buildorder file: $BUILDORDER_FILE"
else
	echo "🔨 Generating build order..."
	"$TERMUX_SCRIPTDIR/scripts/buildorder.py" > "$BUILDORDER_FILE"
	echo "✅ Build order generated: $(wc -l < "$BUILDORDER_FILE") packages"
fi

# Check if continuing
if [ "$CONTINUE_BUILD" = true ] && [ -e "$BUILDSTATUS_FILE" ]; then
	BUILT_COUNT=$(wc -l < "$BUILDSTATUS_FILE")
	echo "📦 Continuing build from: $BUILDSTATUS_FILE ($BUILT_COUNT packages already built)"
else
	# Start fresh
	rm -f "$BUILDSTATUS_FILE" "$BUILD_FAILED_FILE"
	echo "🔨 Starting fresh build of all packages"
fi

# Initialize failed packages file
touch "$BUILD_FAILED_FILE"

# Setup logging
exec >	>(tee -a "$BUILDALL_DIR"/ALL.out)
exec 2> >(tee -a "$BUILDALL_DIR"/ALL.err >&2)

echo ""
echo "📋 Build Configuration:"
echo "   Architecture: $TERMUX_ARCH"
echo "   Output Dir:   $TERMUX_OUTPUT_DIR"
echo "   Install Deps: $TERMUX_INSTALL_DEPS"
echo "   Build Dir:    $BUILDALL_DIR"
echo ""

TOTAL_PACKAGES=$(wc -l < "$BUILDORDER_FILE")
CURRENT_PACKAGE=0
SUCCESS_COUNT=0
SKIP_COUNT=0
FAIL_COUNT=0
BUILD_START_ALL=$(date "+%s")

while read -r PKG PKG_DIR; do
	((CURRENT_PACKAGE++))

	# Check if already built
	if [ -e "$BUILDSTATUS_FILE" ] && grep -q "^$PKG\$" "$BUILDSTATUS_FILE"; then
		((SKIP_COUNT++))
		echo "⏭️  [$CURRENT_PACKAGE/$TOTAL_PACKAGES] Skipping $PKG (already built)"
		continue
	fi

	echo ""
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo "📦 [$CURRENT_PACKAGE/$TOTAL_PACKAGES] Building $PKG..."
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

	BUILD_START=$(date "+%s")

	# Try to build package
	if bash "$BUILDSCRIPT" -a "$TERMUX_ARCH" $TERMUX_DEBUG_BUILD \
		-o "$TERMUX_OUTPUT_DIR" $TERMUX_INSTALL_DEPS "$PKG_DIR" \
		> "$BUILDALL_DIR/${PKG}.out" 2> "$BUILDALL_DIR/${PKG}.err"; then

		BUILD_END=$(date "+%s")
		BUILD_SECONDS=$(( BUILD_END - BUILD_START ))

		((SUCCESS_COUNT++))
		echo "$PKG" >> "$BUILDSTATUS_FILE"
		echo "✅ Success in ${BUILD_SECONDS}s"

		# Show summary
		echo "   📊 Progress: $SUCCESS_COUNT built, $SKIP_COUNT skipped, $FAIL_COUNT failed"
	else
		BUILD_END=$(date "+%s")
		BUILD_SECONDS=$(( BUILD_END - BUILD_START ))

		((FAIL_COUNT++))
		echo "$PKG" >> "$BUILD_FAILED_FILE"
		echo "❌ Failed in ${BUILD_SECONDS}s - See $BUILDALL_DIR/${PKG}.err"
		echo "   📊 Progress: $SUCCESS_COUNT built, $SKIP_COUNT skipped, $FAIL_COUNT failed"

		# Ask if should continue
		echo ""
		read -p "⚠️  Continue building other packages? [Y/n] " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
			echo "🛑 Build stopped by user"
			exit 1
		fi
	fi
done < "$BUILDORDER_FILE"

BUILD_END_ALL=$(date "+%s")
BUILD_SECONDS_ALL=$(( BUILD_END_ALL - BUILD_START_ALL ))
BUILD_HOURS=$(( BUILD_SECONDS_ALL / 3600 ))
BUILD_MINUTES=$(( (BUILD_SECONDS_ALL % 3600) / 60 ))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Build Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Total Time:      ${BUILD_HOURS}h ${BUILD_MINUTES}m"
echo "   Total Packages:  $TOTAL_PACKAGES"
echo "   ✅ Success:      $SUCCESS_COUNT"
echo "   ⏭️  Skipped:      $SKIP_COUNT"
echo "   ❌ Failed:       $FAIL_COUNT"
echo ""
echo "📦 Output: $TERMUX_OUTPUT_DIR"
echo "📋 Logs:   $BUILDALL_DIR"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
	echo "❌ Failed packages:"
	cat "$BUILD_FAILED_FILE"
	echo ""
fi

# Cleanup build status on complete success
if [ "$FAIL_COUNT" -eq 0 ]; then
	rm -f "$BUILDSTATUS_FILE" "$BUILD_FAILED_FILE"
	echo "✅ All packages built successfully!"
else
	echo "⚠️  Some packages failed. Use -c flag to resume."
fi
