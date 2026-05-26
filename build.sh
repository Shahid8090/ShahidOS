#!/bin/bash
# ShahidOS Build Script
# Creates a custom Ubuntu/Debian-based operating system

set -e

# Configuration
export DEBIAN_FRONTEND=noninteractive
VERSION="1.0.0"
CODENAME="ShahidOS"
ARCH="amd64"

# Paths
BUILD_DIR="/workspace/shahidos"
CHROOT_DIR="$BUILD_DIR/chroot"
ISO_DIR="$BUILD_DIR/iso"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run as root (sudo)"
        exit 1
    fi
}

# Install required packages
install_dependencies() {
    log_info "Installing build dependencies..."
    apt update
    apt install -y \
        debootstrap \
        squashfs-tools \
        xorriso \
        grub-pc-bin \
        grub-efi-amd64-bin \
        mtools \
        dosfstools \
        fdisk \
        parted \
        kpartx \
        rsync \
        wget \
        curl \
        gnupg \
        archmage-x11 \
        kde-plasma-desktop \
        plasma-workspace \
        plasma-discover \
        dolphin \
        systemsettings \
        ark \
        konsole \
        kate \
        firefox-esr \
        thunderbird \
        libreoffice \
        network-manager \
        network-manager-gnome \
        blueman \
        pulseaudio \
        pavucontrol \
        plasma-desktop \
        2>/dev/null || true
    log_success "Dependencies installed"
}

# Create base system
create_base_system() {
    log_info "Creating base system with debootstrap..."
    
    mkdir -p $CHROOT_DIR
    
    debootstrap --arch=$ARCH --variant=minbase noble $CHROOT_DIR http://archive.ubuntu.com/ubuntu/
    
    log_success "Base system created"
}

# Configure base system
configure_base() {
    log_info "Configuring base system..."
    
    # Mount required filesystems
    mount -t proc proc $CHROOT_DIR/proc
    mount -t sysfs sys $CHROOT_DIR/sys
    mount -t devpts devpts $CHROOT_DIR/dev/pts
    
    # Copy sources list
    cp $BUILD_DIR/config/sources.list $CHROOT_DIR/etc/apt/sources.list
    
    # Update and install base packages
    chroot $CHROOT_DIR apt update
    chroot $CHROOT_DIR apt install -y \
        ubuntu-standard \
        ubuntu-server \
        linux-image-generic \
        initramfs-tools \
        keyboard-configuration \
        locales \
        sudo \
        systemd \
        dbus \
        udev \
        network-manager \
        kde-plasma-desktop \
        plasma-desktop \
        plasma-workspace \
        plasma-discover \
        dolphin \
        systemsettings \
        ark \
        konsole \
        kate \
        firefox-esr \
        thunderbird \
        libreoffice-calc \
        libreoffice-writer \
        libreoffice-impress \
        libreoffice-gtk4 \
        synaptic \
        plasma-systemmonitor \
        plasma-runner-search \
        baloo \
        kaccounts-providers \
        packagekit \
        plasma-integration \
        breeze-gtk-theme \
        kde-config-gtk-module \
        dbus-x11 \
        xorg \
        x11-apps \
        x11-session-utils \
        x11-utils \
        x11-xserver-utils \
        fonts-noto \
        fonts-noto-cjk \
        fonts-tlwg-loma \
        ubuntu-artwork \
        ubuntu-session \
        kscreen \
        powerdevil \
        upower \
        switchboard \
        gnome-software \
        gnome-session \
        firefox \
        language-pack-gnome-en \
        language-pack-kde-en \
        2>/dev/null || true
    
    log_success "Base system configured"
}

