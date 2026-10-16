# OrangeFox Recovery device tree — OnePlus Ace 5 (PKG110 / OP5D2BL1 / "giulia")

Device tree for building **OrangeFox Recovery** (`fox_16.0`, Android 16 base) for
the OnePlus Ace 5.

Everything below is based on **measurements taken from the device itself**, not
on assumptions.

## Device facts (verified with `adb`)

| Item | Value |
|---|---|
| Marketing name | OnePlus Ace 5 |
| Model | PKG110 (`OP5D2BL1`) |
| Project code (`ro.boot.prjname`) | `23851` |
| SoC | Qualcomm **SM8650** ("pineapple"), Adreno 750 |
| Firmware tested | **C16.0.7.200** (`PKG110_16.0.7.200(CN01)`, Android 16 / SDK 36) |
| Slot | A/B (`slot_suffix=_a`), virtual A/B (COW v3 + zstd) |
| `dtbo_idx` used | 7 |
| Panel | `AA577_P_3_A0020_dsc_cmd` (BOE), backlight `panel0-backlight`, max 4094 |
| Touch | Synaptics **S3910** → `oplus_bsp_tp_tcm_S3910.ko` |
| `recovery` partition | 104857600 bytes, **ramdisk-only** (boot header v4, `kernel_size=0`) |
| `boot` partition | 201326592 bytes, kernel only |
| `super` | 14578294784 bytes |
| `/data` | f2fs + `inlinecrypt` + `fileencryption=aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized+wrappedkey_v0`, metadata-encrypted (`aes-256-xts:wrappedkey_v0`) |
| `/system`, `/vendor`, `/odm`, … | erofs |

The `recovery` partition contains no kernel: the bootloader supplies the kernel
from `boot`. The tree therefore builds a **ramdisk-only recovery image**
(`BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true`).

## Build

The make tree is OrangeFox `fox_16.0`, so the product is called
`twrp_OP5D2BL1` and lunches against the `bp2a` release
(`vendor/twrp/vars/aosp_target_release`):

```bash
export FOX_BUILD_DEVICE=OP5D2BL1
. build/envsetup.sh
lunch twrp_OP5D2BL1-bp2a-eng
mka recoveryimage
```

The image is written to `out/target/product/OP5D2BL1/recovery.img`.

`ALLOW_MISSING_DEPENDENCIES` is already set by `BoardConfig.mk`; `LC_ALL="C"` is
recommended to avoid locale issues during the build.

## Automated builds

Two fully automated paths exist; both do the same work (sync `fox_16.0`, install
this tree as `device/oneplus/OP5D2BL1`, lunch, `mka adbd recoveryimage`) and no
step needs a local device or a local Android SDK.

### GitHub Actions (recommended — no local machine needed)

