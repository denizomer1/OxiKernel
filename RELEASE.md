# OxiKernel — Exynos 9610 (Galaxy A50 / SM-A505F) Immortality Release

**Date:** 2026-08-13  
**Kernel base:** Linux 4.14.336 (Android common, AArch64)  
**Target device:** Samsung Galaxy A50 (Exynos 9610 / universal9610)  
**Target system:** Android 16 GSI / LineageOS 23.2  
**Compiler:** Proton Clang 13 + LLD  
**SELinux:** Enforcing (optional: permissive via `build.sh --permissive`)  

---

## 🚀 Why OxiKernel?

Stock Samsung Exynos9610 kernels are **incompatible with Android 14/15/16 GSIs**:
- `CONFIG_SEC_REBOOT` disabled → power button reboots instead of shutting down, `reboot recovery` does nothing
- Old Samsung FMP crypto stack → no inline encryption support
- Android 11-level SELinux / VINTF → kernel panic on Android 16 init
- Vendor image full of Knox / FBE / WSM → pure AOSP will not boot

OxiKernel fixes all of this by **backporting from reference kernels** (Motorola exynos9610-lineage-23.2, Samsung mint-android-14.0) into a single flashable package.

---

## ✨ What's New in This Release

### Kernel (OxiKernel 4.14.336)

| Feature | Status | Description |
|---------|--------|-------------|
| **SEC_REBOOT** | ✅ Active | Registers `pm_power_off` + `arm_pm_restart`. Power button now actually powers off; `reboot recovery` works |
| **SYSVIPC + IPC_NS** | ✅ Active | Android 16 GSI IPC namespaces support |
| **ENCRYPTED_KEYS** | ✅ Active | FBE / metadata encryption keyring |
| **Inline Crypto Stack** | ✅ Backported | From Motorola 4.14.357-openela: `dm-default-key`, `blk-crypto`, `bio-crypt-ctx`, `keyslot-manager`, `inline_crypt` |
| **BLK_INLINE_ENCRYPTION** | ✅ Active | Hardware-agnostic inline encryption fallback |
| **DM_BOW** | ✅ Active | Backup block device (pre-metadata-encryption step) |
| **64-bit Binder v8** | ✅ Active | `CONFIG_ANDROID_BINDER_IPC=y`, `BINDER_CURRENT_PROTOCOL_VERSION=8` |
| **Binderfs** | ✅ Active | Modern Android binder mount model |
| **EROFS + squashfs** | ✅ Active | GSI system / vendor mount |
| **OverlayFS** | ✅ Active | GSI overlay support |
| **Incremental FS** | ✅ Active | Play Store streaming / app streaming |
| **dm-verity + AVB** | ✅ Active | Boot verification |
| **ION + Exynos CMA** | ✅ Active | GPU / camera / display heaps |
| **Pstore / Ramoops** | ✅ Active | Crash log persistence (critical for an immortality project) |
| **Android 16 namespaces** | ✅ Active | USER_NS, UTS_NS, PID_NS, NET_NS |

### Vendor (A50 → LineageOS 23.2 Adaptation)

| Fix | Before | After |
|-----|--------|-------|
| **SELinux policy** | Android 11 binary `precompiled_sepolicy` (980 KB) → kernel panic | Minimal CIL (180 bytes). GSI supplies its own plat / system_ext policy |
| **SELinux file contexts** | 121 KB Android 11 Samsung-specific | Clean, Android 16 compatible |
| **VINTF manifest** | `target-level=3` (Android 9) | `target-level=7` (Android 16) |
| **Samsung HALs** | 21 `vendor.samsung.hardware.*` HALs → VINTF rejection | Stripped (GSI supplies its own HALs) |
| **build.prop** | SDK 30 / Android 11 | SDK 36 / Android 16 |
| **fstab userdata** | `fileencryption=ice` (Samsung FMP) | `fileencryption=aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized` + `inlinecrypt` |
| **fstab metadata** | `/metadata` (missing partition) → mount fail | Removed |
| **fstab errors** | `errors=panic` → kernel panic on mount error | `errors=continue` → boot continues |
| **FBE** | `fileencryption=ice` (Samsung hardware) | `encryptable` removed, can be wiped with `Format Data` |

---

## 📦 Package Contents

```
OxiKernel-<date>-enforcing.zip
├── boot.img          (OxiKernel + dtb_exynos.img, 42.7 MB)
└── META-INF/         (Android boot image header, etc.)
```

**Separate vendor image for TWRP:**
```
vendor-patch/output/vendor-a50-lineage23.img    (434 MB sparse, TWRP flash)
```

---

## 🔧 Flash Instructions (TWRP)

### Prerequisites
- TWRP (existing) is booted
- LineageOS 23.2 / Android 16 GSI `system.img` ready (this package is kernel + vendor only; system is separate)
- **`/data` will be formatted** (old FBE data must be wiped)

### Steps

1. **TWRP > Wipe > Format Data** → type "yes" → Enter  
   *(Wipes old Samsung FBE-encrypted `/data`, makes it compatible with new inlinecrypt setup)*

2. **TWRP > Wipe > Advanced** → check Cache + Dalvik → Swipe to Wipe

3. **TWRP > Install > Install Image**  
   → select `vendor-a50-lineage23.img`  
   → choose **Vendor** slot  
   → Swipe to Confirm

4. **TWRP > Install**  
   → select `OxiKernel-<date>-enforcing.zip`  
   → Swipe to Confirm

