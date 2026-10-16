#
# Copyright (C) 2025 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/oneplus/OP5D2BL1

# Building with minimal manifest
ALLOW_MISSING_DEPENDENCIES := true

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := kryo

# Power
ENABLE_CPUSETS := true
ENABLE_SCHEDBOOST := true

# Bootloader
PRODUCT_PLATFORM := pineapple
TARGET_NO_BOOTLOADER := false
TARGET_USES_UEFI := true

# Platform
# OnePlus Ace 5 (PKG110 / OP5D2BL1) is SM8650 "pineapple" - NOT "cliffs" (SM8750).
TARGET_BOARD_PLATFORM := oneplus_sm8650
TARGET_BOARD_PLATFORM_GPU := qcom-adreno750
QCOM_BOARD_PLATFORMS += oneplus_sm8650

# Kernel
BOARD_KERNEL_PAGESIZE         := 4096
TARGET_KERNEL_ARCH            := arm64
TARGET_KERNEL_HEADER_ARCH     := arm64
BOARD_KERNEL_IMAGE_NAME       := Image
BOARD_BOOT_HEADER_VERSION     := 4
TARGET_KERNEL_CLANG_COMPILE   := true
BOARD_MKBOOTIMG_ARGS          += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS          += --pagesize $(BOARD_KERNEL_PAGESIZE)
BOARD_RAMDISK_USE_LZ4 := true
# The stock recovery partition is ramdisk-only (v4 header, kernel_size == 0):
# the bootloader supplies the kernel from the `boot` partition.
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true

# Recovery
TARGET_OTA_ASSERT_DEVICE := PKG110,OP5D2BL1,CPH2645,OP5D3BL1,CPH2647,CPH2691

# Verified Boot
BOARD_AVB_ENABLE := true

# Partitions
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600

# Dynamic partitions (erofs, matches firmware C16.0.7.200)
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
# 14578294784 bytes = 0x364C00000, measured on the device (super_a / super_b)
BOARD_SUPER_PARTITION_SIZE := 14578294784
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := odm product system system_dlkm system_ext vendor vendor_dlkm
# BOARD_SUPER_PARTITION_SIZE - 4 MiB
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 14574100480
TARGET_COPY_OUT_ODM := odm
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm

BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs

# File systems
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_USES_VENDOR_DLKMIMAGE := true
BOARD_USES_SYSTEM_DLKMIMAGE := true

# Workaround for error copying vendor files to recovery ramdisk
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4

# Recovery
BOARD_HAS_LARGE_FILESYSTEM := true
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab

# Extras
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Crypto
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
BOARD_USES_QCOM_FBE_DECRYPTION := true
BOARD_USES_METADATA_PARTITION := true
TW_USE_FSCRYPT_POLICY := 2
PLATFORM_VERSION := 99.87.36
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)
BOOT_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)

# Vibrator
TW_SUPPORT_INPUT_AIDL_HAPTICS := true
TW_SUPPORT_INPUT_AIDL_HAPTICS_FIX_OFF := true

TARGET_RECOVERY_DEVICE_MODULES += libexpat android.hardware.vibrator-V2-ndk
RECOVERY_LIBRARY_SOURCE_FILES += \
    $(TARGET_OUT_SHARED_LIBRARIES)/libexpat.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.vibrator-V2-ndk.so

# Tool
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_LIBRESETPROP := true
TW_INCLUDE_LPDUMP := true
TW_INCLUDE_LPTOOLS := true

# Debug
TARGET_USES_LOGD := true
TWRP_INCLUDE_LOGCAT := true

# Fastbootd
TW_INCLUDE_FASTBOOTD := true

# TWRP build flags
TW_THEME := portrait_hdpi
TW_FRAMERATE := 120
RECOVERY_SDCARD_ON_DATA := true
TARGET_RECOVERY_QCOM_RTC_FIX := true
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_INCLUDE_NTFS_3G := true
TW_NO_EXFAT_FUSE := true
TW_USE_DMCTL := true
TW_USE_TOOLBOX := true
TARGET_USES_MKE2FS := true
TW_INCLUDE_FUSE_EXFAT := true
TW_INCLUDE_FUSE_NTFS := true
TW_INPUT_BLACKLIST := "hbtp_vm"
TW_BRIGHTNESS_PATH := "/sys/class/backlight/panel0-backlight/brightness"
TW_MAX_BRIGHTNESS := 4095
TW_DEFAULT_BRIGHTNESS := 2048
TW_EXTRA_LANGUAGES := true
TW_DEFAULT_LANGUAGE := zh_CN
TW_STATUS_ICONS_ALIGN := center
TW_CUSTOM_CPU_POS := "50"
TW_CUSTOM_CLOCK_POS := "600"
TW_CUSTOM_BATTERY_POS := "800"
TW_EXCLUDE_APEX := true
TW_HAS_EDL_MODE := true
TW_USE_SERIALNO_PROPERTY_FOR_DEVICE_ID := true
TW_NO_SCREEN_BLANK := true
TW_CUSTOM_CPU_TEMP_PATH := "/sys/class/thermal/thermal_zone48/temp"
TW_BATTERY_SYSFS_WAIT_SECONDS := 6
TW_BACKUP_EXCLUSIONS := /data/fonts
TW_DEVICE_VERSION := OnePlus_Ace5-C16.0.7.200

# Recovery kernel-module loading (OrangeFox KernelModuleLoader)
#
# TW_LOAD_VENDOR_MODULES lists the top-level modules recovery needs; their
# dependencies are resolved automatically from modules.dep. The complete
# vendor_boot module set (483 .ko, including the provider modules
# hdcp_qseecom_dlkm.ko required by msm_drm.ko and oplus_bsp_sched_assist.ko
# required by sched-walt.ko / ufs_qcom.ko) ships in the recovery ramdisk at
# /vendor/lib/modules, together with its depmod metadata.
#
# Touch on this unit is a Synaptics S3910 panel controller, driven by
# oplus_bsp_tp_tcm_S3910.ko; oplus_bsp_synaptics_tcm2.ko is the shared TCM2
# transport. (No Goodix module is needed on this panel.)
TW_LOAD_VENDOR_MODULES := "ufs_qcom.ko ufshcd-crypto-qti.ko dwc3-msm.ko msm_drm.ko msm_ext_display.ko oplus_bsp_tp_tcm_S3910.ko oplus_bsp_synaptics_tcm2.ko"
TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true
TW_LOAD_VENDOR_BOOT_MODULES := true
TW_LOAD_PREBUILT_MODULES := true

# OrangeFox
OF_MANUAL_ROOT_VENDOR_ERROR_FIX := 1
