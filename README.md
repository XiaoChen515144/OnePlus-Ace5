# OrangeFox Recovery device tree — OnePlus Ace 5 (PKG110 / OP5D2BL1 / "giulia")

Device tree for building **OrangeFox Recovery** for the OnePlus Ace 5.

Everything below is based on **measurements taken from the device itself**, not
on assumptions.

## Device facts (verified with `adb`)

| Item | Value |
|---|---|
| Marketing name | OnePlus Ace 5 |
| Model | PKG110 (`OP5D2BL1`) |
| Project code (`ro.boot.prjname`) | `23851` |
| SoC | Qualcomm **SM8650** ("pineapple"), Adreno 750 |
| Firmware tested | **C16.0.7.200** (`PKG110_16.0.7.200(CN01)`, Android 16) |
| Slot | A/B (`slot_suffix=_a`) |
| `dtbo_idx` used | 7 |
| Panel | `AA577_P_3_A0020_dsc_cmd` (BOE), backlight `panel0-backlight`, max 4095 |
| Touch | Synaptics **S3910** → `oplus_bsp_tp_tcm_S3910.ko` |
| `recovery` partition | 104857600 bytes, **ramdisk-only** (boot header v4, `kernel_size=0`) |
| `boot` partition | 201326592 bytes, kernel only |
| `super` | 14578294784 bytes |

The `recovery` partition contains no kernel: the bootloader supplies the kernel
from `boot`. The tree therefore builds a **ramdisk-only recovery image**
(`BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true`).

## Kernel / module loading

The stock kernel is `6.1.141-android14-11-o-gb0878e0704d9`, built with
`CONFIG_MODVERSIONS`. Under MODVERSIONS the kernel `localversion` is **not**
part of the module comparison — only symbol CRCs are. The device runs the stock
kernel symbols, so the stock modules load fine and **no kernel replacement is
needed**.

The failure mode that produced a black screen is a **module set that does not
match `modules.dep`**: `msm_drm.ko` has a non-weak (GLOBAL) dependency on
`hdcp_qseecom_dlkm.ko` and `ufs_qcom.ko` / `sched-walt.ko` need
`oplus_bsp_sched_assist.ko`. If those provider `.ko` files are absent from the
module directory that OrangeFox loads from, dependency resolution fails and
display/storage never come up.

This tree ships the **complete 483-module set extracted from the stock
`vendor_boot` ramdisk** in the recovery ramdisk at
`recovery/root/vendor/lib/modules/`, together with its
`modules.dep` / `modules.alias` / `modules.softdep` / `modules.blocklist`
metadata. `TW_LOAD_VENDOR_MODULES` lists the top-level modules recovery needs;
their dependencies are resolved from `modules.dep`.

Module load order is handled by the OrangeFox `KernelModuleLoader`; both the
`vendor_boot` ramdisk (`/lib/modules`) and the recovery ramdisk
(`/vendor/lib/modules`) are complete, so dependency resolution succeeds on
either path.

## Vendor blobs (required for a fully working recovery)

This device tree does **not** ship OnePlus proprietary binaries. Without them
the recovery still boots and shows the UI (display/storage/touch all work via
kernel modules), but these features need the matching blobs in
`recovery/root/vendor/`:

* FBE decryption — `keymint` / `gatekeeper` / `weaver` / `qseecomd`
* `fastbootd` — `android.hardware.boot-service.qti`
* Vibrator — `vendor.oplus.hardware.vibrator-service`
* ADB/MTP, firmware loading, etc.

Provide them in one of two ways:

```bash
# from the running (rooted) device — recommended, firmware-matched
./extract_vendor_blobs.sh --device 127.0.0.1:5555

# or from another recovery/root directory you already have
./extract_vendor_blobs.sh --from /path/to/some/recovery/root
```

`vendor_blobs.list` (208 files) contains the exact list that is required; the
files are located at `/vendor`, `/odm` or `/vendor_dlkm` on the device.

## Build

```
. build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
export LC_ALL="C"
lunch omni_OP5D2BL1-eng
mka recoveryimage
```

The image is written to `out/target/product/OP5D2BL1/recovery.img`.

## Flash

Bootloader must be unlocked.

```
fastboot flash recovery_a recovery.img
fastboot flash recovery_b recovery.img
```

Both slots must be flashed: the active slot can change on the next OTA.

## Layout

```
BoardConfig.mk                 platform, partitions, crypto, TWRP/OF flags
device.mk                      product config (base/VAB/API/UFFD)
omni_OP5D2BL1.mk               product definition (lunch target)
AndroidProducts.mk             lunch choices
Android.mk / Android.bp        build glue
recovery.fstab                 Android fstab (dynamic + physical partitions)
system.prop / vendor.prop      recovery properties
vendorsetup.sh                 OrangeFox environment
security/otacert.x509.pem      OTA certificate
prebuilt/kernel/Image          stock kernel (reference only; not used)
dtb/                           stock main DTB + 10 dtbo overlays (reference only)
recovery/root/
    init.recovery.qcom.rc      QCOM recovery init
    init.recovery.usb.rc       USB gadget config (adb/mtp/fastboot)
    system/etc/twrp.flags      TWRP partition flags
    system/etc/ueventd.rc      ueventd rules
    system/etc/vintf/manifest.xml
    system/bin/variant-script.sh   per-project model/variant props
    vendor/lib/modules/        complete 483-module set + depmod metadata
    vendor/**                  -> add with extract_vendor_blobs.sh
```

## Notes / status

* `prebuilt/kernel/Image` and `dtb/` are kept for reference only. The recovery
  build uses the kernel from the `boot` partition.
* MTP is enabled. If MTP causes trouble on your unit, add
  `TW_EXCLUDE_MTP := true` to `BoardConfig.mk`.
* Touch modules are the Synaptics S3910 family; if a different panel supplier
  (e.g. Goodix) shows up, adjust `TW_LOAD_VENDOR_MODULES` accordingly.
