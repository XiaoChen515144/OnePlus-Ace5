# OnePlus Ace 5 (PKG110) OrangeFox device tree

This tree targets the Qualcomm SM8650 (`cliffs`) OnePlus Ace 5, model `PKG110`,
Android device codename `OP5D2BL1`,
firmware `C16.0.7.200`. The source
`dtb/ace5.dts` is the unmodified main DTB extracted from stock `vendor_boot`;
it is
not a DTBO overlay. The confirmed selector values are:

```text
model       = Qualcomm Technologies, Inc. Cliffs SoC
qcom,msm-id = <0x266 0x10000>
qcom,board-id = <0x00 0x00>
```

Build from an OrangeFox/TWRP Android tree with `lunch omni_OP5D2BL1-eng`.
The DTB is intentionally kept prebuilt because the extracted DTS contains
firmware/vendor-specific nodes and cannot be rebuilt without the matching
Qualcomm include tree and generated headers.

The matching `dtbo.img` contains ten overlays. The device reports
`ro.boot.dtbo_idx=7`, so the active overlay is `ace5-overlay-7.dtbo`.
All ten overlays are stored as
`dtb/ace5-overlay-0.dtbo` through `ace5-overlay-9.dtbo`; the bootloader selects
the appropriate one using the msm, board, project, hardware and region IDs.

The prebuilt kernel and recovery module set are extracted from PKG110 firmware
`C16.0.7.200` and must be kept together. The stock fstab confirms an A/B
`recovery` partition, so the Multiple Recovery Builder target is `recovery`.
The kernel is `6.1.141-android14-11`; 455 recovery modules and their module
metadata are included under `prebuilt/modules`.

The stock `vendor.img` is not copied into this tree. It contains proprietary
HALs and firmware, and its EROFS extraction is incomplete in the supplied
image. A working build still needs the matching vendor/odm blobs supplied by
the builder as a private or release artifact.
