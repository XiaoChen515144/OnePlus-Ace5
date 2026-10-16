# OnePlus Ace 5 (PKG110) OrangeFox device tree

This tree targets the Qualcomm **SM8650 (pineapple)** OnePlus Ace 5, model
`PKG110` / `OP5D2BL1`, device codename `giulia`, firmware `C16.0.7.200`
(`ro.build.display.id = PKG110_16.0.7.200(CN01)`).

Build from an OrangeFox `fox_14.1` (or `fox_16.0`) tree with:

```sh
lunch omni_OP5D2BL1-eng
mka recoveryimage
```

## Platform

The device is **not** a Cliffs (SM8750) device. Verified from a live device:

```text
ro.board.platform = pineapple
ro.soc.model      = SM8650
ro.boot.dtbo_idx  = 7
```

The main DTB in `dtb/ace5.dtb` is a multi-SoC FDT table extracted from stock
`vendor_boot`; the matching entry for this device is the Pineapple/PineappleP v2
entry (`qcom,msm-id = <0x22d 0x20000>, <0x241 0x20000>`,
`qcom,board-id = <8 0>`), which pairs with `dtb/ace5-overlay-7.dtbo`. The ten
overlays in `dtb/ace5-overlay-0..9.dtbo` are byte-identical to the ten overlays
in the device's `dtbo` partition.

## Recovery image layout

The stock `recovery` partition is a **ramdisk-only** boot image
(`header_version = 4`, `kernel_size = 0`); the bootloader supplies the kernel
from the `boot` partition. `BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true`
keeps the built recovery image ramdisk-only to match it.

## Kernel and modules

The prebuilt kernel in `prebuilt/kernel/Image` is the stock
`6.1.141-android14-11-o-gb0878e0704d9` kernel from firmware `C16.0.7.200`.

`prebuilt/modules` contains the full **483** vendor_boot kernel-module set plus
its depmod metadata (`modules.dep`, `modules.alias`, `modules.softdep`,
`modules.blocklist`, `modules.load.recovery`). The set is complete: every
symbol required by the modules is either exported by the kernel or provided by
another module in the set. In particular `msm_drm.ko` requires
`hdcp_qseecom_dlkm.ko`, and `sched-walt.ko` requires
`oplus_bsp_sched_assist.ko`; both providers are included.

The modules are copied into the recovery ramdisk at `/vendor/lib/modules`, and
`TW_LOAD_VENDOR_MODULES` (see `BoardConfig.mk`) lists the hardware modules to
insmod; dependencies are resolved automatically from `modules.dep`.

> Under `CONFIG_MODVERSIONS` the vermagic localversion token does not need to
> match between the kernel and the modules (only the symbol CRCs matter), so a
> kernel and module set built from the same tree but with different git
> descriptions still load together.

## Todo

The stock `vendor.img` / `odm.img` blobs are not copied into this tree. A fully
functional build (decryption, MTP, HALs, firmware) still needs the matching
vendor/odm blobs supplied by the builder.
