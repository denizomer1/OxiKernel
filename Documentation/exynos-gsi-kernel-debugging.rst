Exynos GSI kernel compatibility debugging
=========================================

Do not convert a Treble userspace workaround into a kernel change until the
failing kernel interface has been identified. Camera IDs, Samsung radio HIDL or
AIDL interfaces, audio policy, VNDK compatibility and framework FOD support are
not kernel problems.

Collecting evidence
-------------------

Boot the affected GSI, reproduce USB and touch-resume failures at least once,
then run from a host with ``adb`` in ``PATH``::

  tools/gsi/collect-exynos-gsi-diagnostics.sh

The command creates a timestamped ``.tar.gz`` archive. Root is optional, but a
rooted ``adb shell`` is needed for a complete ``dmesg``. The collector covers:

* BPF programs, pinned maps, cgroups, netd and DnsResolver failures;
* Exynos DWC3, UDC, ConfigFS gadget and USB PHY state;
* Samsung ``sec_ts`` input open/close and suspend/resume events;
* EROFS mounts, compression/config support and first-stage mount failures;
* battery power-supply sysfs nodes and relevant SELinux denials.

Interpretation
--------------

Missing ``/sys/fs/bpf/netd_shared`` entries must be correlated with the first
verifier or loader error. Enabling another Kconfig option does not fix a missing
BPF helper or incompatible map ABI.

An empty ``/sys/class/udc`` points to DWC3/PHY probe or device-tree ordering.
An existing UDC which is not linked below ``/config/usb_gadget`` instead points
to init, USB HAL, property or SELinux handling.

The Samsung touchscreen driver normally follows input-device open/close events.
Its system PM callbacks only maintain low-power completion state. Enabling the
commented power-cycle code in those callbacks without logs can double-disable
the IRQ or race with the display/input path.

An EROFS Kconfig entry only proves that the driver was built. Confirm that the
actual system partition is mounted as EROFS and that the image compression and
xattr/security features are supported by the backport.
