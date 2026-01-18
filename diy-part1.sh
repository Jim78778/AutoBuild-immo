#!/bin/bash
set -euo pipefail

echo "==> DIY script start"

# -----------------------------
# Variables
# -----------------------------
OPENWRT_DIR="${OPENWRT_DIR:-$(pwd)}"
DIYPATH="$OPENWRT_DIR/package/diypath"
DL_DIR="$OPENWRT_DIR/dl"

mkdir -p "$DIYPATH" "$DL_DIR"

###############################################################################
echo "==> [1/6] Preload qca-nss-drv source"
###############################################################################

cd "$DL_DIR"

# 强制使用 GITHUB_TOKEN，否则直接报错，避免 CI 128 错
if [ ! -d qca-nss-drv ]; then
  if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "ERROR: GITHUB_TOKEN not set. Cannot clone qca-nss-drv in CI."
    exit 1
  fi
  echo "==> Clone qca-nss-drv with GITHUB_TOKEN"
  git clone --depth=1 \
    "https://x-access-token:${GITHUB_TOKEN}@github.com/Jim78778/qca-nss-drv.git"
else
  echo "==> qca-nss-drv already exists, skipping clone"
fi

# 打包 tarball
if [ ! -f qca-nss-drv-preload.tar.gz ]; then
  echo "==> Creating tarball qca-nss-drv-preload.tar.gz"
  tar -czf qca-nss-drv-preload.tar.gz qca-nss-drv
else
  echo "==> Tarball qca-nss-drv-preload.tar.gz already exists"
fi

ls -lh qca-nss-drv-preload.tar.gz

###############################################################################
echo "==> [2/6] Force qca-nss-drv use local tarball"
###############################################################################

NSS_MK="package/feeds/nss_packages/qca-nss-drv/Makefile"

if [ -f "$OPENWRT_DIR/$NSS_MK" ]; then
  echo "==> Patching Makefile to use local tarball"
  sed -i \
    -e 's/^PKG_SOURCE_PROTO:=.*/# &/' \
    -e "s|^PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=file://$DL_DIR|" \
    -e 's/^PKG_SOURCE_VERSION:=.*/# &/' \
    "$OPENWRT_DIR/$NSS_MK"

  grep -q '^PKG_SOURCE:=' "$OPENWRT_DIR/$NSS_MK" || \
    sed -i "1i PKG_SOURCE:=qca-nss-drv-preload.tar.gz\nPKG_HASH:=skip\n" \
      "$OPENWRT_DIR/$NSS_MK"
else
  echo "WARNING: $NSS_MK not found, cannot patch qca-nss-drv Makefile"
fi

###############################################################################
echo "==> [3/6] Ensure DIYPATH is linked"
###############################################################################

ln -snf "$DL_DIR/qca-nss-drv" "$DIYPATH/qca-nss-drv"
echo "==> DIYPATH link created: $DIYPATH/qca-nss-drv -> $DL_DIR/qca-nss-drv"

###############################################################################
echo "==> [4/6] Optional: Clean previous build"
###############################################################################

# 可选清理
# echo "==> Cleaning previous qca-nss-drv build"
# make -C "$OPENWRT_DIR" package/qca-nss-drv/clean

###############################################################################
echo "==> [5/6] Optional: Apply custom patches"
###############################################################################

# 可选 patch 插槽
# echo "==> Applying custom patches"
# cp -r "$DIYPATH/patches/"* "$OPENWRT_DIR/package/feeds/nss_packages/qca-nss-drv/"

###############################################################################
echo "==> [6/6] Done"
###############################################################################

echo "==> DIY script finished successfully!"
