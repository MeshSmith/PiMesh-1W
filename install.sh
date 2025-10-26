#!/bin/bash
#
# PiMesh-1W Interactive Installer
# https://meshsmith.net
#
# Usage: curl -sSL https://install.meshsmith.net | bash
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_NAME="PiMesh-1W Installer"
VERSION="1.0.0"
LOG_FILE="/tmp/pimesh_install.log"

# System detection variables
PI_MODEL=""
OS_VERSION=""
ARCH=""
IS_SUPPORTED=false

#######################################
# Print colored output
# Arguments:
#   $1: Color code
#   $2: Message
#######################################
print_color() {
    echo -e "${1}${2}${NC}"
}

#######################################
# Print header with ASCII art
#######################################
print_header() {
    clear
    print_color "$CYAN" "
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║  ██████╗ ██╗███╗   ███╗███████╗███████╗██╗  ██╗             ║
║  ██╔══██╗██║████╗ ████║██╔════╝██╔════╝██║  ██║             ║
║  ██████╔╝██║██╔████╔██║█████╗  ███████╗███████║             ║
║  ██╔═══╝ ██║██║╚██╔╝██║██╔══╝  ╚════██║██╔══██║             ║
║  ██║     ██║██║ ╚═╝ ██║███████╗███████║██║  ██║             ║
║  ╚═╝     ╚═╝╚═╝     ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝             ║
║                                                              ║
║        Interactive Meshtastic Installer v${VERSION}           ║
║                   https://meshsmith.net                      ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"
    echo
}

#######################################
# Debug message
#######################################
debug() {
    if [[ "${DEBUG:-}" == "1" ]]; then
        print_color "$CYAN" "🔍 DEBUG: $1"
    fi
    log "DEBUG: $1"
}

#######################################
# Log function
#######################################
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

#######################################
# Error handling
#######################################
error_exit() {
    print_color "$RED" "❌ Error: $1"
    log "ERROR: $1"
    exit 1
}

#######################################
# Success message
#######################################
success() {
    print_color "$GREEN" "✅ $1"
    log "SUCCESS: $1"
}

#######################################
# Warning message
#######################################
warning() {
    print_color "$YELLOW" "⚠️  $1"
    log "WARNING: $1"
}

#######################################
# Info message
#######################################
info() {
    print_color "$BLUE" "ℹ️  $1"
    log "INFO: $1"
}

#######################################
# Detect Raspberry Pi model
#######################################
detect_pi_model() {
    info "Detecting Raspberry Pi model..."
    
    if [[ ! -f /proc/cpuinfo ]]; then
        error_exit "This doesn't appear to be a Raspberry Pi"
    fi
    
    local revision=$(grep "Revision" /proc/cpuinfo | cut -d' ' -f2 | tr -d '\n')
    
    case "$revision" in
        a02082|a22082|a32082|a52082)
            PI_MODEL="Pi 3 Model B"
            ;;
        a020d3|9020e0)
            PI_MODEL="Pi 3 Model B+"
            ;;
        a03111|b03111|b03112|b03114|c03111|c03112|c03114|d03114)
            PI_MODEL="Pi 4 Model B"
            ;;
        b03140|c03140|d03140)
            PI_MODEL="Pi Zero 2 W"
            ;;
        c04170|d04170)
            PI_MODEL="Pi 5"
            ;;
        *)
            warning "Unknown Pi model (revision: $revision)"
            PI_MODEL="Unknown"
            ;;
    esac
    
    success "Detected: $PI_MODEL"
}

#######################################
# Detect OS version
#######################################
detect_os() {
    info "Detecting operating system..."
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_VERSION="$VERSION_CODENAME"
        ARCH=$(dpkg --print-architecture)
        
        case "$OS_VERSION" in
            bookworm|trixie)
                IS_SUPPORTED=true
                ;;
            *)
                IS_SUPPORTED=false
                ;;
        esac
        
        success "OS: $PRETTY_NAME ($ARCH)"
        
        if [[ "$IS_SUPPORTED" == true ]]; then
            success "OS version is supported"
        else
            error_exit "Unsupported OS version. This installer requires Raspberry Pi OS Bookworm or Trixie."
        fi
    else
        error_exit "Cannot detect OS version"
    fi
}

