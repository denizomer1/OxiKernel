#!/usr/bin/env bash
# shellcheck disable=SC1090

set -o pipefail

# Directories
TOP="$(pwd)"
TOOLCHAIN="$TOP/toolchain"
OUT_DIR="$TOP/out"
TMP_DIR="$OUT_DIR/tmp"
DEVICE_DB_DIR="$TOP/Documentation/device-db"
BUILD_CONFIG_DIR="$TOP/arch/arm64/configs"
SUB_CONFIG_DIR="$TOP/kernel/configs"

# Toolchain options
BUILD_PREF_COMPILER="clang"

# Build variables - DO NOT CHANGE
export ARCH="arm64"
export SUBARCH="arm64"
export ANDROID_MAJOR_VERSION="r"
export PLATFORM_VERSION="11.0.0"

VERSION=$(grep -m 1    VERSION "$TOP/Makefile"    | sed 's/^.*= //g')
PATCHLEVEL=$(grep -m 1 PATCHLEVEL "$TOP/Makefile" | sed 's/^.*= //g')
SUBLEVEL=$(grep -m 1   SUBLEVEL "$TOP/Makefile"   | sed 's/^.*= //g')

BUILD_DATE="$(date +%s)"

# Fixed build target
BUILD_DEVICE_NAME="a50"
BUILD_ANDROID_PLATFORM=12
BUILD_VARIANT="aosp"
OXIKERNEL_VARIANT="AOSP"
BUILD_KERNEL_PERMISSIVE=false

# Script commands
script_echo() { echo "  $1"; }
exit_script() { exit 1; }

merge_config() {
	if [[ ! -f "$SUB_CONFIG_DIR/oxikernel_$1.config" ]]; then
		script_echo "E: Subconfig not found on config DB!"
		script_echo "   \"$SUB_CONFIG_DIR/oxikernel_$1.config\""
		script_echo "   Make sure it is in the proper directory."
		script_echo " "
		exit_script
	else
		cat "$SUB_CONFIG_DIR/oxikernel_$1.config" >> "$BUILD_CONFIG_DIR/$BUILD_DEVICE_TMP_CONFIG"
	fi
}

# Script functions
VERIFY_TOOLCHAIN() {
    script_echo " "

    if [ -d "$TOOLCHAIN" ]; then
        script_echo "I: Toolchain found at repository root"
    else
        script_echo "I: Toolchain not found at repository root"
        script_echo "   Downloading Proton Clang from kdrag0n/proton-clang..."
        git clone 'https://github.com/kdrag0n/proton-clang.git' "$TOOLCHAIN" --depth 1 2>&1 | sed 's/^/     /'
    fi

    export PATH="${TOOLCHAIN}/bin:$PATH"
	export LD_LIBRARY_PATH="${TOOLCHAIN}/lib:$LD_LIBRARY_PATH"

    # Proton Clang 13
    export CROSS_COMPILE="aarch64-linux-gnu-"
	export CROSS_COMPILE_ARM32="arm-linux-gnueabi-"
	export CC="$BUILD_PREF_COMPILER"
}
VERIFY_DEFCONFIG() {
    if [ ! -f "$BUILD_CONFIG_DIR/$BUILD_DEVICE_CONFIG" ]; then
        script_echo "E: Defconfig not found!"
        script_echo "   \"$BUILD_CONFIG_DIR/$BUILD_DEVICE_CONFIG\""
        script_echo "   Make sure it is in the proper directory."
        script_echo " "
        exit_script
    else
        cat "$BUILD_CONFIG_DIR/$BUILD_DEVICE_CONFIG" > "$BUILD_CONFIG_DIR/$BUILD_DEVICE_TMP_CONFIG"
    fi
}

SET_ANDROIDVERSION() {
    echo "CONFIG_OXIKERNEL_PLATFORM_VERSION=$BUILD_ANDROID_PLATFORM" >> "$BUILD_CONFIG_DIR/$BUILD_DEVICE_TMP_CONFIG"
}
SET_LOCALVERSION() {
    export LOCALVERSION="-OxiKernel-$BUILD_DATE"
}
SET_ZIPNAME() {
    local OXIKERNEL_SELINUX
    OXIKERNEL_SELINUX="Enforcing"
    $BUILD_KERNEL_PERMISSIVE && OXIKERNEL_SELINUX="Permissive"
    FILE_NAME="OxiKernel-${BUILD_DATE}.A12.AOSP-${OXIKERNEL_SELINUX}_A50.zip"
}

