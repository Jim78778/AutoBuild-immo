#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
#./scripts/feeds update -a && rm -rf feeds/luci/applications/luci-app-mosdns && rm -rf feeds/packages/net/{alist,adguardhome,mosdns,smartdns}
#rm -rf feeds/packages/lang/golang
#git clone https://github.com/kenzok8/golang feeds/packages/lang/golang

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
#echo 'src-git qmodem https://github.com/FUjr/QModem.git;main' >> feeds.conf.default
#./scripts/feeds update qmodem
#./scripts/feeds install -a -p qmodem
#echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default
# 跳过 mx4200 DTS，避免 patch 失败
sed -i '/ipq8174-mx4200.dtsi/d' \
#target/linux/qualcommax/patches-6.6/*.patch
