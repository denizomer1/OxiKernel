
# MintFreshed Kernel

MintFreshed, yalnız Samsung Galaxy A50 için tutulan Exynos 9610 tabanlı Android çekirdeğidir. Android 12 AOSP, GSI ve LineageOS tabanlı sistemleri hedefler. One UI, başka cihazlar ve yerleşik root çözümleri desteklenmez.

> [!WARNING]
> Özel çekirdek yüklemek cihazın açılmamasına, veri kaybına veya güvenlik özelliklerinin kalıcı olarak devre dışı kalmasına neden olabilir. İşleme başlamadan önce verilerinizi yedekleyin. Tüm sorumluluk kullanıcıya aittir.

## Genel bakış

| Özellik | Bilgi |
| --- | --- |
| Desteklenen cihaz | Samsung Galaxy A50 (`a50`, SM-A505 ailesi) |
| SoC | Samsung Exynos 9610 |
| Çekirdek tabanı | Linux 4.14.194 |
| Desteklenen Android sürümü | Android 12-16 |
| ROM türleri | AOSP tabanlı ROM'lar |
| Mimariler | ARM64 çekirdek, ARM32 uyumluluk katmanı |
| Derleyici | Proton Clang 13 |
| Lisans | Çekirdek: GPL-2.0, derleme betiği: GPL-3.0 |

Başlıca özellikler:

- Clang ve Link-Time Optimization (LTO) ile derleme
- Düşük gecikmeye göre düzenlenmiş Exynos Mobile Scheduler (EMS)
- Galaxy S10/S20 kaynaklı zamanlayıcı ve governor geliştirmeleri
- Ek I/O zamanlayıcıları; varsayılan olarak `anxiety`
- ZRAM, RAM Plus ve süreç başına takas desteği
- WireGuard desteği
- AOSP tabanlı ROM'lar için özelleştirilmiş yapılandırma
- Linux upstream ve farklı Android cihazlarından taşınan düzeltmeler

Kaynak ağacının device-tree bölümü yalnız A50 SWA donanım revizyonlarını (`00`, `01`, `02`, `03`, `04`, `06`) ve bunların Exynos 9610 bağımlılıklarını içerir. A50s, A80, M30s, Exynos 9611 ve diğer ARM64 kartların DTS dosyaları kaldırılmıştır. Donanımın çalışması için gereken Samsung ekran, kamera, modem, ses, sensör ve güç sürücüleri korunmuştur.

## Hazır paketi kurma

### Gereksinimler

- Kilidi açılmış bootloader
- TWRP, SHRP veya ZIP yükleyebilen uyumlu bir özel recovery
- Cihaz ve kurulu ROM için doğru Mint paketi
- Önemli verilerin ve mevcut `boot` bölümünün yedeği

Samsung Knox sayacı, bootloader kilidi açıldığında kalıcı olarak tetiklenebilir. Bankacılık uygulamaları, Secure Folder ve bazı DRM özellikleri etkilenebilir.

### Doğru paketi seçme

- MintFreshED yalnız LineageOS ve diğer AOSP tabanlı ROM'lar için derlenir. Samsung stok yazılımı ve One UI tabanlı ROM'lar desteklenmez.
- Android 12 tabanlı bir ROM kullanılmalıdır.
- Normal kullanımda `Enforcing` paket önerilir. `Permissive` yalnız hata ayıklama içindir ve güvenli değildir.

### Kurulum

1. `out/` dizinindeki uygun MintFreshED ZIP paketini kullanın.
2. Paketi telefonun dahili depolamasına veya SD karta kopyalayın.
3. Recovery moduna yeniden başlatın.
4. Mümkünse mevcut `boot` bölümünün yedeğini alın.
5. Mint ZIP dosyasını flaşlayın.
6. Recovery yerine doğrudan sisteme yeniden başlatın.

İlk açılış normalden uzun sürebilir. Cihaz açılmazsa recovery'ye dönüp yedeklediğiniz `boot` imajını veya ROM'un özgün çekirdeğini geri yükleyin.

## Kaynak koddan derleme

Derleme yalnız 64 bit Linux üzerinde desteklenir. En sorunsuz ve CI ile aynı ortam Ubuntu 22.04 LTS'dir. Güncel Ubuntu/Debian, Fedora ve Arch tabanlı dağıtımlarda da aşağıdaki bağımlılıklarla derlenebilir; eski Proton Clang ikilileri nedeniyle bazı çok yeni dağıtımlarda ek uyumluluk paketleri gerekebilir.

En az 20 GB boş disk alanı ve 8 GB RAM önerilir. İlk derlemede araç zinciri indirileceği için internet bağlantısı gerekir.

### 1. Bağımlılıkları kurun

#### Ubuntu 22.04/24.04 ve Debian 12/13

