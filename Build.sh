#!/usr/bin/env bash
set -e

export USE_CCACHE=0
export CCACHE_DISABLE=1
export BUILD_USERNAME=builder
export BUILD_HOSTNAME=codespace

ROM_DIR="$HOME/lineage"
JOBS=2

echo "=== DISK DURUMU ==="
df -h "$HOME"

# Eski build varsa temizle
rm -rf "$ROM_DIR/out"
rm -rf "$ROM_DIR/.repo/local_manifests"

# Repo cache kullanma
export REPO_CURL_OPTS="--retry 2"

mkdir -p "$HOME/bin"

if [ ! -f "$HOME/bin/repo" ]; then
    curl -L https://storage.googleapis.com/git-repo-downloads/repo \
        -o "$HOME/bin/repo"
    chmod +x "$HOME/bin/repo"
fi

export PATH="$HOME/bin:$PATH"

mkdir -p "$ROM_DIR"
cd "$ROM_DIR"

# Android 10 / LineageOS 17.1
repo init \
    -u https://github.com/LineageOS/android.git \
    -b lineage-17.1 \
    --depth=1 \
    --no-clone-bundle \
    --no-tags

# Mümkün olduğunca az eşzamanlı indirme
repo sync \
    --force-sync \
    --no-clone-bundle \
    --no-tags \
    --optimized-fetch \
    -j2

# Device tree
mkdir -p device/xiaomi

git clone \
    --depth=1 \
    --single-branch \
    https://github.com/mahajant99/device_xiaomi_sweet.git \
    device/xiaomi/sweet

# Repo geçmişlerini temizle
find device/xiaomi/sweet -type d -name ".git" -prune -exec rm -rf {} \;

# Build
source build/envsetup.sh
lunch lineage_sweet-userdebug

# Sadece hedefi derle
mka bacon -j2

echo
echo "=== ROM ==="
find out/target/product/sweet \
    -maxdepth 1 \
    -type f \
    -name "*.zip" \
    -print

echo
echo "=== SON DISK DURUMU ==="
df -h "$HOME"
