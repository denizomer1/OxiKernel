#!/bin/sh
# Collect the kernel/userspace evidence needed to replace GSI workarounds with
# targeted Exynos kernel fixes. Run this script on a host with adb available.

set -eu

ADB=${ADB:-adb}
STAMP=$(date +%Y%m%d-%H%M%S)
OUT=${1:-exynos-gsi-diagnostics-$STAMP}

command -v "$ADB" >/dev/null 2>&1 || {
	printf '%s\n' "adb was not found (set ADB=/path/to/adb if needed)" >&2
	exit 1
}

mkdir -p "$OUT"

capture()
{
	name=$1
	shift
	"$ADB" wait-for-device
	{
		printf 'command:'
		printf ' %s' "$@"
		printf '\n\n'
		"$ADB" shell "$@"
	} >"$OUT/$name.txt" 2>&1 || true
}

capture_shell()
{
	name=$1
	command=$2
	"$ADB" wait-for-device
	{
		printf 'command: %s\n\n' "$command"
		"$ADB" shell "$command"
	} >"$OUT/$name.txt" 2>&1 || true
}

capture_root()
{
	name=$1
	command=$2
	"$ADB" wait-for-device
	{
		printf 'command: su -c %s\n\n' "$command"
		"$ADB" shell su -c "$command"
	} >"$OUT/$name.txt" 2>&1 || true
}

"$ADB" wait-for-device

# Capture the volatile buffers before queries or a flaky USB connection can
# disconnect adb. A second copy is collected at the end when possible.
capture logcat logcat -b all -d -v threadtime
capture_root dmesg 'dmesg'

# Keep the property set focused: a full getprop dump may contain identifiers.
capture_shell properties \
	'getprop | grep -E "\[(ro\\.(build\\.version|product|vendor|board|boot)|ro\\.treble|ro\\.vndk|persist\\.sys\\.phh|sys\\.usb|vendor\\.usb)"'
capture uname uname -a
capture mounts mount
capture filesystems cat /proc/filesystems
capture services service list
capture_shell usb_state \
	'echo "== UDC =="; ls -la /sys/class/udc 2>&1; for f in /sys/class/udc/*/state; do echo "== $f =="; cat "$f"; done; echo "== gadget =="; find /config/usb_gadget -maxdepth 3 -type f 2>/dev/null | sort'
capture_shell bpf_state \
	'echo "== mounts =="; mount | grep -E "bpf|cgroup"; echo "== bpffs =="; find /sys/fs/bpf -maxdepth 4 -print 2>/dev/null | sort; echo "== cgroups =="; cat /proc/cgroups'
capture input_devices cat /proc/bus/input/devices
capture_shell touch_sysfs \
	'find /sys/class/sec /sys/bus/i2c/devices -maxdepth 4 \( -iname "*tsp*" -o -iname "*touch*" -o -iname "*sec_ts*" \) -print 2>/dev/null | sort'
capture_shell power_supply \
	'for d in /sys/class/power_supply/*; do echo "== $d =="; for f in type status capacity voltage_now current_now temp charge_counter; do test -r "$d/$f" && echo "$f=$(cat "$d/$f")"; done; done'
capture_shell erofs \
	'echo "== mounts =="; mount | grep -E "erofs| /system | /system_ext | /product "; echo "== config =="; zcat /proc/config.gz 2>/dev/null | grep -E "CONFIG_EROFS|CONFIG_LZ4"'
capture_shell kernel_config \
	'zcat /proc/config.gz 2>/dev/null | grep -E "CONFIG_(BPF|CGROUP_BPF|NET_CLS|NET_ACT_BPF|NETFILTER_XT_MATCH_BPF|EROFS|USB_DWC3|USB_CONFIGFS|F2FS|FS_ENCRYPTION|QUOTA)"'

capture logcat_final logcat -b all -d -v threadtime
capture_root dmesg_final 'dmesg'

test -s "$OUT/logcat.txt" || cp "$OUT/logcat_final.txt" "$OUT/logcat.txt"
test -s "$OUT/dmesg.txt" || cp "$OUT/dmesg_final.txt" "$OUT/dmesg.txt"

# Produce smaller, issue-specific views while retaining the raw logs.
grep -iE 'bpf|bpfloader|netbpf|netd|dnsresolver|cgroup' \
	"$OUT/logcat.txt" "$OUT/dmesg.txt" >"$OUT/bpf-errors.txt" 2>/dev/null || true
grep -iE 'dwc3|udc|gadget|configfs|usb.*phy|role.switch|defer' \
	"$OUT/logcat.txt" "$OUT/dmesg.txt" >"$OUT/usb-errors.txt" 2>/dev/null || true
grep -iE 'sec_ts|tsp|touch|input.*(open|close)|suspend|resume' \
	"$OUT/logcat.txt" "$OUT/dmesg.txt" >"$OUT/touch-errors.txt" 2>/dev/null || true
grep -iE 'erofs|fs_mgr|first.stage.mount|avc:.*(system|vendor|sysfs_battery)' \
	"$OUT/logcat.txt" "$OUT/dmesg.txt" >"$OUT/storage-errors.txt" 2>/dev/null || true

tar -czf "$OUT.tar.gz" "$OUT"
printf '%s\n' "Created $OUT.tar.gz"
printf '%s\n' "Review properties.txt before sharing; the script avoids collecting serial-number properties."