#######################################
# Check if running as root
#######################################
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error_exit "This script should not be run as root. Please run as a regular user with sudo privileges."
    fi
    
    # Check if user has sudo privileges
    if ! sudo -n true 2>/dev/null; then
        error_exit "This script requires sudo privileges. Please run with a user that has sudo access."
    fi
}

#######################################
# System requirements check
#######################################
check_requirements() {
    info "Checking system requirements..."
    
    # Check available disk space (need at least 100MB)
    local available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 102400 ]]; then
        error_exit "Insufficient disk space. At least 100MB required."
    fi
    
    # Check if we have internet connectivity
    if ! curl -s --max-time 10 https://download.opensuse.org > /dev/null; then
        error_exit "No internet connection detected. Please check your network and try again."
    fi
    
    success "System requirements met"
}

#######################################
# Interactive menu system
#######################################
show_menu() {
    print_color "$PURPLE" "┌─────────────────────────────────────────────────────────────┐"
    print_color "$PURPLE" "│                    Installation Options                    │"
    print_color "$PURPLE" "├─────────────────────────────────────────────────────────────┤"
    print_color "$PURPLE" "│                                                             │"
    print_color "$PURPLE" "│  1) 🚀 Full Installation (Recommended)                     │"
    print_color "$PURPLE" "│     • Install Meshtastic daemon                            │"
    print_color "$PURPLE" "│     • Configure PiMesh-1W hardware                         │"
    print_color "$PURPLE" "│     • Enable web interface                                 │"
    print_color "$PURPLE" "│     • Setup auto-start services                            │"
    print_color "$PURPLE" "│                                                             │"
    print_color "$PURPLE" "│  2) ⚙️  Custom Installation                                 │"
    print_color "$PURPLE" "│     • Choose specific components                            │"
    print_color "$PURPLE" "│     • Advanced configuration options                       │"
    print_color "$PURPLE" "│                                                             │"
    print_color "$PURPLE" "│  3) ℹ️  Show System Information                             │"
    print_color "$PURPLE" "│                                                             │"
    print_color "$PURPLE" "│  4) ❌ Exit                                                 │"
    print_color "$PURPLE" "│                                                             │"
    print_color "$PURPLE" "└─────────────────────────────────────────────────────────────┘"
    echo
}

#######################################
# Get user choice
#######################################
get_user_choice() {
    debug "Entering get_user_choice function"
    debug "Terminal test: $(tty 2>/dev/null || echo 'not a tty')"
    debug "Interactive test: $([[ -t 0 ]] && echo 'interactive' || echo 'non-interactive')"
    
    while true; do
        debug "Starting input loop iteration"
        
        # Ensure we're reading from the correct stdin
        if [[ -t 0 ]]; then
            # Interactive terminal
            debug "Reading from interactive terminal"
            read -p "Please select an option (1-4): " choice
        else
            # Non-interactive, try to read from /dev/tty
            debug "Reading from /dev/tty (non-interactive mode)"
            read -p "Please select an option (1-4): " choice < /dev/tty
        fi
        
        debug "User entered: '$choice'"
        
        # Handle empty input
        if [[ -z "$choice" ]]; then
            warning "Please enter a valid option."
            continue
        fi
        
        case $choice in
            1)
                info "Starting full installation..."
                full_installation
                break
                ;;
            2)
                info "Starting custom installation..."
                custom_installation
                break
                ;;
            3)
                show_system_info
                echo
                show_menu
                ;;
            4)
                print_color "$YELLOW" "Installation cancelled by user."
                exit 0
                ;;
            *)
                warning "Invalid option. Please select 1-4."
                ;;
        esac
    done
    
    debug "Exiting get_user_choice function"
}

