# VPN Menu Script

This repository provides a simple Bash menu for managing outbound
traffic through **xray-core** using a tun2socks approach. The script can
install xray, accept a custom V2Ray configuration, activate or deactivate
routing rules, and test the VPS IP address.

## Installation

```bash
sudo apt-get update -y && sudo apt-get upgrade -y
git clone https://github.com/yourusername/tun.git
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
   activate or deactivate routing, and test your external IP.

The menu displays a colored status indicator: **green** when the
VPN rules are active and **red** when they are not.
