#!/usr/bin/env bash
#
# Fully automatic OrangeFox (fox_16.0) build for the OnePlus Ace 5
# (PKG110 / OP5D2BL1 / giulia).
#
# Run it from a checkout of this device tree; it will
#   1. install the build dependencies (OrangeFox's host setup script, once),
#   2. sync/freshen the OrangeFox fox_16.0 source tree,
#   3. copy this device tree into device/oneplus/OP5D2BL1,
#   4. lunch twrp_OP5D2BL1-bp2a-eng and build adbd + recoveryimage,
#   5. print the path/checksum of the resulting recovery.img (and flash it with --flash).
#
# It is idempotent: re-running it re-syncs an existing tree and rebuilds
# incrementally instead of starting over.
#
# Requirements: Ubuntu/Debian (or any distro where OrangeFox's setup script
# works), ~70 GB of free disk space, sudo, and a few hours on a small machine.
# A 4-core/6 GB box is *not* enough; use the GitHub Actions workflow instead
# (.github/workflows/fox_16.0-build.yml).
#
# Usage:
#   ./build.sh                        # do everything
#   ./build.sh --no-sync              # rebuild without re-syncing
#   ./build.sh --sync-only            # only prepare the source tree
#   ./build.sh -j 8                   # limit parallel jobs (repo sync + make)
#   ./build.sh --flash                # build, then flash recovery_a/_b
#   ./build.sh --setup                # force running the dependency setup script
#
set -euo pipefail

# ---------------------------------------------------------------- defaults ---
DEVICE="OP5D2BL1"
PRODUCT="twrp_OP5D2BL1"
LUNCH="${LUNCH:-twrp_OP5D2BL1-bp2a-eng}"
FOX_BRANCH="${FOX_BRANCH:-fox_16.0}"
FOX_BUILD_TYPE="${FOX_BUILD_TYPE:-Alpha}"
BUILD_TARGET="${BUILD_TARGET:-adbd recoveryimage}"
MANIFEST_URL="${MANIFEST_URL:-https://gitlab.com/OrangeFox/Manifest.git}"

SRC="${SRC:-$HOME/$FOX_BRANCH}"
OUT_DIR="${OUT_DIR:-$HOME/fox-out}"
JOBS="$(nproc --all 2>/dev/null || echo 4)"
MAKE_JOBS=()          # empty = let Soong pick the job count (recommended)
MIN_FREE_GB=60

DO_SYNC=1
SYNC_ONLY=0
DO_FLASH=0
DO_SETUP=0

DEVICE_TREE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$DEVICE_TREE/build.log"

# ------------------------------------------------------------------- usage ---
usage() {
    awk 'NR < 3 {next} /^set -euo/ {exit} {sub(/^# ?/, ""); print}' "${BASH_SOURCE[0]}"
    exit "${1:-0}"
}

# ------------------------------------------------------------------ options ---
while [ $# -gt 0 ]; do
    case "$1" in
        -d|--dir)      SRC="$2"; shift 2 ;;
        -o|--out)      OUT_DIR="$2"; shift 2 ;;
        -j|--jobs)     JOBS="$2"; MAKE_JOBS=(-j "$2"); shift 2 ;;
        -t|--target)   BUILD_TARGET="$2"; shift 2 ;;
        -b|--branch)   FOX_BRANCH="$2"; shift 2 ;;
        --no-sync)     DO_SYNC=0; shift ;;
        --sync-only)   SYNC_ONLY=1; shift ;;
        --setup)       DO_SETUP=1; shift ;;
        --flash)       DO_FLASH=1; shift ;;
        -h|--help)     usage 0 ;;
        *)             echo "unknown option: $1" >&2; usage 1 ;;
    esac
done

