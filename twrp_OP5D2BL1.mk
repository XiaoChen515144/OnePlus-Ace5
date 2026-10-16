#
# Copyright (C) 2025 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/oneplus/OP5D2BL1

# Inherit from the device configuration (hardware/product parts)
$(call inherit-product, $(DEVICE_PATH)/device-OP5D2BL1.mk)

# TWRP/OrangeFox common configuration
$(call inherit-product, vendor/twrp/config/common.mk)

#
# The "twrp_" prefix is mandatory: OrangeFox derives the recovery device name
# with $(subst twrp_,,$(TARGET_PRODUCT)) (see bootable/recovery/orangefox.mk),
# and the manifest/build system expect the product to be called twrp_<device>.
#
PRODUCT_DEVICE       := OP5D2BL1
PRODUCT_NAME         := twrp_OP5D2BL1
PRODUCT_BRAND        := OnePlus
PRODUCT_MODEL        := PKG110
PRODUCT_MANUFACTURER := OnePlus
PRODUCT_RELEASE_NAME := OP5D2BL1

# Theme
TW_STATUS_ICONS_ALIGN := center
TW_Y_OFFSET           := 111
TW_H_OFFSET           := -111
