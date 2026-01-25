#!/bin/bash
set -e

echo "==> DIY part start"

OPENWRT_DIR="${OPENWRT_DIR:-$(pwd)}"
FILES_DIR="$OPENWRT_DIR/files"
DEFAULTS_DIR="$FILES_DIR/etc/uci-defaults"

mkdir -p "$DEFAULTS_DIR"

###############################################################################
echo "==> [1] Preinstall LuCI + Chinese language"
###############################################################################

cat >> "$OPENWRT_DIR/.config" <<EOF
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-i18n-firewall-zh-cn=y
EOF

###############################################################################
echo "==> [2] LAN IP 192.168.6.1/24 + fixed LAN port order"
###############################################################################

cat > "$DEFAULTS_DIR/10-network-lan" << 'EOF'
#!/bin/sh

uci batch <<EOT
set network.lan=interface
set network.lan.device='br-lan'
set network.lan.proto='static'
set network.lan.ipaddr='192.168.6.1'
set network.lan.netmask='255.255.255.0'

set network.br_lan=device
set network.br_lan.name='br-lan'
set network.br_lan.type='bridge'
del network.br_lan.ports
add_list network.br_lan.ports='eth1'
add_list network.br_lan.ports='eth2'
EOT

uci commit network
exit 0
EOF

chmod +x "$DEFAULTS_DIR/10-network-lan"

###############################################################################
echo "==> [3] WAN DHCP default enabled"
###############################################################################

cat > "$DEFAULTS_DIR/20-network-wan" << 'EOF'
#!/bin/sh

uci batch <<EOT
set network.wan=interface
set network.wan.device='eth0'
set network.wan.proto='dhcp'
EOT

uci commit network
exit 0
EOF

chmod +x "$DEFAULTS_DIR/20-network-wan"

###############################################################################
echo "==> [4] LuCI default language: Chinese"
###############################################################################

cat > "$DEFAULTS_DIR/30-luci-lang" << 'EOF'
#!/bin/sh

uci set luci.main.lang='zh_cn'
uci commit luci
exit 0
EOF

chmod +x "$DEFAULTS_DIR/30-luci-lang"

###############################################################################
echo "==> [5] Default WiFi SSID: Swaiot_CPE (no password)"
###############################################################################

cat > "$DEFAULTS_DIR/40-wifi-default" << 'EOF'
#!/bin/sh

for dev in $(uci show wireless | grep "=wifi-device" | cut -d. -f2 | cut -d= -f1); do
    uci set wireless.$dev.disabled='0'
done

for iface in $(uci show wireless | grep "=wifi-iface" | cut -d. -f2 | cut -d= -f1); do
    uci set wireless.$iface.ssid='Swaiot_CPE'
    uci set wireless.$iface.encryption='none'
done

uci commit wireless
exit 0
EOF

chmod +x "$DEFAULTS_DIR/40-wifi-default"

###############################################################################
echo "==> DIY part done"
###############################################################################
