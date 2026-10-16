#!/usr/bin/env bash
#
# Populate the recovery ramdisk's vendor blobs (recovery/root/vendor/** and
# recovery/root/system/lib64/libexpat.so) that OrangeFox needs at runtime for
# FBE decryption, fastbootd, the vibrator HAL, firmware loading, etc.
#
# Two sources are supported:
#
#   1) A reference device tree / another recovery/root directory:
#        ./extract_vendor_blobs.sh --from /path/to/recovery/root
#
#   2) The running device itself (needs adb + root):
#        ./extract_vendor_blobs.sh --device 127.0.0.1:5555
#      (a serial is optional if exactly one device is connected: --device "")
#
# The list of required files is in vendor_blobs.list (one path per line,
# relative to recovery/root/).
#
set -u

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST="$SELF_DIR/vendor_blobs.list"
MODE=""
SOURCE=""

usage() {
    sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        --from)   MODE=dir;    SOURCE="${2:-}"; shift 2 ;;
        --device) MODE=device; SOURCE="${2:-}"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "unknown argument: $1"; usage ;;
    esac
done

[ -n "$MODE" ] || usage
[ -f "$LIST" ] || { echo "missing $LIST"; exit 1; }

# Resolve the adb command for a given serial (empty = auto-select).
adb_cmd() {
    if [ -n "$SOURCE" ]; then adb -s "$SOURCE" "$@"; else adb "$@"; fi
}

# Map a recovery/root-relative blob path to candidate device paths.
device_candidates() {
    local rel="$1"
    echo "/$rel"
    case "$rel" in
        vendor/*)
            local tail="${rel#vendor/}"
            echo "/odm/$tail"
            echo "/vendor_dlkm/$tail"
            ;;
    esac
}

copied=0
skipped=0
missing=0

while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    dest="$SELF_DIR/recovery/root/$rel"
    mkdir -p "$(dirname "$dest")"

    if [ "$MODE" = dir ]; then
        src="$SOURCE/$rel"
        if [ -f "$src" ]; then
            cp -f "$src" "$dest"
            copied=$((copied + 1))
        else
            echo "  MISSING (source): $rel"
            missing=$((missing + 1))
        fi
        continue
    fi

    # device mode
    found=""
    for cand in $(device_candidates "$rel"); do
        if adb_cmd shell "[ -e '$cand' ]" >/dev/null 2>&1; then
            found="$cand"
            break
        fi
    done
    if [ -z "$found" ]; then
        echo "  MISSING (device): $rel"
        missing=$((missing + 1))
        continue
    fi
    if adb_cmd pull "$found" "$dest" >/dev/null 2>&1; then
        copied=$((copied + 1))
    elif adb_cmd shell "su -c 'cat \"$found\"'" >"$dest" 2>/dev/null && [ -s "$dest" ]; then
        copied=$((copied + 1))
    else
        echo "  FAILED to read: $found"
        skipped=$((skipped + 1))
        rm -f "$dest"
    fi
done < "$LIST"

echo
echo "done: copied=$copied missing=$missing failed=$skipped"
echo "If files are missing, they are not present on this firmware; the"
echo "corresponding recovery feature (decryption/MTP/fastbootd/vibrator) may"
echo "be unavailable until a matching blob source is found."
