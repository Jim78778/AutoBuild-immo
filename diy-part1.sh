#!/bin/bash
# diy-part1.sh — 在 openwrt 构建前准备

# 假设 OPENWRT_DIR 已经定义
OPENWRT_DIR="${OPENWRT_DIR:-$PWD/openwrt}"

echo "== Copying custom packages =="

# 创建 diypath 目录
mkdir -p "$OPENWRT_DIR/package/diypath"

# 假设 QModem 仓库在仓库子目录 custom-feed/qmodem
# 如果你是用 git clone 拉取，可以用下面方式：
if [ ! -d "$OPENWRT_DIR/package/diypath/qmodem" ]; then
    echo "Cloning QModem into diypath..."
    git clone --depth=1 -b main https://github.com/FUjr/QModem.git "$OPENWRT_DIR/package/diypath/qmodem"
fi

# 修正 QModem Makefile 依赖
echo "Fixing QModem Makefile dependencies..."
sed -i \
  -e 's/kmod-mhi-wwan/kmod-usb-net-qmi-wwan/g' \
  -e 's/quectel-CM-5G//g' \
  -e 's/quectel-cm//g' \
  "$OPENWRT_DIR/package/diypath/qmodem/Makefile"

# 可选：在 feeds 安装后，确保 diypath 被包含
echo "Configuring .config for QModem..."
cd "$OPENWRT_DIR"
# 如果 ci.config 已经包含 QModem，可以直接 make defconfig
make defconfig
