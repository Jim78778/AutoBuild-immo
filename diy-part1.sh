#!/bin/bash
set -euo pipefail

echo "==> DIY script start"

# ------------------------------------------------------------------
# 基础路径定义（显式、可预测）
# ------------------------------------------------------------------
OPENWRT_DIR="${OPENWRT_DIR:-$(pwd)}"
DIYPATH="$OPENWRT_DIR/package/diypath"

mkdir -p "$DIYPATH"

# ------------------------------------------------------------------
echo "==> [1/4] Add QModem"
# ------------------------------------------------------------------

cd "$DIYPATH"

if [ ! -d qmodem ]; then
  git clone --depth=1 https://github.com/FUjr/QModem.git qmodem
fi

QMODEM_MK="$DIYPATH/qmodem/application/qmodem/Makefile"

if [ -f "$QMODEM_MK" ]; then
  sed -i \
    -e 's/kmod-usb-net-qmi-wwan-ctrl/kmod-mhi-wwan-ctrl/g' \
    -e 's/kmod-usb-net-qmi-wwan-mbim/kmod-mhi-wwan-mbim/g' \
    -e 's/-M//g' \
    -e 's/PACKAGE_luci-app-qmodem_USING_QWRT_QUECTEL_CM_5G://g' \
    -e 's/PACKAGE_luci-app-qmodem_USING_NORMAL_QUECTEL_CM://g' \
    "$QMODEM_MK"
else
  echo "WARNING: QModem Makefile not found, skip patch"
fi

# ------------------------------------------------------------------
echo "==> [2/4] Fix luci-app-advanced-reboot (safe guard)"
# ------------------------------------------------------------------

ADV_REBOOT_MK="$OPENWRT_DIR/package/feeds/luci/luci-app-advanced-reboot/Makefile"

if [ -f "$ADV_REBOOT_MK" ]; then
  sed -i '/jq\/host/d' "$ADV_REBOOT_MK"
else
  echo "INFO: luci-app-advanced-reboot not present, skip"
fi

# ------------------------------------------------------------------
echo "==> [3/4] Add extra packages"
# ------------------------------------------------------------------

cd "$DIYPATH"

[ -d adguardhome ] || \
  git clone --depth=1 https://github.com/rufengsuixing/luci-app-adguardhome.git adguardhome

[ -d ttyd ] || \
  git clone --depth=1 https://github.com/tsl0922/ttyd.git ttyd

[ -d luci-theme-argon ] || \
  git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git luci-theme-argon

# ------------------------------------------------------------------
echo "==> [4/4] Register diypath feed (idempotent)"
# ------------------------------------------------------------------

FEEDS_CONF="$OPENWRT_DIR/feeds.conf.default"

if ! grep -qxF "src-link diypath $DIYPATH" "$FEEDS_CONF"; then
  echo "src-link diypath $DIYPATH" >> "$FEEDS_CONF"
fi

ls -l "$DIYPATH"

echo "==> DIY script done"
