#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Redmi Note 10 Pro (sweet) - Android 10 / LineageOS 17.1
# GitHub Actions build script
# ============================================================

export TZ=Europe/Istanbul
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
export BUILD_USERNAME=builder
export BUILD_HOSTNAME=github-actions

ROM_DIR="$HOME/lineage"
JOBS="$(nproc)"

echo "=============================================="
echo " Redmi Note 10 Pro (sweet)"
echo " Android 10 / LineageOS 17.1"
echo " Build started"
echo "=============================================="

# ------------------------------------------------------------
# 1. Paketler
# ------------------------------------------------------------

sudo apt-get update

sudo apt-get install -y \
    adb autoconf automake bc bison build-essential \
    ccache curl flex g++-multilib gcc-multilib git \
    gnupg gperf imagemagick lib32ncurses5-dev \
    lib32readline-dev lib32z1-dev liblz4-tool \
    libncurses5 libncurses5-dev libsdl1.2-dev \
    libssl-dev libxml2-utils lzop pngcrush \
    rsync schedtool squashfs-tools unzip \
    xsltproc zip zlib1g-dev python3

# ------------------------------------------------------------
# 2. Repo
# ------------------------------------------------------------

mkdir -p "$HOME/bin"

if [ ! -x "$HOME/bin/repo" ]; then
    curl -L https://storage.googleapis.com/git-repo-downloads/repo \
        -o "$HOME/bin/repo"

    chmod +x "$HOME/bin/repo"
fi

export PATH="$HOME/bin:$PATH"

# ------------------------------------------------------------
# 3. Kaynak dizini
# ------------------------------------------------------------

rm -rf "$ROM_DIR"
mkdir -p "$ROM_DIR"

cd "$ROM_DIR"

# ------------------------------------------------------------
# 4. LineageOS 17.1
# ------------------------------------------------------------

repo init \
    -u https://github.com/LineageOS/android.git \
    -b lineage-17.1 \
    --depth=1

# ------------------------------------------------------------
# 5. Kaynakları indir
# ------------------------------------------------------------

repo sync \
    --force-sync \
    --no-clone-bundle \
    --no-tags \
    --optimized-fetch \
    -j"$JOBS"

# ------------------------------------------------------------
# 6. Sweet device tree / kernel / vendor
# ------------------------------------------------------------
#
# BURADAKİ REPO URL'LERİNİ kendi doğruladığın Android 10
# kaynaklarıyla değiştirmen gerekebilir.
#

mkdir -p device/xiaomi
mkdir -p kernel/xiaomi
mkdir -p vendor/xiaomi

git clone \
    --depth=1 \
    https://github.com/mahajant99/device_xiaomi_sweet.git \
    device/xiaomi/sweet

# Kernel repo:
git clone \
    --depth=1 \
    https://github.com/LineageOS/android_kernel_xiaomi_sm6150.git \
    kernel/xiaomi/sm6150

# Vendor repo:
git clone \
    --depth=1 \
    https://github.com/TheMuppets/proprietary_vendor_xiaomi_sweet.git \
    vendor/xiaomi/sweet

# ------------------------------------------------------------
# 7. Cihaz yapılandırması
# ------------------------------------------------------------

source build/envsetup.sh

lunch lineage_sweet-userdebug

# ------------------------------------------------------------
# 8. CCache
# ------------------------------------------------------------

ccache -M 20G || true

# ------------------------------------------------------------
# 9. Build
# ------------------------------------------------------------

echo "=============================================="
echo " BUILDING..."
echo " Jobs: $JOBS"
echo "=============================================="

mka bacon

# ------------------------------------------------------------
# 10. Çıktı
# ------------------------------------------------------------

echo
echo "=============================================="
echo " BUILD FINISHED"
echo "=============================================="

find "$ROM_DIR/out/target/product/sweet" \
    -maxdepth 1 \
    -type f \
    \( -name "*.zip" -o -name "*.img" \) \
    -print
