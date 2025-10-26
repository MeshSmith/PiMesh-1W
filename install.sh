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
    
    # Enable SPI
    if ! grep -q "^dtparam=spi=on" "$boot_config"; then
        echo "dtparam=spi=on" | sudo tee -a "$boot_config"
    fi
    
    # Enable SPI overlay for chip select
    if ! grep -q "^dtoverlay=spi0-0cs" "$boot_config"; then
        echo "dtoverlay=spi0-0cs" | sudo tee -a "$boot_config"
    fi
    
    # Enable I2C
    if ! grep -q "^dtparam=i2c_arm=on" "$boot_config"; then
        echo "dtparam=i2c_arm=on" | sudo tee -a "$boot_config"
    fi
    
    # Enable UART
    if ! grep -q "^enable_uart=1" "$boot_config"; then
        echo "enable_uart=1" | sudo tee -a "$boot_config"
    fi
    
    # Create Meshtastic configuration directories
    sudo mkdir -p /etc/meshtasticd/config.d
    sudo mkdir -p /etc/meshtasticd/available.d
    
    # Create PiMesh-1W configuration
    info "Creating PiMesh-1W configuration..."
    
    sudo tee /etc/meshtasticd/available.d/pimesh-1w.yaml > /dev/null << 'EOF'
# PiMesh-1W (E22-900M30S)
# https://MeshSmith.net
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
    
    # Activate the PiMesh-1W preset
    sudo cp /etc/meshtasticd/available.d/pimesh-1w.yaml /etc/meshtasticd/config.d/
    
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

Webserver:
  Port: 443
  RootPath: /usr/share/meshtasticd/web
  
# Additional web interface settings
Serial:
  Enabled: true
  Echo: true
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
# Enable services
#######################################
enable_services() {
    info "Enabling auto-start services..."
    
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
                fi
            else
                warning "Failed to start service - reboot may be required for GPIO access"
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