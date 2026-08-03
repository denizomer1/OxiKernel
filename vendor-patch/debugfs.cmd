rm /etc/fstab.exynos9610
write vendor-patch/files/fstab.exynos9610 /etc/fstab.exynos9610
set_inode_field /etc/fstab.exynos9610 mode 0100644
set_inode_field /etc/fstab.exynos9610 uid 0
set_inode_field /etc/fstab.exynos9610 gid 0
ea_set /etc/fstab.exynos9610 security.selinux u:object_r:vendor_configs_file:s0

rm /etc/init/vaultkeeper_common.rc
write vendor-patch/files/vaultkeeper_common.rc /etc/init/vaultkeeper_common.rc
set_inode_field /etc/init/vaultkeeper_common.rc mode 0100644
set_inode_field /etc/init/vaultkeeper_common.rc uid 0
set_inode_field /etc/init/vaultkeeper_common.rc gid 0
ea_set /etc/init/vaultkeeper_common.rc security.selinux u:object_r:vendor_configs_file:s0

rm /etc/init/pa_daemon_teegris.rc
write vendor-patch/files/pa_daemon_teegris.rc /etc/init/pa_daemon_teegris.rc
set_inode_field /etc/init/pa_daemon_teegris.rc mode 0100644
set_inode_field /etc/init/pa_daemon_teegris.rc uid 0
set_inode_field /etc/init/pa_daemon_teegris.rc gid 0
ea_set /etc/init/pa_daemon_teegris.rc security.selinux u:object_r:vendor_configs_file:s0

rm /etc/vintf/manifest.xml
write vendor-patch/files/manifest.xml /etc/vintf/manifest.xml
set_inode_field /etc/vintf/manifest.xml mode 0100644
set_inode_field /etc/vintf/manifest.xml uid 0
set_inode_field /etc/vintf/manifest.xml gid 0
ea_set /etc/vintf/manifest.xml security.selinux u:object_r:vendor_configs_file:s0

rm /etc/vintf/manifest/vaultkeeper_manifest.xml
write vendor-patch/files/vaultkeeper_manifest.xml /etc/vintf/manifest/vaultkeeper_manifest.xml
set_inode_field /etc/vintf/manifest/vaultkeeper_manifest.xml mode 0100644
set_inode_field /etc/vintf/manifest/vaultkeeper_manifest.xml uid 0
set_inode_field /etc/vintf/manifest/vaultkeeper_manifest.xml gid 0
ea_set /etc/vintf/manifest/vaultkeeper_manifest.xml security.selinux u:object_r:vendor_configs_file:s0

set_inode_field /bin/vaultkeeperd mode 0100000
