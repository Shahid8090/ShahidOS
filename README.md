# ShahidOS - Custom Ubuntu-Based Desktop OS

A fully customizable Debian/Ubuntu-based operating system featuring KDE Plasma with Windows 11-inspired layout.

## Overview

ShahidOS is a custom distribution built on Ubuntu 24.04 LTS (Noble Numbat) with:
- KDE Plasma Desktop (Windows 11 style layout)
- Professional dark theme
- Custom branding and theming
- Full application suite
- Bootable ISO with live mode and installer

## Build Status

### Current Status: ✅ ISO Structure Generated

The ISO structure and configuration files have been created. The ISO requires:
- Ubuntu 24.04 kernel (vmlinuz) and initrd
- Full build environment for complete ISO generation

### Files Created

```
shahidos/
├── README.md                    # This file
├── build-all.sh                 # Main build script (run on Ubuntu)
├── build-from-ubuntu.sh         # Build from existing Ubuntu ISO
├── build-shahidos.sh            # Alternative build script
├── generate-iso.py              # Python ISO structure generator
├── test-qemu.sh                 # QEMU test script
├── cubic-config.sh              # Cubic customization config
├── config/
│   ├── sources.list             # Ubuntu 24.04 repositories
│   └── packages.list            # Package list for installation
├── scripts/
│   └── configure-plasma.sh      # KDE Plasma configuration
├── themes/
│   ├── ShahidOS-Dark.colors     # Dark theme colors
│   └── ShahidOS-Icons/          # Icon theme
├── packages/
│   └── shahidos-artwork/        # Branding package
├── build/
│   └── work/iso/                # ISO structure (generated)
│       ├── casper/              # Kernel, initrd, squashfs
│       ├── boot/grub/           # GRUB configuration
│       └── EFI/boot/            # UEFI configuration
└── output/                      # Built ISO output
```

## Quick Start - Build ShahidOS

### Option 1: Full Build (Recommended)

On Ubuntu 24.04/Debian system with root access:

```bash
# 1. Clone/copy this project to your build machine

# 2. Make scripts executable
chmod +x build-all.sh

# 3. Run full build
sudo ./build-all.sh

# 4. Wait 30-60 minutes for build to complete

# 5. Find your ISO at:
#    output/ShahidOS-1.0.0-amd64.iso
```

### Option 2: Build from Existing Ubuntu ISO (Faster)

```bash
# Download Ubuntu 24.04 Desktop ISO first
wget http://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso

# Run build script
sudo ./build-from-ubuntu.sh --iso=ubuntu-24.04-desktop-amd64.iso
```

### Option 3: Using Cubic (GUI)

```bash
# Install Cubic
sudo apt install cubic

# Launch Cubic and use:
# - Source ISO: Ubuntu 24.04 Desktop
# - Custom script: cubic-config.sh
```

### Testing with QEMU

```bash
# After ISO is built
./test-qemu.sh

# Or manually
qemu-system-x86_64 \
    -m 4G \
    -cdrom output/ShahidOS-1.0.0-amd64.iso \
    -boot d \
    -display gtk
```

## Build Requirements

### System Requirements
- 4+ CPU cores
- 8GB+ RAM  
- 50GB+ free disk space
- Ubuntu 24.04 or Debian 12+

### Required Packages
```bash
sudo apt install \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools \
    dosfstools \
    gdisk \
    kpartx \
    rsync \
    wget

# Optional
sudo apt install qemu-system-x86
```

## Project Structure

```
shahidos/
├── build-all.sh          # Main build script (from scratch)
├── build-from-ubuntu.sh  # Build from existing Ubuntu ISO
├── config/
│   ├── sources.list      # Ubuntu repositories
│   ├── packages.list     # Packages to install
│   └── locale.conf       # System locale
├── scripts/
│   ├── 01-base.sh        # Base system setup
│   ├── 02-kde.sh         # KDE Plasma installation
│   ├── 03-branding.sh    # ShahidOS branding
│   ├── 04-themes.sh      # Custom themes
│   ├── 05-apps.sh        # Application installation
│   ├── 06-config.sh      # System configuration
│   └── 07-iso.sh         # ISO creation
├── themes/
│   ├── ShahidOS-Dark/    # Dark theme
│   ├── ShahidOS-Icons/   # Icon set
│   └── ShahidOS-Cursors/ # Cursor theme
├── packages/
│   └── shahidos-artwork/ # Custom wallpaper/branding
├── output/              # Built ISOs
└── README.md
```

## Features

### Desktop Experience
- ✓ KDE Plasma 6 with Windows 11-style layout
- ✓ Centered taskbar
- ✓ Custom start menu (Kickoff)
- ✓ System tray with network, volume, bluetooth
- ✓ Notification center
- ✓ Dark theme by default

### Applications
- ✓ Dolphin file manager
- ✓ System Settings (Systemsettings)
- ✓ Ark archive manager
- ✓ Konsole terminal
- ✓ Kate text editor
- ✓ Firefox web browser
- ✓ Thunderbird email
- ✓ LibreOffice suite

### System
- ✓ NetworkManager (WiFi/Ethernet)
- ✓ Bluetooth (Blueman)
- ✓ Audio (PulseAudio/Pavucontrol)
- ✓ Modern Mesa graphics drivers
- ✓ Full Linux kernel

### Boot & Install
- ✓ UEFI support
- ✓ BIOS/Legacy support
- ✓ Live boot mode
- ✓ Graphical installer (Calamares or Ubiquity)
- ✓ Persistent storage support

## Customization

### Changing Wallpaper
Replace files in: `packages/shahidos-artwork/usr/share/backgrounds/`

### Changing Icons
Replace files in: `packages/shahidos-artwork/usr/share/icons/`

### Changing Theme Colors
Edit: `themes/ShahidOS-Dark/colors`

### Changing Boot Splash
Edit: `config/plymouth.conf`

## Build Options

### Faster Build (Less Packages)
```bash
./build-all.sh --minimal
```

### Debug Mode
```bash
./build-all.sh --debug
```

### Custom Version
```bash
VERSION=2.0.0 ./build-all.sh
```

## System Requirements

### Build Machine
- 4+ CPU cores
- 8GB+ RAM
- 50GB+ free disk space
- Ubuntu/Debian-based Linux

### Target System
- 2GB+ RAM
- 20GB+ storage
- 64-bit x86 processor
- Graphics card with driver support

## Troubleshooting

### Build Fails with "No Space"
Clear cache: `rm -rf work/`
Increase loop devices: `ls -la /dev/loop*`

### QEMU Very Slow
Enable KVM: `ls /dev/kvm` (if exists)
Use: `qemu-system-x86_64 -enable-kvm ...`

### Network Issues in Chroot
Run: `./scripts/03-network.sh`

## License

ShahidOS is provided as-is. Ubuntu components are licensed under GPL.

## Credits

- Ubuntu: https://ubuntu.com
- KDE: https://kde.org
- This project: Custom development

---

**Version:** 1.0.0  
**Based on:** Ubuntu 24.04 LTS  
**Desktop:** KDE Plasma 6  
**Architecture:** amd64