#######################################
# Show system information
#######################################
show_system_info() {
    print_color "$CYAN" "
┌─────────────────────────────────────────────────────────────┐
│                    System Information                      │
├─────────────────────────────────────────────────────────────┤"
    print_color "$CYAN" "│ Pi Model:      $PI_MODEL"
    print_color "$CYAN" "│ OS Version:    $OS_VERSION ($ARCH)"
    print_color "$CYAN" "│ Supported:     $([ "$IS_SUPPORTED" == true ] && echo "Yes" || echo "No")"
    print_color "$CYAN" "│ Kernel:        $(uname -r)"
    print_color "$CYAN" "│ Uptime:        $(uptime -p)"
    print_color "$CYAN" "└─────────────────────────────────────────────────────────────┘"
}

#######################################
# Full installation
#######################################
full_installation() {
    print_color "$GREEN" "Starting full PiMesh-1W installation..."
    echo
    
    # TODO: Implement full installation
    install_meshtastic
    configure_pimesh_hardware
    setup_web_interface
    enable_services
    
    print_color "$GREEN" "
🎉 Installation completed successfully!

Your PiMesh-1W node is now ready to use.

⚠️  IMPORTANT: A reboot is required for GPIO changes to take effect.

Next steps:
1. Reboot your Raspberry Pi: sudo reboot
2. After reboot, access web interface: https://$(hostname -I | awk '{print $1}')
3. Check service status: sudo systemctl status meshtasticd
4. View logs: sudo journalctl -u meshtasticd -f

For support and documentation, visit: https://meshsmith.net
"
    
    echo
    read -p "Would you like to reboot now? (y/N): " reboot_now
    reboot_now=${reboot_now:-N}  # Default to N if empty
    case $reboot_now in
        [Yy]*)
            info "Rebooting system..."
            sudo reboot
            ;;
        *)
            warning "Remember to reboot before using your PiMesh-1W node!"
            ;;
    esac
}

#######################################
# Custom installation (placeholder)
#######################################
custom_installation() {
    warning "Custom installation not yet implemented"
    info "Falling back to full installation..."
    full_installation
}

#######################################
# Install Meshtastic
#######################################
install_meshtastic() {
    info "Installing Meshtastic daemon..."
    
    # Add Meshtastic repository based on architecture
    if [[ "$ARCH" == "armhf" ]]; then
        # 32-bit Raspberry Pi OS
        info "Adding 32-bit Meshtastic repository..."
        echo 'deb http://download.opensuse.org/repositories/network:/Meshtastic:/beta/Raspbian_12/ /' | sudo tee /etc/apt/sources.list.d/network:Meshtastic:beta.list
        curl -fsSL https://download.opensuse.org/repositories/network:Meshtastic:beta/Raspbian_12/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/network_Meshtastic_beta.gpg > /dev/null
    else
        # 64-bit: use Debian packages
        info "Adding 64-bit Meshtastic repository..."
        echo 'deb http://download.opensuse.org/repositories/network:/Meshtastic:/beta/Debian_12/ /' | sudo tee /etc/apt/sources.list.d/network:Meshtastic:beta.list
        curl -fsSL https://download.opensuse.org/repositories/network:Meshtastic:beta/Debian_12/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/network_Meshtastic_beta.gpg > /dev/null
    fi
    
    # Update package list
    info "Updating package list..."
    sudo apt-get update
    
    # Install Meshtastic daemon and dependencies
    info "Installing meshtasticd and dependencies..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y meshtasticd avahi-daemon
    
    success "Meshtastic daemon installed"
}

