# PiMesh Installer Project

This workspace contains an interactive Raspberry Pi Meshtastic installer script for easy setup of PiMesh-1W hardware.

## Project Goals
- Single command installation via curl
- Interactive TUI for user-friendly setup
- Support for Pi 3/4/5 with Bookworm/Trixie
- Automatic hardware detection and configuration
- PiMesh-1W (E22-900M30S) preset integration

## Key Components
- Main installer script with TUI interface
- Hardware detection and OS compatibility checks
- Meshtastic daemon configuration
- GPIO setup for PiMesh-1W hardware
- Service management and auto-start configuration

## Usage
```bash
curl -sSL https://install.meshsmith.net | bash
```