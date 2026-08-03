
# MintFreshed Kernel

Mint, Samsung Galaxy A50 için geliştirilen, Exynos 9610 tabanlı ve One UI öncelikli özel bir Android çekirdeğidir. Samsung'un yayımladığı çekirdek kaynaklarını temel alır; günlük kullanımda akıcılık, düşük gecikme ve verimli kaynak kullanımı hedefleyen ek iyileştirmeler içerir.

> [!WARNING]
> Özel çekirdek yüklemek cihazın açılmamasına, veri kaybına veya güvenlik özelliklerinin kalıcı olarak devre dışı kalmasına neden olabilir. İşleme başlamadan önce verilerinizi yedekleyin. Tüm sorumluluk kullanıcıya aittir.

## Genel bakış

| Özellik | Bilgi |
| --- | --- |
| Desteklenen cihaz | Samsung Galaxy A50 (`a50`, SM-A505 ailesi) |
| SoC | Samsung Exynos 9610 |
| Çekirdek tabanı | Linux 4.14.194 |
| Desteklenen Android sürümleri | Android 11 ve 12 |
| ROM türleri | One UI ve AOSP tabanlı ROM'lar |
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
- One UI ve AOSP için ayrı yapılandırmalar
- İsteğe bağlı KernelSU entegrasyonu
- Linux upstream ve farklı Android cihazlarından taşınan düzeltmeler

## Hazır paketi kurma

### Gereksinimler

- Kilidi açılmış bootloader
- TWRP, SHRP veya ZIP yükleyebilen uyumlu bir özel recovery
- Cihaz ve kurulu ROM için doğru Mint paketi
- Önemli verilerin ve mevcut `boot` bölümünün yedeği

Samsung Knox sayacı, bootloader kilidi açıldığında kalıcı olarak tetiklenebilir. Bankacılık uygulamaları, Secure Folder ve bazı DRM özellikleri etkilenebilir.

### Doğru paketi seçme

- Samsung stok yazılımı veya One UI tabanlı ROM kullanıyorsanız `OneUI` paketini seçin.
- LineageOS ve diğer AOSP tabanlı ROM'larda `AOSP` paketini seçin.
- Android sürümü paket adındaki sürümle aynı olmalıdır (`A11` veya `A12`).
- Root istemiyorsanız standart paketi, KernelSU kullanacaksanız adında `KSU` bulunan paketi seçin.
- Normal kullanımda `Enforcing` paket önerilir. `Permissive` yalnız hata ayıklama içindir ve güvenli değildir.

### Kurulum

