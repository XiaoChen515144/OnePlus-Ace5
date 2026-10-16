LOCAL_PATH := device/oneplus/OP5D2BL1

# Recovery fstab (first stage) used to boot into OrangeFox.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery/root/first_stage_ramdisk/fstab.qcom:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.qcom

# Ship the full vendor_boot kernel-module set (483 modules) plus the depmod
# metadata into the recovery ramdisk. The build tree's modprobe then resolves
# dependencies from modules.dep, so the provider modules that msm_drm.ko and
# sched-walt.ko need (hdcp_qseecom_dlkm.ko, oplus_bsp_sched_assist.ko) are
# loaded automatically.
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*.ko,$(LOCAL_PATH)/prebuilt/modules,$(TARGET_COPY_OUT_RECOVERY)/root/vendor/lib/modules)

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/modules/modules.alias:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/lib/modules/modules.alias \
    $(LOCAL_PATH)/prebuilt/modules/modules.blocklist:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/lib/modules/modules.blocklist \
    $(LOCAL_PATH)/prebuilt/modules/modules.dep:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/lib/modules/modules.dep \
    $(LOCAL_PATH)/prebuilt/modules/modules.load.recovery:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/lib/modules/modules.load \
    $(LOCAL_PATH)/prebuilt/modules/modules.softdep:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/lib/modules/modules.softdep
