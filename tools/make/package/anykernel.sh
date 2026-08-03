### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
do.devicecheck=1
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
supported.patchlevels=2021-04 -
'; } # end properties


### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# boot shell variables
BLOCK=/dev/block/platform/13520000.ufs/by-name/boot;
IS_SLOT_DEVICE=0;
RAMDISK_COMPRESSION=auto;
NO_BLOCK_DISPLAY=1;
PATCH_VBMETA_FLAG=0;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# TenSeventySeven 2021 - Enable Pageboost and RAM Plus
AK_FOLDER=/tmp/anykernel
mount /system/
mount /system_root/
mount /vendor/
mount -o rw,remount -t auto /system > /dev/null
mount -o rw,remount -t auto /vendor > /dev/null

# Accomodate Exynos9611 devices' init.hardware.rc
if [ -f "/vendor/etc/init/init.exynos9611.rc" ]; then
	VENDOR_INIT_RC=/vendor/etc/init/init.exynos9611.rc
else
	VENDOR_INIT_RC=/vendor/etc/init/init.exynos9610.rc
fi

if ! blkid '/dev/block/platform/13520000.ufs/by-name/vendor' | grep -q 'erofs'; then
	ui_print "  - AOSP ROM detected!"
	ui_print "    - Enabling native ZRAM writeback"

	mkdir -p /vendor/overlay
	cp -rf $AK_FOLDER/files_aosp/vendor/overlay/MintZramWb.apk /vendor/overlay/MintZramWb.apk
	cp -rf $AK_FOLDER/files_aosp/vendor/etc/fstab.zram /vendor/etc/fstab.zram

	chmod 644 /vendor/overlay/MintZramWb.apk
	chmod 644 /vendor/etc/fstab.zram

	patch_prop /vendor/build.prop 'ro.zram.mark_idle_delay_mins' '60'
	patch_prop /vendor/build.prop 'ro.zram.first_wb_delay_mins' '1440'
	patch_prop /vendor/build.prop 'ro.zram.periodic_wb_delay_hours' '24'
	replace_string ${VENDOR_INIT_RC} 'swapon_all /vendor/etc/fstab.dummy' 'swapon_all /vendor/etc/fstab.exynos9610' 'swapon_all /vendor/etc/fstab.zram' global
	replace_string ${VENDOR_INIT_RC} 'swapon_all /vendor/etc/fstab.dummy' 'swapon_all /vendor/etc/fstab.sqzr' 'swapon_all /vendor/etc/fstab.zram' global
	append_file ${VENDOR_INIT_RC} 'swapon_all /vendor/etc/fstab.zram' init.zram.rc
fi

umount /system
umount /system_root
umount /vendor

## AnyKernel boot install
split_boot;

process_ramdisk;

flash_boot;

# Flash dtb
ui_print "  - Installing Exynos device tree blob (DTB)...";
flash_generic dtb;
## end boot install
