# VPN Menu Script

This repository provides a simple Bash menu for managing outbound
traffic through **xray-core** using a tun2socks approach. The script can
install xray, accept a custom V2Ray configuration, activate or deactivate
routing rules, and test the VPS IP address.

## Installation

```bash
curl -L https://github.com/iyf577ge6/tun/archive/refs/heads/main.zip -o tun.zip
unzip tun.zip
cd tun-main
```

## Usage

1. Make the script executable:

   ```bash
   chmod +x vpn_menu.sh
   ```

2. Run the menu as root (required for network changes):

   ```bash
   sudo ./vpn_menu.sh
   ```

3. Follow the on-screen menu to install xray, provide your configuration,
   activate or deactivate routing, test your external IP, view recent xray
   logs, or toggle screen clearing if you want to keep previous output visible.

The menu displays a colored status indicator: **green** when the
VPN rules are active and **red** when they are not.

## Checking Logs

Select "View logs" from the menu to display the last 20 lines from the xray
service. The script will try to read `/var/log/xray/` if it exists, otherwise it
falls back to `journalctl`:

```bash
sudo journalctl -u xray -n 20 --no-pager
```
