#!/bin/bash

# Simple VPN management menu for xray-core with tun2socks
# This script installs xray, allows a custom config, and toggles routing.

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"

CONFIG_DIR="/usr/local/etc/xray"
CONFIG_PATH="$CONFIG_DIR/config.json"
RULE_COMMENT="VPN_MENU_RULE"
TUN_PORT=1090

status_circle() {
    if iptables -t nat -C OUTPUT -m comment --comment "$RULE_COMMENT" -j REDIRECT --to-ports "$TUN_PORT" 2>/dev/null; then
        echo -e "${GREEN}●${NC}"
    else
        echo -e "${RED}●${NC}"
    fi
}

install_xray() {
    echo -e "${GREEN}Installing xray-core...${NC}"
    if command -v apt-get >/dev/null; then
        sudo apt-get update && sudo apt-get install -y xray-core
    else
        echo "Unsupported package manager. Install xray manually."
    fi
}

set_config() {
    read -rp "Enter path to your V2Ray config: " path
    if [ -f "$path" ]; then
        sudo mkdir -p "$CONFIG_DIR"
        sudo install -m 600 "$path" "$CONFIG_PATH"
        echo "Config copied to $CONFIG_PATH"
    else
        echo "File not found: $path"
    fi
}

activate_vpn() {
    echo -e "${GREEN}Activating VPN...${NC}"
    sudo systemctl start xray >/dev/null 2>&1 || sudo xray -config "$CONFIG_PATH" &
    sudo iptables -t nat -C OUTPUT -m comment --comment "$RULE_COMMENT" -j REDIRECT --to-ports "$TUN_PORT" 2>/dev/null || \
    sudo iptables -t nat -A OUTPUT -p tcp -m comment --comment "$RULE_COMMENT" -j REDIRECT --to-ports "$TUN_PORT"
}

deactivate_vpn() {
    echo -e "${RED}Deactivating VPN...${NC}"
    sudo iptables -t nat -D OUTPUT -p tcp -m comment --comment "$RULE_COMMENT" -j REDIRECT --to-ports "$TUN_PORT" 2>/dev/null
    sudo systemctl stop xray >/dev/null 2>&1 || sudo pkill -f "xray -config" >/dev/null 2>&1
}

test_ip() {
    echo "Testing IP via ipinfo.io:"
    curl -s ipinfo.io
}

menu() {
    while true; do
        echo
        echo -n "VPN status: $(status_circle) "
        echo ""
        echo "1) Install xray-core"
        echo "2) Provide custom config"
        echo "3) Activate routing"
        echo "4) Deactivate routing"
        echo "5) Test IP address"
        echo "0) Exit"
        read -rp "Choice: " choice
        case $choice in
            1) install_xray ;;
            2) set_config ;;
            3) activate_vpn ;;
            4) deactivate_vpn ;;
            5) test_ip ;;
            0) exit 0 ;;
            *) echo "Invalid option" ;;
        esac
    done
}

menu
