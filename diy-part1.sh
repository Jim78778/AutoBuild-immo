#!/bin/bash
set -e

DIYPATH="package/diypath"
OPENWRT_DIR="$(pwd)"

mkdir -p $DIYPATH

echo "=== Step 1: Add QModem ==="
# 使用 fork 的 QModem 仓库
git clone --depth=1 https://github.com/FUjr/QModem.git $DIYPATH/qmodem

#修复jq/host
sed -i '/jq\/host/d' \
  package/feeds/luci/luci-app-advanced-reboot/Makefile

# 修复 QModem Makefile 中不必要的依赖，适配 PCIe
sed -i \
  -e 's/kmod-usb-net-qmi-wwan-ctrl/kmod-mhi-wwan-ctrl/g' \
  -e 's/kmod-usb-net-qmi-wwan-mbim/kmod-mhi-wwan-mbim/g' \
  -e 's/-M//g' \
  -e 's/PACKAGE_luci-app-qmodem_USING_QWRT_QUECTEL_CM_5G://g' \
  -e 's/PACKAGE_luci-app-qmodem_USING_NORMAL_QUECTEL_CM://g' \
  $DIYPATH/qmodem/application/qmodem/Makefile

echo "=== Step 2: Add AdGuardHome ==="
# 如果 feeds 有 luci-app-adguardhome 可以跳过，否则放到 diypath
git clone --depth=1 https://github.com/rufengsuixing/luci-app-adguardhome.git $DIYPATH/adguardhome

echo "=== Step 3: Add ttyd ==="
git clone --depth=1 https://github.com/tsl0922/ttyd.git $DIYPATH/ttyd

echo "=== Step 4: Add custom themes ==="
# 举例 luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git $DIYPATH/luci-theme-argon

echo "=== Step 5: Register DIY packages in feeds.conf.default ==="
# 避免重复添加
grep -qxF "src-link diypath $DIYPATH" $OPENWRT_DIR/feeds.conf.default || \
  echo "src-link diypath $DIYPATH" >> $OPENWRT_DIR/feeds.conf.default

echo "=== Step 6: All DIY packages ready ==="
ls -l $DIYPATH


