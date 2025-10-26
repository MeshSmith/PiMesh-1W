# PiMesh-1W Interactive Installer

A beautiful, interactive installer for setting up Meshtastic on Raspberry Pi with PiMesh-1W hardware configuration.

## 🚀 Quick Installation

Install your PiMesh-1W node with a single command:

```bash
curl -sSL https://install.meshsmith.net | bash
```

## ✨ Features

- **🎯 One-Command Installation**: Simple curl command gets you started
- **🖥️ Interactive TUI**: Beautiful terminal interface with colored output and ASCII art
- **🔍 Smart Detection**: Automatically detects Pi model and OS version
- **⚙️ Hardware Configuration**: Pre-configured for PiMesh-1W (E22-900M30S) LoRa module
- **🌐 Web Interface**: Enables HTTPS web interface for easy management
- **🔧 Complete Setup**: Configures GPIO, services, and network discovery
- **📱 Multi-Platform**: Supports Pi 3/4/5 on both 32-bit and 64-bit OS

## 🛠️ What Gets Installed

### Core Components
- **Meshtastic Daemon** (`meshtasticd`) - Latest beta version
- **Avahi Daemon** - For network discovery
- **Web Interface** - HTTPS access on port 443

### Hardware Configuration
- **SPI Interface** - Enabled for LoRa communication
- **I2C Interface** - Enabled for sensors and displays  
- **UART** - Enabled for serial communication
- **PiMesh-1W Preset** - E22-900M30S module configuration

### GPIO Pin Configuration
```yaml
# PiMesh-1W (E22-900M30S) Configuration
Lora:
  Module: sx1262
  CS: 21        # Chip Select
  IRQ: 16       # Interrupt Request
  Busy: 20      # Busy Signal
  Reset: 18     # Reset Pin
  TXen: 13      # TX Enable
  RXen: 12      # RX Enable
  DIO3_TCXO_VOLTAGE: true
```

## 🎛️ Installation Options

### 1. Full Installation (Recommended)
Complete setup with all components:
- Meshtastic daemon installation
- PiMesh-1W hardware configuration
- Web interface setup
- Auto-start service configuration

### 2. Custom Installation
*Coming soon* - Choose specific components and advanced options

### 3. System Information
View detailed information about your Raspberry Pi:
- Pi model detection
- OS version and architecture
- Compatibility status
- System resources

## 📋 Requirements

### Supported Hardware
- Raspberry Pi 3 Model B/B+
- Raspberry Pi 4 Model B
- Raspberry Pi 5
- Raspberry Pi Zero 2 W

### Supported Operating Systems
- Raspberry Pi OS Bookworm (32-bit & 64-bit)
- Raspberry Pi OS Trixie (32-bit & 64-bit)

### System Requirements
- Internet connection for package downloads
- At least 100MB free disk space
- User account with sudo privileges
- **Not running as root** (security best practice)

## 🔧 Manual Installation

If you prefer to download and inspect the script first:

```bash
# Download the installer
curl -sSL https://install.meshsmith.net -o install.sh

# Make it executable
chmod +x install.sh

# Run the installer
./install.sh
```

## 📖 Usage After Installation

### Access Web Interface
```bash
# Find your Pi's IP address
hostname -I

# Access web interface at:
https://YOUR_PI_IP_ADDRESS
```

### Service Management
```bash
# Check service status
sudo systemctl status meshtasticd

# View live logs
sudo journalctl -u meshtasticd -f

# Restart service
sudo systemctl restart meshtasticd

# Stop service
sudo systemctl stop meshtasticd

# Start service
sudo systemctl start meshtasticd
```

### Configuration Files
- **Main Config**: `/etc/meshtasticd/config.yaml`
- **Hardware Preset**: `/etc/meshtasticd/config.d/pimesh-1w.yaml`
- **Available Presets**: `/etc/meshtasticd/available.d/`

## 🔍 Troubleshooting

### Service Won't Start
If Meshtastic daemon fails to start after installation:

1. **Reboot Required**: GPIO changes require a reboot
   ```bash
   sudo reboot
   ```

2. **Check GPIO Configuration**: Verify `/boot/firmware/config.txt` contains:
   ```
   dtparam=spi=on
   dtoverlay=spi0-0cs
   dtparam=i2c_arm=on
   enable_uart=1
   ```

3. **Hardware Check**: Ensure PiMesh-1W board is properly connected

### Permission Issues
If you get permission errors:
```bash
# Make sure you're not running as root
whoami

# Check sudo access
sudo -l
```

### Network Discovery
If your Pi isn't discoverable on the network:
```bash
# Check Avahi service
sudo systemctl status avahi-daemon

# Restart Avahi
sudo systemctl restart avahi-daemon
```

## 🛡️ Security Features

- **Non-root Installation**: Script refuses to run as root
- **HTTPS Web Interface**: Secure web access
- **Service Isolation**: Services run with minimal privileges
- **Firewall Friendly**: Uses standard ports (443, 4403)

## 📝 Installation Log

The installer creates a detailed log at `/tmp/pimesh_install.log` for troubleshooting.

## 🤝 Support & Community

- **Documentation**: [https://meshsmith.net](https://meshsmith.net)
- **Issues & Support**: [GitHub Issues](https://github.com/MeshSmith/PiMesh-1W-Docs/issues)
- **Community**: Join our Meshtastic community discussions

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🔄 Updates

The installer always fetches the latest version. To update your installation, simply run the installer again:

```bash
curl -sSL https://install.meshsmith.net | bash
```

---

**Made with ❤️ by the MeshSmith community**