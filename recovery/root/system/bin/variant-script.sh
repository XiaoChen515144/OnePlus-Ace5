#!/system/bin/sh
# This script is needed to automatically set device props.
variant=$(getprop ro.boot.prjname)
echo $variant
        case $variant in
            "23851")
            # oneplus ACE 5 (giulia)
                echo "Oneplus ACE 5" > /config/usb_gadget/g1/strings/0x409/product
                resetprop ro.product.device "OP5D2BL1"
                resetprop ro.product.system.device "PKG110"
                resetprop ro.product.vendor.device "OP5D2BL1"
                resetprop ro.product.odm.device "OP5D2BL1"
                resetprop ro.product.product.device "OP5D2BL1"
                resetprop ro.product.system_ext.device "OP5D2BL1"
                resetprop ro.product.product.model "PKG110"
                resetprop ro.product.model "PKG110"
                resetprop ro.product.system.model "PKG110"
                resetprop ro.product.system_ext.model "PKG110"
                resetprop ro.product.vendor.model "PKG110"
                resetprop ro.product.odm.model "PKG110"
                resetprop ro.boot.hardware.revision "CN"
                ;;
            "23868")
            # oneplus 13 R (giulia)
                echo "Oneplus 13 R" > /config/usb_gadget/g1/strings/0x409/product
                resetprop ro.product.device "OP5D3BL1"
                resetprop ro.product.system.device "CPH2645"
                resetprop ro.product.vendor.device "OP5D3BL1"
                resetprop ro.product.odm.device "OP5D3BL1"
                resetprop ro.product.product.device "OP5D3BL1"
                resetprop ro.product.system_ext.device "OP5D3BL1"
                resetprop ro.product.product.model "CPH2645"
                resetprop ro.product.model "CPH2645"
                resetprop ro.product.system.model "CPH2645"
                resetprop ro.product.system_ext.model "CPH2645"
                resetprop ro.product.vendor.model "CPH2645"
                resetprop ro.product.odm.model "CPH2645"
                resetprop ro.boot.hardware.revision "GL"
                ;;
            "23869")
            # oneplus 13 R (giulia)
                echo "Oneplus 13 R" > /config/usb_gadget/g1/strings/0x409/product
                resetprop ro.product.device "OP5D3BL1"
                resetprop ro.product.system.device "CPH2647"
                resetprop ro.product.vendor.device "OP5D3BL1"
                resetprop ro.product.odm.device "OP5D3BL1"
                resetprop ro.product.product.device "OP5D3BL1"
                resetprop ro.product.system_ext.device "OP5D3BL1"
                resetprop ro.product.product.model "CPH2647"
                resetprop ro.product.model "CPH2647"
                resetprop ro.product.system.model "CPH2647"
                resetprop ro.product.system_ext.model "CPH2647"
                resetprop ro.product.vendor.model "CPH2647"
                resetprop ro.product.odm.model "CPH2647"
                resetprop ro.boot.hardware.revision "NA"
                ;;
            "23867")
            # oneplus 13 R (giulia)
                echo "Oneplus 13 R" > /config/usb_gadget/g1/strings/0x409/product
                resetprop ro.product.device "OP5D3BL1"
                resetprop ro.product.system.device "CPH2691"
                resetprop ro.product.vendor.device "OP5D3BL1"
                resetprop ro.product.odm.device "OP5D3BL1"
                resetprop ro.product.product.device "OP5D3BL1"
                resetprop ro.product.system_ext.device "OP5D3BL1"
                resetprop ro.product.product.model "CPH2691"
                resetprop ro.product.model "CPH2691"
                resetprop ro.product.system.model "CPH2691"
                resetprop ro.product.system_ext.model "CPH2691"
                resetprop ro.product.vendor.model "CPH2691"
                resetprop ro.product.odm.model "CPH2691"
                resetprop ro.boot.hardware.revision "IN"
                ;;
esac
exit 0
