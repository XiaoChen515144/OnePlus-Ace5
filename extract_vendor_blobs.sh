#!/usr/bin/env bash
#
# Populate the recovery ramdisk's blobs and vendor data:
#
#   recovery/root/vendor/**        vendor HALs, libraries and rc/config files
#   recovery/root/odm/**           ODM data that is looked up by absolute path
#                                  (vibrator effect configs, LRA waveform library,
#                                  odm ueventd rules) - shipped in the ramdisk
#                                  because recovery never mounts /odm
#   recovery/root/system/lib64/**  libexpat.so
#
# OrangeFox needs these at runtime for FBE decryption, fastbootd, the vibrator
# HAL, firmware loading, etc.
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
# Notes
# -----
# * This script only touches the files listed in vendor_blobs.list. Files that
#   the tree maintains by hand are deliberately NOT in that list, so they are
#   never overwritten:
#       vendor/etc/init/android.hardware.*.rc   (paths/seclabel/explicit start)
#       vendor/etc/init/qseecomd.rc, ssgtzd.rc
#       vendor/etc/init/vibrator-default.rc
#       vendor/etc/init/variant-script.rc
#       system/**, variant-script.sh
#   Those need a manual diff when switching firmware.
# * Permissions are re-applied from the device (adb pull does not preserve
#   them); HAL daemons must stay executable.
#
set -u

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST="$SELF_DIR/vendor_blobs.list"
MODE=""
SOURCE=""

usage() {
    sed -n '2,/^set -u$/p' "${BASH_SOURCE[0]}" | sed -e 's/^# \{0,1\}//' -e '/^set -u$/d'
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
            # Some libraries the vendor HALs need come from the system image.
            case "$rel" in
                vendor/lib64/*) echo "/system/lib64/${rel#vendor/lib64/}" ;;
                vendor/bin/*)   echo "/system/bin/${rel#vendor/bin/}" ;;
            esac
            ;;
        odm/*)
            # ODM data may live in /odm or, on some firmware, in /vendor.
            echo "/vendor/${rel#odm/}"
            ;;
    esac
}

# Make sure the installed file has a sane mode (cp/adb pull do not preserve it).
apply_mode() {
    local mode="$1" dest="$2" rel="$3"
    case "$mode" in
        [0-7][0-7][0-7]|[0-7][0-7][0-7][0-7]) chmod "$mode" "$dest" ;;
        *)
            case "$rel" in
                */bin/*|*/bin) chmod 0755 "$dest" ;;
                *)             chmod 0644 "$dest" ;;
            esac
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
            apply_mode "$(stat -c %a "$src" 2>/dev/null)" "$dest" "$rel"
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
        # adb reads stdin, which would eat the list this loop is reading from.
        if adb_cmd shell "[ -e '$cand' ]" </dev/null >/dev/null 2>&1; then
            found="$cand"
            break
        fi
    done
    if [ -z "$found" ]; then
        echo "  MISSING (device): $rel"
        missing=$((missing + 1))
        continue
    fi
    if adb_cmd pull "$found" "$dest" </dev/null >/dev/null 2>&1; then
        apply_mode "$(adb_cmd shell "stat -c %a '$found'" </dev/null 2>/dev/null | tr -d '\r\n')" "$dest" "$rel"
        copied=$((copied + 1))
    elif adb_cmd shell "su -c 'cat \"$found\"'" </dev/null >"$dest" 2>/dev/null && [ -s "$dest" ]; then
        apply_mode "$(adb_cmd shell "stat -c %a '$found'" </dev/null 2>/dev/null | tr -d '\r\n')" "$dest" "$rel"
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
