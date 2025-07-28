#!/bin/bash

# Simple VPN management menu for xray-core with tun2socks
# This script installs xray, allows a custom config, and toggles routing.

GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

# Enable or disable clearing the screen between menu refreshes
CLEAR_SCREEN=1

CONFIG_DIR="/usr/local/etc/xray"
CONFIG_PATH="$CONFIG_DIR/config.json"
RULE_COMMENT="VPN_MENU_RULE"
TUN_PORT=1090

log_msg() {
    local level=$1
    shift
    local color
    case $level in
        INFO) color=$BLUE ;;
        SUCCESS) color=$GREEN ;;
        ERROR) color=$RED ;;
        *) color=$NC ;;
    esac
    echo -e "${color}[$level]${NC} $*"
}

status_circle() {
    if iptables -t nat -C OUTPUT -m comment --comment "$RULE_COMMENT" -j REDIRECT --to-ports "$TUN_PORT"; then
        echo -e "${GREEN}●${NC}"
    else
        echo -e "${RED}●${NC}"
    fi
}

install_xray() {
    log_msg INFO "Installing xray-core..."
    url=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest \
        | grep browser_download_url \
        | grep 'Xray-linux-64\.zip' \
        | head -n 1 \
        | cut -d '"' -f 4)
    if [ -z "$url" ]; then
        log_msg ERROR "Could not determine download URL."
        return 1
    fi
    tmpdir=$(mktemp -d)
    if output=$(curl -L "$url" -o "$tmpdir/xray.zip" 2>&1 && \
        unzip -q "$tmpdir/xray.zip" -d "$tmpdir" 2>&1 && \
        sudo install -m 755 "$tmpdir/xray" /usr/local/bin/xray 2>&1); then
        rm -rf "$tmpdir"
        log_msg SUCCESS "xray-core installed to /usr/local/bin/xray"
    else
        rm -rf "$tmpdir"
        log_msg ERROR "Installation failed: $output"
        return 1
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
    log_msg INFO "Activating VPN..."
    if output=$(sudo systemctl start xray 2>&1); then
        log_msg SUCCESS "xray service started"
    else
        if output=$(sudo xray -config "$CONFIG_PATH" 2>&1 &); then
            log_msg SUCCESS "xray started"
        else
            log_msg ERROR "Failed to start xray: $output"
            return 1
        fi
    fi

    if sudo iptables -t nat -C OUTPUT -m comment --comment "$RULE_COMMENT" -j REDIRECT --to-ports "$TUN_PORT" 2>&1; then
        log_msg INFO "iptables rule already exists"
    else
        if output=$(sudo iptables -t nat -A OUTPUT -p tcp -m comment --comment "$RULE_COMMENT" -j REDIRECT --to-ports "$TUN_PORT" 2>&1); then
            log_msg SUCCESS "iptables rule added"
        else
            log_msg ERROR "Failed to add iptables rule: $output"
            return 1
        fi
    fi
}

deactivate_vpn() {
    log_msg INFO "Deactivating VPN..."
    if output=$(sudo iptables -t nat -D OUTPUT -p tcp -m comment --comment "$RULE_COMMENT" -j REDIRECT --to-ports "$TUN_PORT" 2>&1); then
        log_msg SUCCESS "iptables rule removed"
    else
        log_msg ERROR "Failed to remove iptables rule: $output"
    fi

    if output=$(sudo systemctl stop xray 2>&1); then
        log_msg SUCCESS "xray service stopped"
    else
        if output=$(sudo pkill -f "xray -config" 2>&1); then
            log_msg SUCCESS "xray process stopped"
        else
            log_msg ERROR "Failed to stop xray: $output"
            return 1
        fi
    fi
}

test_ip() {
    echo "Testing IP via ipinfo.io:"
    curl -s ipinfo.io
}

toggle_clear() {
    if [ "$CLEAR_SCREEN" -eq 1 ]; then
        CLEAR_SCREEN=0
        log_msg INFO "Screen clearing disabled"
    else
        CLEAR_SCREEN=1
        log_msg INFO "Screen clearing enabled"
    fi
}

show_logs() {
    log_msg INFO "Displaying xray logs..."
    if [ -d /var/log/xray ]; then
        sudo tail -n 20 /var/log/xray/* 2>/dev/null
    else
        sudo journalctl -u xray -n 20 --no-pager
    fi
}

menu() {
    while true; do
        if [ "$CLEAR_SCREEN" -eq 1 ]; then
            clear
        fi
        echo "-----------------------------"
        echo "-         VPN Menu         -"
        echo "-----------------------------"
        echo -n "VPN status: $(status_circle) "
        echo ""
        echo "1) Install xray-core"
        echo "2) Provide custom config"
        echo "3) Activate routing"
        echo "4) Deactivate routing"
        echo "5) Test IP address"
        echo "6) Toggle screen clearing"
        echo "7) View logs"
        echo "0) Exit"
        read -rp "Choice: " choice
        case $choice in
            1) install_xray ;;
            2) set_config ;;
            3) activate_vpn ;;
            4) deactivate_vpn ;;
            5) test_ip ;;
            6) toggle_clear ;;
            7) show_logs ;;
            0) exit 0 ;;
            *) echo "Invalid option" ;;
        esac
    done
}

menu