#######################################
# Configure PiMesh hardware
#######################################
configure_pimesh_hardware() {
    info "Configuring PiMesh-1W hardware..."
    
    # Enable SPI, I2C, and UART
    info "Enabling GPIO interfaces..."
    
    # Check if already enabled, if not add to config.txt
    local boot_config="/boot/firmware/config.txt"
    if [[ ! -f "$boot_config" ]]; then
        boot_config="/boot/config.txt"  # Fallback for older systems
    fi
    
    # Enable SPI (required for LoRa radio)
    if ! grep -q "^dtparam=spi=on" "$boot_config"; then
        echo "dtparam=spi=on" | sudo tee -a "$boot_config"
        info "Added SPI enable to config.txt"
    else
        info "SPI already enabled in config.txt"
    fi
    
    # Enable SPI overlay for chip select (required by Meshtastic)
    if ! grep -q "^dtoverlay=spi0-0cs" "$boot_config"; then
        echo "dtoverlay=spi0-0cs" | sudo tee -a "$boot_config"
        info "Added SPI chip select overlay to config.txt"
    else
        info "SPI chip select overlay already enabled in config.txt"
    fi
    
    # Enable I2C (for displays and sensors)
    if ! grep -q "^dtparam=i2c_arm=on" "$boot_config"; then
        echo "dtparam=i2c_arm=on" | sudo tee -a "$boot_config"
        info "Added I2C enable to config.txt"
    else
        info "I2C already enabled in config.txt"
    fi
    
    # Enable UART (for GPS support)
    if ! grep -q "^enable_uart=1" "$boot_config"; then
        echo "enable_uart=1" | sudo tee -a "$boot_config"
        info "Added UART enable to config.txt"
    else
        info "UART already enabled in config.txt"
    fi
    
    # Enable UART overlay for Pi 5 compatibility
    if [[ "$PI_MODEL" == *"Pi 5"* ]]; then
        if ! grep -q "^dtoverlay=uart0" "$boot_config"; then
            echo "dtoverlay=uart0" | sudo tee -a "$boot_config"
            info "Added UART overlay for Pi 5 to config.txt"
        else
            info "UART overlay for Pi 5 already enabled in config.txt"
        fi
    fi
    
    # Disable serial console (recommended for UART GPS usage)
    info "Configuring serial console..."
    if command -v raspi-config >/dev/null 2>&1; then
        # Use raspi-config if available (preferred method)
        sudo raspi-config nonint do_serial_cons 1  # Disable Serial Console
        info "Serial console disabled using raspi-config"
    else
        # Fallback: manual configuration
        if grep -q "console=serial0" /boot/firmware/cmdline.txt 2>/dev/null; then
            sudo sed -i 's/console=serial0[^ ]* //g' /boot/firmware/cmdline.txt
            info "Removed serial console from cmdline.txt"
        elif grep -q "console=serial0" /boot/cmdline.txt 2>/dev/null; then
            sudo sed -i 's/console=serial0[^ ]* //g' /boot/cmdline.txt
            info "Removed serial console from cmdline.txt"
        else
            info "Serial console already disabled"
        fi
    fi
    
    # Add user to necessary groups for GPIO/SPI access
    info "Adding user to gpio and spi groups..."
    sudo usermod -a -G gpio,spi,i2c "$(whoami)"
    
    # Ensure SPI device permissions
    if [[ -c /dev/spidev0.0 ]]; then
        success "SPI device /dev/spidev0.0 exists"
    else
        warning "SPI device not yet available (will be created after reboot)"
    fi
    
    # Create Meshtastic configuration directories
    sudo mkdir -p /etc/meshtasticd/config.d
    sudo mkdir -p /etc/meshtasticd/available.d
    
    # Create PiMesh-1W reference configuration (for documentation)
    info "Creating PiMesh-1W reference configuration..."
    
    sudo tee /etc/meshtasticd/available.d/pimesh-1w.yaml > /dev/null << 'EOF'
# PiMesh-1W (E22-900M30S) Reference Configuration
# https://MeshSmith.net
# Note: This is a reference file. The actual configuration is in /etc/meshtasticd/config.yaml
Lora:
  Module: sx1262
  CS: 21
  IRQ: 16
  Busy: 20
  Reset: 18
  TXen: 13
  RXen: 12
  DIO3_TCXO_VOLTAGE: true
EOF
    
    # Don't copy to config.d since we're using a unified config.yaml
    info "PiMesh-1W configuration will be included in main config.yaml"
    
    success "PiMesh-1W hardware configured"
    warning "Reboot required for GPIO changes to take effect"
}

