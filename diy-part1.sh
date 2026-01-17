#!/bin/bash
set -e

DIYPATH="package/diypath"
OPENWRT_DIR="$(pwd)"

mkdir -p $DIYPATH

echo "=== Step 1: Add QModem ==="
# 使用你 fork 的 QModem 仓库
git clone --depth=1 https://github.com/FUjr/QModem.git $DIYPATH/qmodem

# 修复 QModem Makefile 中不必要的依赖
sed -i \
  -e 's/kmod-mhi-wwan/kmod-usb-net-qmi-wwan/g' \
  -e 's/quectel-CM-5G//g' \
  -e 's/quectel-cm//g' \
  $DIYPATH/qmodem/application/qmodem/Makefile

echo "=== Step 2: Add AdGuardHome ==="
# 直接从官方 feeds 拉 luci-app-adguardhome
# 如果 feeds 没有，需要你自行放入 diypath/adguardhome
git clone --depth=1 https://github.com/rufengsuixing/luci-app-adguardhome.git $DIYPATH/adguardhome

echo "=== Step 3: Add ttyd ==="
git clone --depth=1 https://github.com/tsl0922/ttyd.git $DIYPATH/ttyd

echo "=== Step 4: Add custom themes ==="
# 举例添加 luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git $DIYPATH/luci-theme-argon

echo "=== Step 5: Fix dependencies ==="
# 强制安装 QModem 依赖包
cat >> $OPENWRT_DIR/feeds.conf.default <<EOL
src-git qmodem https://github.com/FUjr/QModem.git;main
EOL

# 如果需要，可以在这里自动添加 QModem 的 Build/Host deps
# sed 或 echo 修改 Makefile 或依赖的 kmod

echo "=== Step 6: All DIY packages ready ==="
ls -l $DIYPATH

