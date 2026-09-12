$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)
$(call inherit-product, vendor/orangefox/config/common.mk)
$(call inherit-product, $(LOCAL_PATH)/device.mk)

PRODUCT_DEVICE := OP5D2BL1
PRODUCT_RELEASE_NAME := PKG110
PRODUCT_NAME := omni_OP5D2BL1
PRODUCT_BRAND := OnePlus
PRODUCT_MODEL := OnePlus Ace 5
PRODUCT_MANUFACTURER := OnePlus

PRODUCT_SHIPPING_API_LEVEL := 34
BOARD_SHIPPING_API_LEVEL := 34
PRODUCT_TARGET_VNDK_VERSION := 34

PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH)