```bash
sudo apt update
sudo apt install -y \
  bc binutils bison build-essential bzip2 cpio flex git jq \
  libelf-dev libncurses-dev libssl-dev libc6-dev-i386 lib32stdc++6 \
  python3 rsync unzip zip
```

#### Fedora

```bash
sudo dnf install -y \
  @development-tools bc binutils bison bzip2 cpio elfutils-libelf-devel \
  flex git glibc-devel.i686 jq ncurses-devel openssl-devel python3 \
  rsync unzip zip
```

#### Arch Linux ve türevleri

```bash
sudo pacman -S --needed \
  base-devel bc binutils bison bzip2 cpio flex git jq libelf ncurses \
  openssl python rsync unzip zip
```

### 2. Kaynak kodu alın

Kaynak kodu indirin:

```bash
git clone https://github.com/denizomer1/mintfresh.git
cd mintfresh
```

### 3. Derlemeyi başlatın

`build.sh`, gerekli Proton Clang araç zincirini ilk çalıştırmada otomatik olarak `toolchain/` dizinine indirir, yapılandırmaları birleştirir ve paketi hazırlar.

AOSP 12 SELinux enforcing derlemesi için:

```bash
./build.sh --enforcing
```

AOSP 12 SELinux permissive derlemesi için:

```bash
./build.sh --permissive
```

### Derleme seçenekleri

```text
--enforcing     SELinux enforcing AOSP 12 çekirdeği üretir
--permissive    SELinux permissive AOSP 12 çekirdeği üretir (önerilmez)
```

Başka cihaz, Android sürümü, ROM varyantı veya artımlı derleme seçeneği yoktur. Betik her çalıştırmada temiz derleme yapar.

### Derleme çıktıları

Başarılı derlemenin dosyaları `out/` dizinine yazılır:

- `MintFreshED-*.zip`: Galaxy A50 recovery üzerinden kurulabilir minimal paket
- `boot.img`: Galaxy A50 için doğrudan boot imajı

ZIP yalnız `boot.img`, `dtb.img` ve Galaxy A50'ye özel minimal recovery kurucusunu içerir. AnyKernel, BusyBox, Magisk, KernelSU veya root yardımcı aracı içermez. Kurucu yalnız cihaz kimliğini denetler ve iki imajı ilgili bölümlere yazar.

Derlemeyi sıfırdan tekrarlamak için normal komutu yeniden çalıştırın. Betik her zaman `make mrproper` ile temiz yapılandırma oluşturur.

### LineageOS/GSI geliştirmesinde kullanım

Bu ağaç A50 device tree içinden standart ARM64 kernel kaynağı olarak kullanılabilir. Derleme yapılandırması üç parçadan oluşur:

- `arch/arm64/configs/exynos9610-a50_core_defconfig`
- `arch/arm64/configs/exynos9610-a50_default_defconfig`
- `kernel/configs/mint_*12.config`

ROM derlemesi çekirdeği kendi build sistemiyle paketleyecekse `build.sh` içindeki aynı config birleştirme sırasını kullanmalıdır. `build.sh` ise bağımsız test ve recovery ZIP üretimi için referans uygulamadır. Android 13+, One UI ve A50 dışı cihazlar bu ağacın hedefi değildir.

## Sorun giderme

### Araç zinciri indirilemiyor

`git` kurulu ve GitLab erişilebilir olmalıdır. Yarım kalmış bir indirme varsa `toolchain/` dizinini kaldırıp derlemeyi yeniden başlatın.

### `libncurses.so.5` bulunamıyor

Proton Clang 13 eski bir kullanıcı alanı hedeflediğinden bazı yeni dağıtımlarda bu hata görülebilir. Öncelikle dağıtımınızın uyumluluk paketini kullanın. Paket bulunmuyorsa Ubuntu 22.04 tabanlı bir konteyner veya sanal makineyle derleyin; sistem kitaplıklarına elle sembolik bağ oluşturmayın.

### Derleme sonunda `Image not built successfully` hatası

Bu mesaj asıl hatanın özetidir. Terminal çıktısında bundan önce görünen ilk `error:` satırını inceleyin.

### Cihaz açılmıyor

Paketin cihaz, ROM türü ve Android sürümüyle eşleştiğini kontrol edin. Ardından recovery üzerinden önceki `boot` yedeğini veya ROM'un özgün boot imajını geri yükleyin.

## Hata bildirimi

Bir hata bildirirken aşağıdakileri ekleyin:

- Tam cihaz modeli (ör. `SM-A505F`)
- Mint sürümü ve kullanılan paket adı
- Android ve ROM sürümü
- Baseband sürümü
- Sorunu yeniden oluşturma adımları
- İlgili `logcat`, `dmesg` ve `kmsg` kayıtları

Hataları [GitHub Issues](hhttps://github.com/denizomer1/mintfresh/issues) üzerinden bildirebilirsiniz.
