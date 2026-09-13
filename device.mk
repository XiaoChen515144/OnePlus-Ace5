LOCAL_PATH := device/oneplus/OP5D2BL1

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery/root/first_stage_ramdisk/fstab.qcom:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.qcom \
    $(LOCAL_PATH)/prebuilt/modules/modules.alias:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/lib/modules/modules.alias \
    $(LOCAL_PATH)/prebuilt/modules/modules.blocklist:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/lib/modules/modules.blocklist \
    $(LOCAL_PATH)/prebuilt/modules/modules.dep:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/lib/modules/modules.dep \
    $(LOCAL_PATH)/prebuilt/modules/modules.load.recovery:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/lib/modules/modules.load \
    $(LOCAL_PATH)/prebuilt/modules/modules.softdep:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/lib/modules/modules.softdep

PRODUCT_COPY_FILES += $(foreach module,$(wildcard $(LOCAL_PATH)/prebuilt/modules/*.ko),\
    $(module):$(TARGET_COPY_OUT_RECOVERY)/root/vendor/lib/modules/$(notdir $(module)))
