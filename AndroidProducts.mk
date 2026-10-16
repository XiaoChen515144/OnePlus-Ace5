#
# Copyright (C) 2025 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/twrp_OP5D2BL1.mk

# OrangeFox/TWRP (fox_16.0) uses the AOSP 16 lunch format
#   lunch <product>-<release>-<variant>
# where <release> comes from vendor/twrp/vars/aosp_target_release (bp2a).
COMMON_LUNCH_CHOICES := \
    twrp_OP5D2BL1-bp2a-eng \
    twrp_OP5D2BL1-bp2a-userdebug \
    twrp_OP5D2BL1-eng \
    twrp_OP5D2BL1-userdebug