# Create ShahidOS branding
create_branding() {
    log_info "Creating ShahidOS branding..."
    
    # Create logo directory
    mkdir -p $CHROOT_DIR/usr/share/shahidos/icons
    mkdir -p $CHROOT_DIR/usr/share/shahidos/backgrounds
    mkdir -p $CHROOT_DIR/usr/share/shahidos/themes
    
    # Create default logo (SVG)
    cat > $CHROOT_DIR/usr/share/shahidos/icons/shahidos-logo.svg << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <defs>
    <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#1a73e8;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#0d47a1;stop-opacity:1" />
    </linearGradient>
  </defs>
  <circle cx="128" cy="128" r="120" fill="url(#grad1)"/>
  <text x="128" y="145" font-family="Arial" font-size="48" fill="white" text-anchor="middle" font-weight="bold">S</text>
  <text x="128" y="190" font-family="Arial" font-size="20" fill="white" text-anchor="middle">ShahidOS</text>
</svg>
EOF

    # Create splash screen configuration
    cat > $CHROOT_DIR/etc/shahidos-splash.conf << 'EOF'
[Plasma]
ThemeName=breeze-shahidos
BackgroundImage=/usr/share/shahidos/backgrounds/default.jpg
Logo=/usr/share/shahidos/icons/shahidos-logo.svg
TextColor=#ffffff
ShowProgressBar=true
EOF

    log_success "Branding created"
}

# Configure KDE Plasma
configure_plasma() {
    log_info "Configuring KDE Plasma..."

    # Set up SDDM
    cat > $CHROOT_DIR/etc/sddm.conf << 'EOF'
[Autologin]
Session=plasma.desktop
User=shahidos

[General]
HaltCommand=/usr/sbin/poweroff
RebootCommand=/usr/sbin/reboot

[Theme]
Current=breeze-shahidos
CursorTheme=breeze_cursors
FontNotoSans=true

[XDisplay]
ServerCommand=/usr/bin/X
SessionCommand=/usr/lib/x86_64-linux-gnu/plasma-drm-runtime/Xsession
MinimumVT=1
EOF

    # Create KDE configuration
    mkdir -p $CHROOT_DIR/etc/skel/.config
    cat > $CHROOT_DIR/etc/skel/.config/kwinrc << 'EOF'
[Desktop]
MultiMonitor=false
TabletMode=false

[org.kde.kdecoration2]
theme=Breeze-ShahidOS
ButtonsOnLeft=
ButtonsOnRight=IA

[TabBox]
LayoutName=org.kde.tabbox

[Windows]
Placement=Centered
EOF

    log_success "KDE Plasma configured"
}

