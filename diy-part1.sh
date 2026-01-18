#!/bin/bash
set -euo pipefail

echo "==> DIY script start"

OPENWRT_DIR="${OPENWRT_DIR:-$(pwd)}"
DIYPATH="$OPENWRT_DIR/package/diypath"
DL_DIR="$OPENWRT_DIR/dl"

mkdir -p "$DIYPATH" "$DL_DIR"

###############################################################################
echo "==> [1/6] Preload qca-nss-drv source"
###############################################################################

cd "$DL_DIR"

if [ ! -d qca-nss-drv ]; then
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    echo "==> Clone qca-nss-drv with GITHUB_TOKEN"
    git clone --depth=1 \
      https://x-access-token:${GITHUB_TOKEN}@github.com/Jim78778/qca-nss-drv.git
  else
    echo "==> Clone qca-nss-drv without token"
    git clone --depth=1 \
      https://github.com/Jim78778/qca-nss-drv.git
  fi
fi

if [ ! -f qca-nss-drv-preload.tar.gz ]; then
  tar -czf qca-nss-drv-preload.tar.gz qca-nss-drv
fi

ls -lh qca-nss-drv-preload.tar.gz

###############################################################################
echo "==> [2/6] Force qca-nss-drv use local tarball"
###############################################################################

NSS_MK="package/feeds/nss_packages/qca-nss-drv/Makefile"

if [ -f "$OPENWRT_DIR/$NSS_MK" ]; then
  sed -i \
    -e 's/^PKG_SOURCE_PROTO:=.*/# &/' \
    -e 's/^PKG_SOURCE_URL:=.*/PKG_SOURCE_URL:=file:\/\/$(DL_DIR)/' \
    -e 's/^PKG_SOURCE_VERSION:=.*/# &/' \
    "$OPENWRT_DIR/$NSS_MK"

  grep -q '^PKG_SOURCE:=' "$OPENWRT_DIR/$NSS_MK" || \
    sed -i '1i PKG_SOURCE:=qca-nss-drv-preload.tar.gz\nPKG_HASH:=skip\n' \
      "$OPENWRT_DIR/$NSS_MK"
else
  echo "WARNING: qca-nss-dr