BUILD_KERNEL() {
    local JOBS
    JOBS="$(nproc --all)"

    script_echo " "

    make -C "$TOP" CC="$BUILD_PREF_COMPILER" HOSTCC="clang -Qunused-arguments --ld-path=/usr/bin/ld" HOSTCXX="clang++ -Qunused-arguments --ld-path=/usr/bin/ld" AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip "$BUILD_DEVICE_TMP_CONFIG" LOCALVERSION="$LOCALVERSION" 2>&1 | sed 's/^/     /' || exit_script
    make -C "$TOP" CC="$BUILD_PREF_COMPILER" HOSTCC="clang -Qunused-arguments --ld-path=/usr/bin/ld" HOSTCXX="clang++ -Qunused-arguments --ld-path=/usr/bin/ld" AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip -j1 drivers/net/wireless/scsc/ LOCALVERSION="$LOCALVERSION" 2>&1 | sed 's/^/     /' || exit_script
    make -C "$TOP" CC="$BUILD_PREF_COMPILER" HOSTCC="clang -Qunused-arguments --ld-path=/usr/bin/ld" HOSTCXX="clang++ -Qunused-arguments --ld-path=/usr/bin/ld" AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip -j$JOBS LOCALVERSION="$LOCALVERSION" 2>&1 | sed 's/^/     /' || exit_script

    if [ ! -f "$TOP/arch/arm64/boot/Image" ]; then
        script_echo "E: Image not built successfully!"
        script_echo "   Errors can be found above."
        exit_script
    fi
}
BUILD_RAMDISK() {
    local comptype compcmd
    comptype="cpio"
    RAMDISK="ramdisk-new.cpio"

    case "$comptype" in
    gzip)  compcmd="gzip";                          RAMDISK="$RAMDISK.gz" ;;
    lzop)  compcmd="lzop";                          RAMDISK="$RAMDISK.lzo" ;;
    xz)    compcmd="xz -1 -Ccrc32";                 RAMDISK="$RAMDISK.xz" ;;
    lzma)  compcmd="xz -9 -Flzma";                  RAMDISK="$RAMDISK.lzma" ;;
    bzip2) compcmd="bzip2";                         RAMDISK="$RAMDISK.bz2" ;;
    lz4)   compcmd="$TOP/tools/make/bin/lz4 -9";    RAMDISK="$RAMDISK.lz4" ;;
    lz4-l) compcmd="$TOP/tools/make/bin/lz4 -9 -l"; RAMDISK="$RAMDISK.lz4" ;;
    cpio)  compcmd="cat";                           RAMDISK="$RAMDISK" ;;
    esac

    script_echo " "
    script_echo "I: Building ramdisk..."
    script_echo "Compression type: $comptype"

    cd "$TOP/tools/make/ramdisk" || exit
    find . | cpio -R 0:0 -H newc --quiet -o | $compcmd > "$TOP/tools/make/$RAMDISK"
    cd "$TOP" || exit

    if [ ! -f "$TOP/tools/make/$RAMDISK" ]; then
        script_echo " "
		script_echo "E: Ramdisk not built successfully!"
		script_echo "   Errors can be found above."
		exit_script
    fi
}
BUILD_IMAGE() {
    script_echo " "
	script_echo "I: Building kernel image..."
	script_echo "    Header/Page size: $DEVICE_KERNEL_HEADER/$DEVICE_KERNEL_PAGESIZE"
	script_echo "      Board and base: $DEVICE_KERNEL_BOARD/$DEVICE_KERNEL_BASE"
	script_echo " "
	script_echo "     Android Version: $PLATFORM_VERSION"
	script_echo "Security patch level: $PLATFORM_PATCH_LEVEL"

    "$TOP/tools/make/bin/mkbootimg" \
        --kernel "$TOP/arch/arm64/boot/Image" --ramdisk "$TOP/tools/make/$RAMDISK" \
        --cmdline "$KERNEL_CMDLINE" --board "$DEVICE_KERNEL_BOARD" \
        --base "$DEVICE_KERNEL_BASE" --pagesize "$DEVICE_KERNEL_PAGESIZE" \
        --kernel_offset "$DEVICE_KERNEL_OFFSET" --ramdisk_offset "$DEVICE_RAMDISK_OFFSET" \
        --second_offset "$DEVICE_SECOND_OFFSET" --tags_offset "$DEVICE_TAGS_OFFSET" \
		--os_version "$PLATFORM_VERSION" --os_patch_level "$PLATFORM_PATCH_LEVEL" \
		--header_version "$DEVICE_KERNEL_HEADER" --hashtype "$DEVICE_DTB_HASHTYPE" \
		-o "$OUT_DIR/boot.img"

	if [[ ! -f "$OUT_DIR/boot.img" ]]; then
		script_echo " "
		script_echo "E: Kernel image not built successfully!"
		script_echo "   Errors can be found above."
		exit_script
	fi
}
BUILD_PACKAGE() {
    script_echo " "
    script_echo "I: Creating kernel ZIP..."

    mkdir -p "$TMP_DIR"
    cp "$OUT_DIR/boot.img" "$TMP_DIR/boot.img"
    cp "$TOP/arch/arm64/boot/dtb_exynos.img" "$TMP_DIR/dtb.img"
    cp -r "$TOP/tools/make/package/META-INF" "$TMP_DIR/META-INF"

    cd "$TMP_DIR" && zip -9 -r "$OUT_DIR/$FILE_NAME" ./* 2>&1 | sed 's/^/     /'
}

show_usage() {
	script_echo "Usage: $0 <--enforcing|--permissive>"
	script_echo " "
	script_echo "--enforcing     Build AOSP 12 with SELinux enforcing."
	script_echo "--permissive    Build AOSP 12 with SELinux permissive."
	exit 1
}
# Process the only two supported build modes.
[[ $# -eq 1 ]] || show_usage
case "$1" in
--enforcing)  BUILD_KERNEL_PERMISSIVE=false ;;
--permissive) BUILD_KERNEL_PERMISSIVE=true ;;
*)
	script_echo "E: Unknown build mode: $1"
	script_echo " "
	show_usage ;;
esac

KERNEL_CMDLINE="loop.max_part=7"
$BUILD_KERNEL_PERMISSIVE && KERNEL_CMDLINE="androidboot.selinux=permissive $KERNEL_CMDLINE"

# Set variables
source "$DEVICE_DB_DIR/kernel_info.sh"
source "$DEVICE_DB_DIR/$BUILD_DEVICE_NAME.sh"
BUILD_DEVICE_CONFIG="exynos9610-${BUILD_DEVICE_NAME}_core_defconfig"
BUILD_DEVICE_TMP_CONFIG="tmp_exynos9610-${BUILD_DEVICE_NAME}_${BUILD_VARIANT}_defconfig"
export KCONFIG_BUILTINCONFIG="$BUILD_CONFIG_DIR/exynos9610-${BUILD_DEVICE_NAME}_default_defconfig"

SET_LOCALVERSION
SET_ZIPNAME

# Print build information
script_echo "I: Selected device:    $BUILD_DEVICE_NAME"
script_echo "   Selected variant:   $OXIKERNEL_VARIANT"
script_echo "   Kernel version:     $VERSION.$PATCHLEVEL.$SUBLEVEL"
script_echo "   Android version:    $BUILD_ANDROID_PLATFORM"
script_echo "   Output file:        $OUT_DIR/$FILE_NAME"

# Setup build environment
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

VERIFY_TOOLCHAIN
VERIFY_DEFCONFIG
SET_ANDROIDVERSION

script_echo " "
script_echo "I: Clean build!"
touch "$TOP/.config"
make CC="$BUILD_PREF_COMPILER" mrproper 2>&1 | sed 's/^/     /' || exit_script

# Merge subconfigs
merge_config "partial-deknox-$BUILD_ANDROID_PLATFORM"
merge_config "mali-$BUILD_ANDROID_PLATFORM"
merge_config "variant_$BUILD_VARIANT"

if $BUILD_KERNEL_PERMISSIVE; then
	script_echo "WARNING! You're building this kernel in permissive mode!"
	script_echo "         This is insecure and may make your device vulnerable."
	script_echo "         This kernel has NO RESPONSIBILITY on whatever happens next."
	merge_config selinux-permissive
fi

# Build OxiKernel
BUILD_KERNEL
BUILD_RAMDISK
BUILD_IMAGE
BUILD_PACKAGE

# Print end message
TIME_NOW=$(date +%s)
BUILD_TIME=$((TIME_NOW-BUILD_DATE))
BUILD_TIME_STR=$(printf '%02dh:%02dm:%02ds\n' $((BUILD_TIME/3600)) $((BUILD_TIME%3600/60)) $((BUILD_TIME%60)))

script_echo " "
script_echo "I: Build completed in ${BUILD_TIME_STR}"
script_echo "   Output: $OUT_DIR/$FILE_NAME"
rm -f "$BUILD_CONFIG_DIR/$BUILD_DEVICE_TMP_CONFIG"

exit 0