#######################################
# Setup web interface
#######################################
setup_web_interface() {
    info "Setting up web interface..."
    
    # Create main configuration file with web interface enabled
    sudo tee /etc/meshtasticd/config.yaml > /dev/null << 'EOF'
# PiMesh-1W Main Configuration
# https://MeshSmith.net

# LoRa Radio Configuration (PiMesh-1W with E22-900M30S)
Lora:
  Module: sx1262
  CS: 21
  IRQ: 16
  Busy: 20
  Reset: 18
  TXen: 13
  RXen: 12
  DIO3_TCXO_VOLTAGE: true

# Web Interface Configuration
Webserver:
  Port: 443
  RootPath: /usr/share/meshtasticd/web
EOF
    
    # Setup Avahi service for network discovery
    info "Configuring network discovery..."
    
    sudo tee /etc/avahi/services/meshtastic.service > /dev/null << 'EOF'
<?xml version="1.0" standalone="no"?><!--*-nxml-*-->
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name>Meshtastic</name>
  <service protocol="ipv4">
    <type>_meshtastic._tcp</type>
    <port>4403</port>
  </service>
  <service protocol="ipv4">
    <type>_http._tcp</type>
    <port>443</port>
    <txt-record>path=/</txt-record>
  </service>
</service-group>
EOF
    
    success "Web interface configured"
    info "Web interface will be available at: https://$(hostname -I | awk '{print $1}')"
}

#######################################
# Validate Meshtastic service
#######################################
validate_service() {
    info "Validating Meshtastic service configuration..."
    
    # Check if config files exist
    if [[ -f /etc/meshtasticd/config.yaml ]]; then
        success "Main configuration file exists"
    else
        error_exit "Main configuration file missing"
    fi
    
    # Validate YAML syntax and required sections
    if command -v python3 >/dev/null 2>&1; then
        if python3 -c "
import yaml
try:
    with open('/etc/meshtasticd/config.yaml', 'r') as f:
        config = yaml.safe_load(f)
    
    # Check for required sections
    if 'Lora' not in config:
        print('ERROR: Missing Lora section')
        exit(1)
    if 'Module' not in config['Lora']:
        print('ERROR: Missing Lora.Module')
        exit(1)
    if 'CS' not in config['Lora']:
        print('ERROR: Missing Lora.CS pin')
        exit(1)
    
    print('Configuration validation passed')
except Exception as e:
    print(f'ERROR: {e}')
    exit(1)
" 2>/dev/null; then
            success "Configuration YAML syntax and structure is valid"
        else
            warning "Configuration validation failed - check YAML syntax"
        fi
    fi
    
    # Check service status
    if systemctl is-enabled --quiet meshtasticd; then
        success "Meshtastic service is enabled"
    else
        warning "Meshtastic service is not enabled"
    fi
    
    # Check GPIO groups
    if groups "$(whoami)" | grep -q gpio; then
        success "User is in gpio group"
    else
        warning "User is not in gpio group (logout/login required)"
    fi
    
    if groups "$(whoami)" | grep -q spi; then
        success "User is in spi group"
    else
        warning "User is not in spi group (logout/login required)"
    fi
    
    # Validate GPIO interface configuration
    local boot_config="/boot/firmware/config.txt"
    if [[ ! -f "$boot_config" ]]; then
        boot_config="/boot/config.txt"
    fi
    
    if [[ -f "$boot_config" ]]; then
        if grep -q "^dtparam=spi=on" "$boot_config"; then
            success "SPI enabled in config.txt"
        else
            warning "SPI not enabled in config.txt"
        fi
        
        if grep -q "^dtoverlay=spi0-0cs" "$boot_config"; then
            success "SPI chip select overlay enabled in config.txt"
        else
            warning "SPI chip select overlay not enabled in config.txt"
        fi
        
        if grep -q "^dtparam=i2c_arm=on" "$boot_config"; then
            success "I2C enabled in config.txt"
        else
            warning "I2C not enabled in config.txt"
        fi
        
        if grep -q "^enable_uart=1" "$boot_config"; then
            success "UART enabled in config.txt"
        else
            warning "UART not enabled in config.txt"
        fi
        
        if [[ "$PI_MODEL" == *"Pi 5"* ]] && grep -q "^dtoverlay=uart0" "$boot_config"; then
            success "Pi 5 UART overlay enabled in config.txt"
        elif [[ "$PI_MODEL" == *"Pi 5"* ]]; then
            warning "Pi 5 UART overlay not enabled in config.txt"
        fi
    else
        warning "Config.txt not found"
    fi
}

