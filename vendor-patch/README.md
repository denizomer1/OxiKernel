# Galaxy A50 vendor patch

Bu çalışma yalnız aşağıdaki Samsung Galaxy A50 vendor imajını destekler:

- Firmware: `A505FDDS9CWA1` (Android 11)
- Device: `a50`
- Girdi SHA-256: `609385bbd8cc20b079f8a606039be171da84e7bf6e1a67752298e45c00e944b1`

## Kullanım

```bash
./vendor-patch/patch_vendor.sh /path/to/vendor.img
```

Çıktı `vendor-patch/output/vendor-a50-multidisabled.img` konumuna yazılır.
Çıktı 800 MiB boyutunda raw ext4 imajıdır; sparse Android imajı değildir.

## Uygulanan değişiklikler

- `fstab.exynos9610`: `fileencryption=ice` devre dışı bırakılır ve `encryptable` kullanılır.
- VaultKeeper init servisleri devre dışı bırakılır.
- PROCA init servisi devre dışı bırakılır.
- PROCA ve WSM VINTF manifest girdileri kaldırılır.
- VaultKeeper VINTF manifest girdisi kaldırılır.
- `/vendor/bin/vaultkeeperd` çalıştırma izinleri kaldırılır.

Dosya sahiplikleri ve SELinux etiketleri korunur. Orijinal sparse vendor imajı değiştirilmez.

Multidisabler'ın `system` bölümündeki stock recovery restorasyonunu kapatan değişikliği vendor imajına dahil değildir.