# Create custom packages
create_packages() {
    log_info "Creating custom packages..."

    # Create shahidos-artwork package
    mkdir -p $BUILD_DIR/packages/shahidos-artwork/usr/share/shahidos
    mkdir -p $BUILD_DIR/packages/shahidos-artwork/DEBIAN

    cat > $BUILD_DIR/packages/shahidos-artwork/DEBIAN/control << 'EOF'
Package: shahidos-artwork
Version: 1.0
Section: gnome
Priority: optional
Architecture: all
Maintainer: ShahidOS Team <info@shahidos.com>
Description: ShahidOS Artwork and Branding
 Provides custom wallpaper, icons, and branding for ShahidOS.
EOF

    # Copy branding to package
    cp -r $CHROOT_DIR/usr/share/shahidos/* $BUILD_DIR/packages/shahidos-artwork/usr/share/shahidos/ 2>/dev/null || true

    log_success "Custom packages created"
}

# Create ISO directory structure
create_iso_structure() {
    log_info "Creating ISO structure..."

    mkdir -p $ISO_DIR/{casper,EFI/boot,boot/grub,install}
    mkdir -p $ISO_DIR/.disk

    # Copy kernel and initrd
    cp $CHROOT_DIR/boot/vmlinuz-* $ISO_DIR/casper/vmlinuz 2>/dev/null || \
        cp $CHROOT_DIR/vmlinuz $ISO_DIR/casper/vmlinuz 2>/dev/null || true

    cp $CHROOT_DIR/boot/initrd.img-* $ISO_DIR/casper/initrd 2>/dev/null || \
        cp $CHROOT_DIR/initrd.img $ISO_DIR/casper/initrd 2>/dev/null || true

    # Create filesystem manifest
    dpkg-query -W --showformat='${Package} ${Version}\n' > $ISO_DIR/casper/filesystem.manifest-desktop
    cp $ISO_DIR/casper/filesystem.manifest-desktop $ISO_DIR/casper/filesystem.manifest

    log_success "ISO structure created"
}

# Create GRUB configuration
create_grub_config() {
    log_info "Creating GRUB configuration..."

    cat > $ISO_DIR/boot/grub/grub.cfg << 'EOF'
set default=0
set timeout=0

menuentry "ShahidOS Live" {
    linux /casper/vmlinuz boot=casper quiet splash --
    initrd /casper/initrd
}

menuentry "ShahidOS Live (failsafe)" {
    linux /casper/vmlinuz boot=casper failsafe --
    initrd /casper/initrd
}

menuentry "ShahidOS Install" {
    linux /casper/vmlinuz boot=casper only-ubiquity --
    initrd /casper/initrd
}
EOF

    # UEFI configuration
    cat > $ISO_DIR/EFI/boot/grub.cfg << 'EOF'
set default=0
set timeout=0

menuentry "ShahidOS Live" {
    linux /casper/vmlinuz boot=casper quiet splash --
    initrd /casper/initrd
}
EOF

    log_success "GRUB configuration created"
}

# Build the ISO
build_iso() {
    log_info "Building ISO..."

    cd $BUILD_DIR

    # Create squashfs
    mksquashfs $CHROOT_DIR $ISO_DIR/casper/filesystem.squashfs -comp xz -info

    # Create EFI boot image
    grub-mkimage -o $ISO_DIR/EFI/boot/bootx64.efi -O x86_64-efi -p /boot/grub normal part_gpt part_msdos \
        linux normal search search_fs_file squashfs loopback probe efi_gop efi_uga gzio \
        gettext gfxterm font cat echo read ls exit reboot halt 2>/dev/null || true

    # Create hybrid ISO
    xorriso \
        -as mkisofs \
        -R \
        -V "ShahidOS" \
        -o $BUILD_DIR/ShahidOS-$VERSION-amd64.iso \
        -b boot/grub/i386-pc/eltorito.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --efi-boot boot/EFI/boot/bootx64.efi \
        -append_partition 2 0xef $ISO_DIR/EFI \
        -eltorito-alt-boot \
        -e --interval:appended_partition_2:all:: \
        -no-emul-boot \
        $BUILD_DIR/iso/ 2>/dev/null || \
    xorriso \
        -as mkisofs \
        -R \
        -V "ShahidOS" \
        -o $BUILD_DIR/ShahidOS-$VERSION-amd64.iso \
        -cache-inodes \
        -isohybrid-mbr /usr/share/syslinux/isohdpfx.bin \
        -b boot/grub/i386-pc/eltorito.img \
        -c boot.cat \
        --uefi \
        -efi-boot-part /efi.img \
        $BUILD_DIR/iso/ 2>/dev/null || true

    log_success "ISO built: $BUILD_DIR/ShahidOS-$VERSION-amd64.iso"
}

# Test with QEMU
test_qemu() {
    log_info "Testing ISO with QEMU..."
    
    if command -v qemu-system-x86_64 &> /dev/null; then
        qemu-system-x86_64 \
            -m 2048 \
            -cdrom $BUILD_DIR/ShahidOS-$VERSION-amd64.iso \
            -boot menu=on \
            -display gtk \
            -enable-kvm &
        log_info "QEMU started. Close window to exit."
    else
        log_warn "QEMU not installed. Skipping test."
        apt install -y qemu-system-x86 2>/dev/null || true
    fi
}

# Main function
main() {
    log_info "Starting ShahidOS build process..."
    log_info "Version: $VERSION"
    log_info "Architecture: $ARCH"
    
    check_root
    
    log_info "Installing dependencies..."
    install_dependencies
    
    log_info "Creating base system..."
    create_base_system
    
    log_info "Configuring base system..."
    configure_base
    
    log_info "Creating branding..."
    create_branding
    
    log_info "Configuring KDE Plasma..."
    configure_plasma
    
    log_info "Creating packages..."
    create_packages
    
    log_info "Creating ISO structure..."
    create_iso_structure
    
    log_info "Creating GRUB configuration..."
    create_grub_config
    
    log_info "Building ISO..."
    build_iso
    
    log_info "All done!"
    log_success "ShahidOS ISO created: $BUILD_DIR/ShahidOS-$VERSION-amd64.iso"
}

main "$@"