1. Uygun ZIP paketini [GitHub Releases](https://github.com/FreshROMs/android_kernel_samsung_exynos9610_mint/releases) sayfasından indirin.
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

KernelSU ile derleme yapabilmek için alt modülleri de indirin:

```bash
git clone --recurse-submodules \
  https://github.com/FreshROMs/android_kernel_samsung_exynos9610_mint.git
cd android_kernel_samsung_exynos9610_mint
```

Depoyu daha önce klonladıysanız:

```bash
git submodule update --init --recursive
```

### 3. Derlemeyi başlatın

`build.sh`, gerekli Proton Clang araç zincirini ilk çalıştırmada otomatik olarak `toolchain/` dizinine indirir, yapılandırmaları birleştirir ve paketi hazırlar.

One UI 4 / Android 12 için önerilen standart derleme:

```bash
./build.sh --device a50 --variant oneui --android 12
```

AOSP 12 için:

```bash
./build.sh --device a50 --variant aosp --android 12
```

KernelSU eklemek için:

```bash
./build.sh --device a50 --variant oneui --android 12 --kernelsu
```

Recovery entegrasyonunda kullanılacak yalnız çekirdek imajını üretmek için:

```bash
./build.sh --device a50 --variant recovery --android 12
```

Android 11 hedefliyorsanız komutlardaki `--android 12` bölümünü `--android 11` olarak değiştirin.

### Derleme seçenekleri

```text
-d, --device <cihaz>     Hedef cihaz (zorunlu; şu anda yalnız a50)
-v, --variant <tür>      oneui, aosp veya recovery (zorunlu)
-a, --android <sürüm>    Android sürümü (11 veya 12; varsayılan: 11)
-k, --kernelsu           KernelSU desteğini etkinleştirir
-n, --no-clean           Temizleme yapmadan artımlı derler
-p, --permissive         SELinux permissive derlemesi üretir (önerilmez)
-h, --help               Yardım ekranını gösterir
```

Tüm seçenekleri doğrudan görmek için:

```bash
./build.sh --help
```

### Derleme çıktıları

Başarılı derlemenin dosyaları `out/` dizinine yazılır:

- `Mint-*.zip` veya `MintBeta-*.zip`: recovery üzerinden kurulabilir paket
- `boot.img`: doğrudan boot imajı
- `Image`: yalnız `recovery` varyantında üretilen ham ARM64 çekirdek imajı

Derlemeyi sıfırdan tekrarlamak için normal komutu yeniden çalıştırın. Betik varsayılan olarak `make clean` ve `make mrproper` uygular. Yalnız ne yaptığınızı biliyorsanız daha hızlı artımlı derleme için `--no-clean` kullanın.

## Sorun giderme

### Araç zinciri indirilemiyor

`git` kurulu ve GitLab erişilebilir olmalıdır. Yarım kalmış bir indirme varsa `toolchain/` dizinini kaldırıp derlemeyi yeniden başlatın.

### `libncurses.so.5` bulunamıyor

Proton Clang 13 eski bir kullanıcı alanı hedeflediğinden bazı yeni dağıtımlarda bu hata görülebilir. Öncelikle dağıtımınızın uyumluluk paketini kullanın. Paket bulunmuyorsa Ubuntu 22.04 tabanlı bir konteyner veya sanal makineyle derleyin; sistem kitaplıklarına elle sembolik bağ oluşturmayın.

### Derleme sonunda `Image not built successfully` hatası

Bu mesaj asıl hatanın özetidir. Terminal çıktısında bundan önce görünen ilk `error:` satırını inceleyin. Artımlı derleme kullandıysanız `--no-clean` seçeneğini kaldırıp yeniden deneyin.

### Cihaz açılmıyor

Paketin cihaz, ROM türü ve Android sürümüyle eşleştiğini kontrol edin. Ardından recovery üzerinden önceki `boot` yedeğini veya ROM'un özgün boot imajını geri yükleyin.

## Hata bildirimi

Bir hata bildirirken aşağıdakileri ekleyin:

- Tam cihaz modeli (ör. `SM-A505F`)
- Mint sürümü ve kullanılan paket adı
- Android ve ROM/One UI sürümü
- Baseband sürümü
- Sorunu yeniden oluşturma adımları
- İlgili `logcat`, `dmesg` ve `kmsg` kayıtları

Hataları [GitHub Issues](https://github.com/FreshROMs/android_kernel_samsung_exynos9610_mint/issues) üzerinden bildirebilirsiniz.

## Kaynaklar ve teşekkürler

Mint, aşağıdaki projelerden ve geliştiricilerden alınan çalışmaları içerir. Yazarlık bilgileri mümkün olduğunca commit geçmişinde korunmuştur.

- [Cruel Kernel](https://github.com/CruelKernel/samsung-exynos9820/) — evdenis
- [GaltsGulch](https://github.com/RealJohnGalt/GaltsGulch-sm8150) — RealJohnGalt
- [DragonHeart Kernel](https://github.com/cyberknight777/dragonheart_kernel_oneplus_sm8150) — cyberknight777
- [Sultan Kernel](https://github.com/kerneltoast/android_kernel_google_floral) — kerneltoast
- [ThunderStorms Kernel](https://github.com/ThunderStorms21th/Galaxy-S10) — ThunderStorms21th
- [Cosmic Fresh](https://github.com/Dark-Matter7232/CosmicFresh-Hanoip) — Dark-Matter7232
- [Motorola Exynos kernel sources](https://github.com/MotorolaMobilityLLC/kernel-slsi)
- [Quantum Kernel](https://github.com/prashantpaddune/android_kernel_samsung_a50dd) — prashantpaddune
- [Zeus Kernel](https://github.com/THEBOSS619/Note9-Zeus-Q10.0) — THEBOSS619
- [Galaxy A51 kernel sources](https://github.com/ianmacd/a51xx) — ianmacd
- [StormBreaker Kernel](https://github.com/stormbreaker-project/kernel_xiaomi_surya) ve [Stratosphere Kernel](https://github.com/Stratosphere-Kernel/android_kernel_xiaomi_surya)
- [Artemis Kernel](https://github.com/celtare21/kernel_google_coral) — celtare21
- [GS101/Tensor kernel sources](https://github.com/AndreiLux/GS101) — Google ve AndreiLux

Linux çekirdeğinin özgün belgeleri için [README_Kernel](README_Kernel) dosyasına bakın.