#######################################
# Show troubleshooting information
#######################################
show_troubleshooting() {
    print_color "$YELLOW" "
🔧 Troubleshooting Information:

Service Commands:
  sudo systemctl status meshtasticd     # Check service status
  sudo journalctl -u meshtasticd -f     # View live logs
  sudo journalctl -u meshtasticd -b     # View logs since boot

Hardware Validation:
  ls -la /dev/spidev*                   # Check SPI devices
  ls -la /dev/i2c*                      # Check I2C devices
  ls -la /dev/ttyAMA0 /dev/ttyS0        # Check UART devices

Manual Service Test:
  sudo meshtasticd --help               # Test binary
  sudo meshtasticd -c /etc/meshtasticd/config.yaml  # Test with config

Configuration Files:
  Main config: /etc/meshtasticd/config.yaml (contains all settings)
  Reference: /etc/meshtasticd/available.d/pimesh-1w.yaml
  Boot config: /boot/firmware/config.txt

Configuration Validation:
  sudo meshtasticd -c /etc/meshtasticd/config.yaml --version
  python3 -c \"import yaml; print(yaml.safe_load(open('/etc/meshtasticd/config.yaml')))\"

Required in /boot/firmware/config.txt:
  dtparam=spi=on                        # Enable SPI
  dtoverlay=spi0-0cs                    # Enable SPI chip select
  dtparam=i2c_arm=on                    # Enable I2C
  enable_uart=1                         # Enable UART
  dtoverlay=uart0                       # Pi 5 only

Common Issues:
  1. ❗ Reboot required after config.txt changes
  2. ❗ User must logout/login after group changes
  3. ❗ Serial console interferes with GPS UART
  4. ❗ Check radio module wiring to GPIO pins

Documentation:
  📖 https://meshtastic.org/docs/hardware/devices/linux-native-hardware/?os=debian
"
}

#######################################
# Enable services
#######################################
enable_services() {
    info "Enabling auto-start services..."
    
    # Validate configuration before enabling services
    validate_service
    
    # Enable and start Meshtastic daemon
    info "Enabling meshtasticd service..."
    sudo systemctl enable meshtasticd
    
    # Enable and start Avahi daemon for network discovery
    info "Enabling avahi-daemon service..."
    sudo systemctl enable avahi-daemon
    sudo systemctl start avahi-daemon
    
    # Check if we should start meshtasticd now or after reboot
    read -p "Would you like to start Meshtastic daemon now? (y/N): " start_now
    start_now=${start_now:-N}  # Default to N if empty
    case $start_now in
        [Yy]*)
            info "Starting meshtasticd service..."
            if sudo systemctl start meshtasticd; then
                success "Meshtastic daemon started successfully"
                
                # Wait a moment and check status
                sleep 3
                if sudo systemctl is-active --quiet meshtasticd; then
                    success "Service is running properly"
                else
                    warning "Service may need a reboot to function properly due to GPIO requirements"
                    show_troubleshooting
                fi
            else
                warning "Failed to start service - this is expected before reboot"
                info "The service will start automatically after reboot when GPIO interfaces are available"
                show_troubleshooting
            fi
            ;;
        *)
            info "Service will start automatically after reboot"
            ;;
    esac
    
    success "Services configured for auto-start"
}

#######################################
# Main function
#######################################
main() {
    # Initialize log file
    echo "PiMesh-1W Installer started at $(date)" > "$LOG_FILE"
    
    print_header
    
    # System checks
    check_root
    detect_pi_model
    detect_os
    check_requirements
    
    echo
    info "System checks completed successfully!"
    echo
    
    # Show menu and get user input
    log "About to show menu"
    show_menu
    log "Menu displayed, waiting for user input"
    get_user_choice
    log "User choice completed"
}

# Run main function
main "$@"