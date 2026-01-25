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
  git clone --depth=1 \
    https://github.com/qosmio/nss-packages.git
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

# 假设 openwrt feeds 有 nss_packages 目录
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
      sed -i "1i PKG_SOURCE:=nss-packages-preload.tar.gz\nPKG_HASH:=skip\n" \
        "$MK"
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
echo "==> [4/6] 精简 NSS 配置：只保留 WWAN + WiFi"
###############################################################################

CONFIG_FILE="$OPENWRT_DIR/.config"

if [ -f "$CONFIG_FILE" ]; then
  echo "==> Modifying .config to keep only WWAN + WiFi NSS modules"

  # 注释掉不需要的 NSS 模块
  sed -i \
    -e 's/^CONFIG_DEFAULT_kmod-qca-nss-drv-bridge-mgr=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_CAPWAP_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_C2C_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_CLMAP_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_CRYPTO_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_DTLS_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_GRE_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_IGS_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_IPSEC_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_L2TP_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_LAG_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_MAPT_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_MATCH_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_MIRROR_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_LSO_RX_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_PPTP_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_PVXLAN_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_QRFS_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_QVPN_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_SHAPER_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_SJACK_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_TLS_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_TRUSTSEC_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_UDP_ST_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_TUN6RD_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_TUNIPIP6_ENABLE=y/# &/' \
    -e 's/^CONFIG_NSS_DRV_VXLAN_ENABLE=y/# &/' \
    "$CONFIG_FILE"

  echo "==> NSS 精简完成，只保留 WWAN + WiFi"
else
  echo "WARNING: .config not found, skip NSS config modification"
fi

###############################################################################
echo "==> [5/6] Optional patches"
###############################################################################

# cp -r "$DIYPATH/patches" "$OPENWRT_DIR/package/feeds/nss_packages/"

###############################################################################
echo "==> [6/6] Done"
###############################################################################

echo "==> DIY script finished!"