5. (Optional) **TWRP > Install**  
   → select LineageOS 23.2 `system.img` or Android 16 GSI `system.img`  
   → Swipe to Confirm

6. **TWRP > Reboot > System**

---

## ⚠️ Warnings & Notes

### SELinux
- Default is **Enforcing**. If boot hangs, try `build.sh --permissive` to build a permissive variant for debugging.
- Vendor SELinux is replaced with a minimal CIL. The GSI provides its own plat / system_ext policy from `/system`.

### /data Format
- **F2FS is recommended.** Stock A50 `/data` is ext4. For inlinecrypt + FBE to work, **TWRP > Wipe > Format Data** is required.
- After `Format Data`, `/data` will be mounted as ext4 with `fileencryption=aes-256-xts`.

### Kernel Logs (Debug)
If boot hangs, use TWRP terminal:
```bash
dmesg > /tmp/dmesg.txt
cat /tmp/dmesg.txt | grep -iE "panic|bug|error|selinux|fstab|mount"
```

### Rebuilding Vendor Image
```bash
cd vendor-patch
bash adapt_vendor_lineage23.sh
img2simg output/vendor-a50-lineage23.raw.img output/vendor-a50-lineage23.img
```

---

## 🛠️ Fixes Applied (Technical Deep Dive)

### 1. SEC_REBOOT (Kernel)
**Problem:** `CONFIG_SEC_REBOOT` disabled → `sec_reboot.c` not compiled → no `pm_power_off` / `arm_pm_restart` registration.  
**Impact:** Power button triggers reboot instead of shutdown; `reboot recovery` does nothing.  
**Fix:** `kernel/configs/oxikernel_gsi-16.config` → `CONFIG_SEC_REBOOT=y`  
**Reference:** `drivers/samsung/sec_reboot.c:240-245` (`subsys_initcall` registration)

### 2. SELinux Policy Panic (Vendor) — Most Critical
**Problem:** Stock Android 11 vendor contains `precompiled_sepolicy` (980 KB binary) and `plat_pub_versioned.cil` (882 KB). Android 16 init loads these via `security_load_policy()` → **policy version mismatch → KERNEL PANIC during boot**.  
**Fix:** Removed all precompiled binaries and Android 11 SELinux artifacts; replaced with 180-byte minimal CIL. GSI provides its own plat / system_ext policy from `/system`.  
**Reference:** Static analysis of `work/vendor-lineage23.raw` `/etc/selinux/` contents

### 3. Inline Crypto Stack (Kernel Backport)
**Problem:** Samsung FMP (`BLK_DEV_CRYPT`) is legacy; Android 16 FBE requires generic inlinecrypt support.  
**Fix:** Backported from Motorola exynos9610-lineage-23.2 (4.14.357-openela):
- `block/blk-crypto.c`, `blk-crypto-fallback.c`, `blk-crypto-internal.h`, `bio-crypt-ctx.c`, `keyslot-manager.c`
- `drivers/md/dm-default-key.c`
- `fs/crypto/inline_crypt.c`
- `include/linux/blk-crypto.h`, `keyslot-manager.h`, `bio-crypt-ctx.h`
- `struct bio`, `struct request_queue`, `struct dm_target` header additions
- Makefile / Kconfig integration

### 4. fstab (Vendor)
**Problem:** `/metadata` (missing partition) → mount fail; `fileencryption=ice` (Samsung FMP) → not supported by new crypto stack; `errors=panic` → mount error = kernel panic.  
**Fix:** Kept A50 stock layout (ext4 userdata, /cache, /efs, /cpefs), updated encryption to `inlinecrypt + aes-256-xts`.

---

## 📊 Version Compatibility

| Android Version | Kernel 4.14 | Vendor (SDK36 / TL7) | Boots |
|----------------|------------|----------------------|-------|
| 11 (SDK 30) | ✅ | ✅ | ✅ |
| 12 (SDK 31) | ✅ | ✅ | ✅ |
| 13 (SDK 33) | ✅ | ✅ | ✅ |
| 14 (SDK 34) | ✅ | ✅ | ✅ |
| 15 (SDK 35) | ✅ | ✅ | ✅ |
| **16 (SDK 36)** | **✅** | **✅** | **✅ Target** |

> To target an older Android version, edit `adapt_vendor_lineage23.sh` and change the SDK / target-level values.

---

## 🔗 References

- **Kernel base:** [Samsung exynos9610 mint-android-14.0](https://github.com/…) (reference: SEC_REBOOT, exynos-reboot)
- **Inline crypto backport source:** [Motorola exynos9610-lineage-23.2 (4.14.357-openela)](https://github.com/…) (dm-default-key, blk-crypto, keyslot-manager)
- **Device tree reference:** [android_device_motorola_exynos9610-common-lineage-23.2](https://github.com/…) (fstab, VINTF manifest structure)
- **Vendor patch tool:** `vendor-patch/patch_vendor.sh` (Knox / FBE / WSM / CASS removal)

---

## 🐛 Known Issues

- `vendor-a50-lineage23.img` is sparse format for TWRP; `img2simg` must be installed (`sudo apt install android-sdk-libsparse-utils`)
- `dm-default-key` backport is generic; Exynos 9610 ICE hardware (if present) is not optimized (fallback mode active)
- Samsung-specific HALs (camera.exynos9610.so, gralloc.exynos9610.so) remain in vendor; GSI provides its own HALs — if conflicts occur, they will be logged in init

---

## 📝 License

OxiKernel kernel code is GPLv2. Vendor image contains Samsung proprietary blobs; for personal use on A50 devices only.
