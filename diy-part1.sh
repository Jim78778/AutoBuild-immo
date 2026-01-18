#!/bin/bash
set -euo pipefail

echo "==> DIY script start"

OPENWRT_DIR="${OPENWRT_DIR:-$(pwd)}"
DIYPATH="$OPENWRT_DIR/package/diypath"
DL_DIR="$OPENWRT_DIR/dl"

mkdir -p "$DIYPATH" "$DL_DIR"

###############################################################################
echo "==> [1/6] Preload NSS Packages source"
###############################################################################

cd "$DL_DIR"

if [ ! -d nss-packages ]; then
  echo "==> Clone qosmio/nss-packages (public)"
  git clone --depth=1 https://github.com/qosmio/nss-packages.git
else
  echo "==> nss-packages already exists"
fi

if [ ! -f nss-packages-preload.tar.gz ]; then
  echo "==> Creating tarball nss-packages-preload.tar.gz"
  tar -czf nss-packages-preload.tar.gz nss-packages
else
  echo "==> Tarball already exists"
fi

ls -lh nss-packages-preload.tar.gz

###############################################################################
echo "==> [2/6] Force OpenWrt NSS feed use local tarball"
###############################################################################

NSS_FEED="package/feeds/nss_packages"

if [ -d "$OPENWRT_DIR/$NSS_FEED" ]; then
  echo "==> Patching nss_packages Makefiles"
  find "$OPENWRT_DIR/$NSS_FEED" -name 'Makefile*' -print0 | while IFS= read -r -d '' MK; do
    sed -i \
      -e 's/^PKG_SOURCE_PROTO:=.*/# &/' \
      -e "s|^PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=file://$DL_DIR|" \
      -e 's/^PKG_SOURCE_VERSION:=.*/# &/' \
      "$MK"

    grep -q '^PKG_SOURCE:=' "$MK" || \
      sed -i "1i PKG_SOURCE:=nss-packages-preload.tar.gz\nPKG_HASH:=skip\n" "$MK"
  done
else
  echo "WARNING: NSS feed dir not found"
fi

###############################################################################
echo "==> [3/6] DIYPATH link"
###############################################################################

ln -snf "$DL_DIR/nss-packages" "$DIYPATH/nss-packages"
echo "==> DIYPATH created: $DIYPATH/nss-packages -> $DL_DIR/nss-packages"

###############################################################################
echo "==> [4/6] Optional clean"
###############################################################################

# make -C "$OPENWRT_DIR" package/nss_packages clean

###############################################################################
echo "==> [5/6] Optional patches"
###############################################################################

# cp -r "$DIYPATH/patches" "$OPENWRT_DIR/package/feeds/nss_packages/"

###############################################################################
echo "==> [6/6] Done"
###############################################################################

echo "==> DIY script finished!"