log()  { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!!! %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31m### %s\033[0m\n' "$*" >&2; exit 1; }

# --------------------------------------------------------------- preflight ---
log "preflight"
[ -f "$DEVICE_TREE/AndroidProducts.mk" ] \
    || die "$DEVICE_TREE does not look like the $DEVICE device tree."

for tool in git python3 curl tar; do
    command -v "$tool" >/dev/null || die "missing required tool: $tool"
done

mkdir -p "$SRC" "$OUT_DIR"
FREE_GB="$(df -Pk "$SRC" | awk 'NR==2 {printf "%d", $4/1024/1024}')"
[ "$FREE_GB" -ge "$MIN_FREE_GB" ] \
    || die "only ${FREE_GB} GB free on $(df -P --output=target "$SRC" | tail -1); need ~${MIN_FREE_GB} GB.
    Free some space, point --dir at another filesystem, or use the GitHub Actions workflow."
echo "source tree : $SRC"
echo "output dir  : $OUT_DIR"
echo "free space  : ${FREE_GB} GB"
echo "sync jobs   : $JOBS"

# ------------------------------------------------------------ dependencies ---
if [ "$DO_SETUP" = 1 ] || ! command -v repo >/dev/null; then
    log "installing build dependencies (OrangeFox android_build_env.sh)"
    curl -fsSL \
        https://gitlab.com/OrangeFox/misc/scripts/-/raw/master/setup/android_build_env.sh \
        -o /tmp/android_build_env.sh
    sudo bash /tmp/android_build_env.sh
    # The setup script drops `repo` in /usr/local/bin without the exec bit.
    [ -x /usr/local/bin/repo ] || sudo chmod a+x /usr/local/bin/repo
    hash -r
fi
command -v repo >/dev/null || die "repo is not available after setup; install it and re-run"

git config --global --add safe.directory '*'
git config --global user.name  "${GIT_AUTHOR_NAME:-fox builder}"
git config --global user.email "${GIT_AUTHOR_EMAIL:-builder@localhost}"

# -------------------------------------------------------------- repo sync ----
if [ "$DO_SYNC" = 1 ]; then
    log "syncing OrangeFox $FOX_BRANCH into $SRC"
    cd "$SRC"
    if [ ! -d .repo ]; then
        repo init --depth=1 -u "$MANIFEST_URL" -b "$FOX_BRANCH"
    fi
    repo sync -c -j"$JOBS" --no-clone-bundle --no-tags
    du -sh "$SRC"
fi

[ "$SYNC_ONLY" = 1 ] && { log "sync only - done"; exit 0; }

# ---------------------------------------------------------- device tree ------
log "installing device tree into device/oneplus/$DEVICE"
DEST="$SRC/device/oneplus/$DEVICE"
rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
tar -C "$DEVICE_TREE" \
    --exclude=./.git --exclude=./artifacts --exclude=./build.log --exclude=./build-logs \
    -cf - . | tar -C "$DEST" -xf -
echo "installed $(du -sh "$DEST" | cut -f1)"

# ------------------------------------------------------------------ build ----
log "building: lunch $LUNCH && mka $BUILD_TARGET"
(
    cd "$SRC"
    export LC_ALL=C
    export ALLOW_MISSING_DEPENDENCIES=true
    export FOX_BUILD_DEVICE="$DEVICE"
    export FOX_BUILD_TYPE="$FOX_BUILD_TYPE"
    export OUT_DIR="$OUT_DIR"
    mkdir -p "$OUT_DIR"

    # shellcheck disable=SC1091
    source build/envsetup.sh
    lunch "$LUNCH"
    mka ${MAKE_JOBS[@]+"${MAKE_JOBS[@]}"} $BUILD_TARGET 2>&1 | tee "$LOG"
)

# -------------------------------------------------------------- reporting ----
PRODUCT_OUT="$OUT_DIR/target/product/$DEVICE"
IMG="$PRODUCT_OUT/recovery.img"
[ -s "$IMG" ] || die "build finished but no recovery.img at $IMG"

sha256sum "$IMG" | tee "$IMG.sha256"

SIZE="$(stat -c %s "$IMG")"
log "done"
cat <<EOF
image   : $IMG
size    : $(numfmt --to=iec "$SIZE") ($SIZE bytes)
sha256  : $(cut -d' ' -f1 "$IMG.sha256")
log     : $LOG

flash it (bootloader unlocked) with:
    fastboot flash recovery_a $IMG
    fastboot flash recovery_b $IMG
EOF

# ------------------------------------------------------------------ flash ----
if [ "$DO_FLASH" = 1 ]; then
    log "flashing $IMG"
    command -v fastboot >/dev/null || die "fastboot not found"
    read -r -p "flash recovery_a and recovery_b now? [y/N] " ans
    [ "$ans" = "y" ] || [ "$ans" = "Y" ] || die "aborted"
    fastboot flash recovery_a "$IMG"
    fastboot flash recovery_b "$IMG"
    fastboot reboot recovery
fi