Builds run from the
[`Multiple-Recovery-Builder-2026`](https://github.com/XiaoChen515144/Multiple-Recovery-Builder-2026)
builder repository: workflow **OrangeFox fox_16.0 - OnePlus Ace 5 (OP5D2BL1)**
(`.github/workflows/fox_16.0-Ace5-OP5D2BL1.yml` on its `OrangeFox` branch). It is
preconfigured for this device (manifest branch `16.0`, this tree at `main`,
`twrp_OP5D2BL1-bp2a-eng`, `mka adbd recoveryimage`), so starting it from the
Actions page is enough; it also runs when its own workflow file is edited.

Each run verifies the produced image (boot header, the 483 kernel modules, the
vibrator HAL and its `/odm` data, parity with this tree), runs `ldcheck` over the
security and vibrator binaries, uploads `recovery.img` + `.sha256` + `.md5` as an
artifact, publishes a release tagged `fox16-<device tree commit>`, and
force-pushes a build report to that repository's `ci-logs` branch, which can be
read with a plain `git fetch` (job logs need a token, the report does not).

A cold run takes roughly 1–2 hours on a standard runner: every run syncs the
~390-project OrangeFox manifest with `--depth=1` and then builds from scratch.

This repository deliberately ships no workflow of its own, so pushing here never
starts a build.

### Locally on a build machine

[`build.sh`](build.sh) is a one-shot, idempotent script: it installs the host
dependencies (via
[OrangeFox's `android_build_env.sh`](https://gitlab.com/OrangeFox/misc/scripts)),
syncs the manifest, installs this tree, builds, and prints the image path and
its `sha256`.

```bash
./build.sh                 # everything: deps (if needed), sync, build
./build.sh --no-sync       # rebuild without re-syncing
./build.sh --sync-only     # prepare the source tree only
./build.sh -j 8            # cap parallel jobs (repo sync + make)
./build.sh --flash         # build, then fastboot flash recovery_a/_b
./build.sh --help
```

Requires ~70 GB free disk space and a few hours on a small box; a 4-core/6 GB
machine is not enough — use the GitHub Actions workflow there. The source tree
defaults to `~/fox_16.0` and the output to `~/fox-out` (`--dir` / `--out` /
`SRC` / `OUT_DIR` override them).

## Flash

Bootloader must be unlocked (`fastboot flashing unlock`; on this unit
`verifiedbootstate=orange` / `vbmeta.device_state=unlocked`).

```
fastboot flash recovery_a out/target/product/OP5D2BL1/recovery.img
fastboot flash recovery_b out/target/product/OP5D2BL1/recovery.img
```

Both slots must be flashed: the active slot can change on the next OTA.

## Kernel / module loading

The `recovery` image ships **no kernel** — the kernel comes from `boot`. The
tree works with both the stock kernel (`6.1.141-android14-11-o-gb0878e0704d9`)
and custom 6.1.141 builds (e.g. `6.1.141-xiaochen`), because the kernel is built
with `CONFIG_MODVERSIONS`: only symbol CRCs are compared, so the stock modules
load against any kernel built from the same source/config.

What actually matters is that the module set matches its `modules.dep`. The
failure mode that produced a black screen is a module directory that is missing
**provider** modules: `msm_drm.ko` has a non-weak (GLOBAL) dependency on
`hdcp_qseecom_dlkm.ko`, and `ufs_qcom.ko` / `sched-walt.ko` need
`oplus_bsp_sched_assist.ko`. If the providers are absent, dependency resolution
fails and display/storage never come up.

This tree therefore ships the **complete 483-module set** (extracted from the
stock `vendor_boot` ramdisk) inside the recovery ramdisk at
`recovery/root/vendor/lib/modules/`, together with its
`modules.dep` / `modules.alias` / `modules.softdep` / `modules.blocklist`
metadata (0 unresolved symbols).

Loading is done by the OrangeFox `KernelModuleLoader`:

* `TW_LOAD_PREBUILT_MODULES_AT_FIRST := true` makes the loader use the
  in-ramdisk copy (`/vendor/lib/modules`) **before** the vendor/vendor_dlkm
  partitions are consulted.
* `TW_LOAD_VENDOR_MODULES` lists the top-level modules recovery needs
  (`msm_drm`, `ufs_qcom`, the Synaptics S3910 touch modules, …); their
  dependencies are resolved automatically from `modules.dep`.
* `TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true` skips the `-gki` module
  directory, so the vendor modules are used on any kernel.

Security-patch levels do **not** need the old `prepdecrypt` helper: the
`fox_16.0` module loader itself reads `/vendor/build.prop` and
`/system_root/build.prop` and overrides `ro.vendor.build.security_patch` /
`ro.build.version.security_patch`. No `prepdecrypt` script/service is shipped.

## Vendor blobs

The proprietary blobs needed by recovery are **already included** in
`recovery/root/vendor/`, extracted from the device's own firmware
(C16.0.7.200) and completed to the full ELF dependency closure. All of them were
verified byte-for-byte (md5) against the device.

* FBE decryption — `keymint` / `gatekeeper` / `weaver` / `qseecomd` / `ssgtzd`
  and their libraries
* `fastbootd` — `android.hardware.boot-service.qti`
* Vibrator — `vendor.oplus.hardware.vibrator-service` +
  `vendor.oplus.hardware.oplusvibrator-V2-ndk.so`
* Health/HAL firmware loading, modem firmware (`vendor/firmware_mnt`)

On the device several of these live on `/odm` (`weaver`, `secure_element`, the
vibrator HAL). Recovery does not mount `/odm`, so they are shipped in the
ramdisk under `/vendor/bin/hw/` and their `.rc` files are adjusted accordingly.
Every recovery HAL service gets `seclabel u:r:recovery:s0` (recovery has no
vendor SELinux policy).

Data files that the vendor libraries open by **absolute path** cannot simply be
relocated, so they keep their stock path and are shipped under
`recovery/root/odm/` (the `/odm` directory exists in the ramdisk only; mounting
the real `odm` partition from the TWRP mount menu simply shadows it):

* `odm/etc/vibrator/` — `vibrator_effect.json` plus `809/{def,soft}/*.bin`.
  `liboplusvibratoreffect.so` loads this JSON and then loads the effect files
  using the absolute paths stored inside it (`/odm/etc/vibrator/809/...`).
* `odm/etc/wave_lib/` + `odm/etc/lra_model_0.conf` — used by `libsivibrator.so`.
* `odm/etc/ueventd.rc` / `odm/etc/ueventd.reserve.rc` — imported by the AOSP
  `system/etc/ueventd.rc`; shipping them keeps the imports resolvable.

The `ro.oplus.haptic.lra_*` calibration properties the vibrator HAL reads are in
`vendor.prop`, with the values measured on the device.

Core AOSP libraries that the recovery ramdisk already provides (`libc`, `libm`,
`libc++`, `libbase`, `libbinder*`, `libcutils`, `liblog`, `libutils`,
`libhardware`, `libhidlbase`, `libz`, `libcrypto`, `libssl`, `libpng`, …) are
intentionally **not** shipped, so the recovery's own copies are used.

To regenerate the blobs for a different firmware:

```bash
# from the running (rooted) device — recommended, firmware-matched
./extract_vendor_blobs.sh --device 127.0.0.1:5555

# or from another recovery/root directory you already have
./extract_vendor_blobs.sh --from /path/to/some/recovery/root
```

`vendor_blobs.list` is the exact file list; the files live at `/vendor`, `/odm`
or `/vendor_dlkm` on the device (a few libraries that the vendor HALs need come
from `/system/lib64`, which the script also checks).

The list intentionally contains **only** device-provided data. Files this tree
maintains by hand — the recovery `.rc` files under `vendor/etc/init/`, the VINTF
manifests, `twrp.flags`, `variant-script.sh`, … — are not listed, so re-running
the script never overwrites them (that is why the HAL `.rc` files here differ
from the stock ones). The script also re-applies each file's permissions from the
device, because `adb pull` does not preserve the executable bit.

## Layout

```
BoardConfig.mk                 platform, partitions, crypto, TWRP/OF flags
device-OP5D2BL1.mk             product config (base/VAB/API/UFFD)
twrp_OP5D2BL1.mk               product definition (lunch target)
AndroidProducts.mk             lunch choices
vendorsetup.sh                 OrangeFox environment (FOX_* build vars)
build.sh                       one-shot automated local build (sync + build)
twrp.dependencies              extra repo dependencies (none needed)
Android.mk / Android.bp        build glue
recovery.fstab                 Android fstab (dynamic + physical partitions)
vendor.prop                    recovery properties (wired up as TARGET_VENDOR_PROP)
security/otacert.x509.pem      OTA certificate
prebuilt/kernel/Image          stock kernel (reference only; not used by the build)
dtb/                           stock DTB/DTBO overlays (reference only; not used)
recovery/root/
    init.recovery.qcom.rc      QCOM recovery init (HAL/service startup)
    init.recovery.usb.rc       USB gadget config (adb/mtp/fastboot)
    system/etc/twrp.flags      TWRP partition flags
    system/etc/ueventd.rc      ueventd rules
    system/etc/vintf/manifest.xml
    system/bin/variant-script.sh   per-project model/variant props
    vendor/etc/init/*.rc       HAL service definitions (recovery seclabel)
    vendor/etc/vintf/          VINTF manifest + HAL fragments
    vendor/lib/modules/        complete 483-module set + depmod metadata
    vendor/bin/hw/             recovery HAL daemons (keymint/weaver/…)
    odm/etc/vibrator/          vibrator effect config (absolute paths!)
    odm/etc/wave_lib/          LRA waveform library
    odm/etc/lra_model_0.conf   LRA model calibration
    odm/etc/ueventd*.rc        ODM ueventd rules (imported by the AOSP ueventd.rc)
```

## Notes / status

* `prebuilt/kernel/Image` and `dtb/` are kept for reference only. The recovery
  build uses the kernel from the `boot` partition, so they are not packaged.
* MTP is enabled. If MTP causes trouble on your unit, add
  `TW_EXCLUDE_MTP := true` to `BoardConfig.mk`.
* Touch modules are the Synaptics S3910 family; if a different panel supplier
  (e.g. Goodix) shows up, adjust `TW_LOAD_VENDOR_MODULES` accordingly.
* Vibration works through the kernel haptic device (`/dev/awinic_haptic`, the
  Awinic AW8697 I2C chip) with the vendor's full effect configuration bundled in
  the ramdisk at `recovery/root/odm/etc/` (see above), so
  `liboplusvibratoreffect.so` and `libsivibrator.so` find their effect files and
  waveforms. `aw8697.ko` (plus the OPLUS haptic module set) is in
  `TW_LOAD_VENDOR_MODULES` so the device node exists in recovery; the unit has no
  `/sys/class/leds/vibrator`, so TWRP's sysfs haptic fallback does not apply and
  the AIDL vibrator HAL (`android.hardware.vibrator.IVibrator/default`, which the
  OPLUS service registers) is the only path.
* AAC "richtap" is not supported by this firmware: there is no
  `/odm/etc/aac_richtap.config` on the device, so the HAL logs
  `aac richtap not support` — exactly like the stock ROM.
