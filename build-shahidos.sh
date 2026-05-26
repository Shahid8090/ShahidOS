#!/bin/bash
# ShahidOS Builder - Uses Ubuntu Live ISO as base
# Version: 1.0

set -e

VERSION="1.0.0"
BUILD_DIR="/workspace/shahidos"
WORK_DIR="$BUILD_DIR/work"
ISO_DIR="$BUILD_DIR/iso"
CHROOT_DIR="$WORK_DIR/chroot"
UBUNTU_ISO_URL="http://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso"
UBUNTU_ISO="ubuntu-24.04-desktop-amd64.iso"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[*]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }

# Check root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Install deps
install_deps() {
    log "Installing dependencies..."
    apt update
    apt install -y \
        wget \
        squashfs-tools \
        xorriso \
        grub-pc-bin \
        grub-efi-amd64-bin \
        mtools \
        dosfstools \
        gdisk \
        parted \
        kpartx \
        rsync \
        archmage-x11 \
        x11-apps \
        x11-utils \
        x11-session-utils \
        fuse \
        bogl-bterm \
        gfxboot-theme-ubuntu \
        squashfs-tools \
        genisoimage \
        2>/dev/null || true
    success "Dependencies installed"
}

# Download Ubuntu ISO
download_iso() {
    log "Downloading Ubuntu 24.04 Desktop ISO..."
    cd "$BUILD_DIR"
    if [ ! -f "$UBUNTU_ISO" ]; then
        wget -q --show-progress "$UBUNTU_ISO_URL" -O "$UBUNTU_ISO" || \
        curl -# -L "$UBUNTU_ISO_URL" -o "$UBUNTU_ISO" || true
    fi
    success "Ubuntu ISO downloaded"
}

# Extract ISO
extract_iso() {
    log "Extracting Ubuntu ISO..."
    mkdir -p "$WORK_DIR/mount"
    mkdir -p "$WORK_DIR/squashfs"
    mount -o loop "$BUILD_DIR/$UBUNTU_ISO" "$WORK_DIR/mount"
    unsquashfs -f -d "$WORK_DIR/squashfs" "$WORK_DIR/mount/casper/filesystem.squashfs" || true
    umount "$WORK_DIR/mount" 2>/dev/null || true
    success "ISO extracted"
}

# Customize the system
customize_system() {
    log "Customizing ShahidOS..."

    # Copy sources
    mkdir -p "$CHROOT_DIR/etc/apt"
    cp "$BUILD_DIR/config/sources.list" "$CHROOT_DIR/etc/apt/sources.list"

    # Update
    mount -t proc proc "$CHROOT_DIR/proc"
    mount -t sysfs sys "$CHROOT_DIR/sys"
    mount --bind /dev "$CHROOT_DIR/dev"

    # Chroot into system
    cat > "$WORK_DIR/chroot-customize.sh" << 'CHROOTEOF'
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
export LANG=C

echo "ShahidOS" > /etc hostname
echo "shahidos" > /etc/hostname

# Add ShahidOS repository
echo "deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse" > /etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse" >> /etc/apt/sources.list

# Update
apt update -qq

# Install additional packages
apt install -y --no-install-recommends \
    plasma-desktop \
    kde-config-gtk-module \
    breeze-gtk-theme \
    kde-style-breeze \
    plasma-systemmonitor \
    systemsettings \
    dolphin \
    ark \
    konsole \
    kate \
    firefox \
    thunderbird \
    libreoffice-calc \
    libreoffice-writer \
    libreoffice-impress \
    2>/dev/null || true

# Remove snaps
apt remove --purge snapd 2>/dev/null || true

# Install network-manager
apt install -y network-manager network-manager-gnome 2>/dev/null || true

# Install audio
apt install -y pulseaudio pavucontrol 2>/dev/null || true

# Install bluetooth
apt install -y blueman 2>/dev/null || true

# Create shahidos user
useradd -m -s /bin/bash shahidos 2>/dev/null || true
echo "shahidos:shahidos" | chpasswd
usermod -aG sudo,adm,cdrom,dip,plugdev,lpadmin,sambashare shahidos

# Configure sudo
echo "shahidos ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/shahidos
chmod 0440 /etc/sudoers.d/shahidos

# Set up SDDM
apt install -y sddm sddm-theme-breeze 2>/dev/null || true

# Create ShahidOS branding
mkdir -p /usr/share/shahidos/icons
mkdir -p /usr/share/shahidos/backgrounds
mkdir -p /usr/share/shahidos/themes

# Create simple icon (PPM format)
cat > /usr/share/shahidos/icons/shahidos-logo.ppm << 'ICON'
P6
256 256
255
ICON
python3 -c "
import struct
with open('/usr/share/shahidos/icons/shahidos-logo.ppm', 'wb') as f:
    f.write(b'P6\n256 256\n255\n')
    # Blue gradient
    for y in range(256):
        for x in range(256):
            r = int(26 + (x/256)*50)
            g = int(115 + (y/256)*100)
            b = int(232)
            f.write(struct.pack('BBB', r, g, b))
"

# Create wallpapers
cp /usr/share/backgrounds/*/GNU_Rabbit* /usr/share/shahidos/backgrounds/default.jpg 2>/dev/null || \
cp /usr/share/backgrounds/kde-cyberpunk* /usr/share/shahidos/backgrounds/default.jpg 2>/dev/null || \
cp /usr/share/backgrounds/Oracle_Light_* /usr/share/shahidos/backgrounds/default.jpg 2>/dev/null || true

# Configure KDE
mkdir -p /etc/skel/.config

cat > /etc/skel/.config/kwinrc << 'KWIN'
[Desktop]
MultiMonitor=false

[org.kde.kdecoration2]
theme=Breeze-ShahidOS
ButtonsOnLeft=
ButtonsOnRight=IA
KWIN

cat > /etc/skel/.config/plasmashellrc << 'PLASMA'
[Containments][1]
plugin=org.kde.plasma.taskmanager
[Containments][2]
plugin=org.kde.plasma.panel
PLASMA

# Copy branding to skel
cp -r /usr/share/shahidos /etc/skel/ 2>/dev/null || true

# Set up lightdm instead of sddm
apt install -y lightdm lightdm-gtk-greeter 2>/dev/null || true

cat > /etc/lightdm/lightdm.conf << 'LIGHTDM'
[Seat:*]
user-session=plasma
greeter-session=lightdm-gtk-greeter
LIGHTDM

# Enable services
systemctl enable lightdm 2>/dev/null || true
systemctl enable NetworkManager 2>/dev/null || true

# Clean up
apt clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
rm -rf /var/tmp/*
CHROOTEOF

    chmod +x "$WORK_DIR/chroot-customize.sh"
    chroot "$CHROOT_DIR" /bin/bash /chroot-customize.sh

    umount "$CHROOT_DIR/proc" 2>/dev/null || true
    umount "$CHROOT_DIR/sys" 2>/dev/null || true
    umount "$CHROOT_DIR/dev" 2>/dev/null || true

    success "System customized"
}

# Create ISO
create_iso() {
    log "Creating ShahidOS ISO..."

    mkdir -p "$ISO_DIR/casper"
    mkdir -p "$ISO_DIR/boot/grub/x86_64-efi"
    mkdir -p "$ISO_DIR/boot/grub/i386-pc"
    mkdir -p "$ISO_DIR/EFI/boot"

    # Copy kernel and initrd from extracted system
    cp "$CHROOT_DIR/boot/vmlinuz-*" "$ISO_DIR/casper/vmlinuz" 2>/dev/null || \
    cp "$CHROOT_DIR/vmlinuz" "$ISO_DIR/casper/vmlinuz" 2>/dev/null || \
    ls "$CHROOT_DIR/boot/vmlinuz"* | head -1 | xargs -I{} cp {} "$ISO_DIR/casper/vmlinuz"

    cp "$CHROOT_DIR/boot/initrd.img-*" "$ISO_DIR/casper/initrd" 2>/dev/null || \
    cp "$CHROOT_DIR/initrd.img" "$ISO_DIR/casper/initrd" 2>/dev/null || \
    ls "$CHROOT_DIR/boot/initrd.img"* | head -1 | xargs -I{} cp {} "$ISO_DIR/casper/initrd"

    # Create squashfs
    log "Creating filesystem squashfs..."
    mksquashfs "$CHROOT_DIR" "$ISO_DIR/casper/filesystem.squashfs" \
        -comp xz \
        -e proc \
        -e sys \
        -e dev \
        -e run \
        -e tmp

    # Create manifest
    dpkg-query -W --showformat='${Package} ${Version}\n' > "$ISO_DIR/casper/filesystem.manifest"
    cp "$ISO_DIR/casper/filesystem.manifest" "$ISO_DIR/casper/filesystem.manifest-desktop"

    # Create GRUB config for ISO
    cat > "$ISO_DIR/boot/grub/grub.cfg" << 'GRUB'
set default=0
set timeout=0

menuentry "ShahidOS Live" {
    search --no-floppy --fs-uuid --set=root XXXX-XXXX
    linux /casper/vmlinuz boot=casper quiet splash --
    initrd /casper/initrd
}

menuentry "ShahidOS (safe graphics)" {
    linux /casper/vmlinuz boot=casper nomodeset quiet splash --
    initrd /casper/initrd
}
GRUB

    # Create UEFI GRUB config
    cat > "$ISO_DIR/EFI/boot/grub.cfg" << 'UEFIGRUB'
set default=0
set timeout=0

menuentry "ShahidOS Live" {
    linux /casper/vmlinuz boot=casper quiet splash --
    initrd /casper/initrd
}
UEFIGRUB

    # Copy Ubuntu's EFI bootloader as base
    cp "$WORK_DIR/squashfs/boot/grub/x86_64-efi/"*.mod "$ISO_DIR/boot/grub/x86_64-efi/" 2>/dev/null || true

    # Build ISO with xorriso
    log "Building final ISO..."
    xorriso \
        -as mkisofs \
        -R \
        -V "ShahidOS" \
        -o "$BUILD_DIR/ShahidOS-$VERSION-amd64.iso" \
        -b boot/grub/i386-pc/eltorito.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --uefi-targ="on" \
        --efi-boot-image "casper/efi.img" \
        -append_partition 2 0xef $ISO_DIR/EFI \
        -eltorito-alt-boot \
        -e EFI/EFI_BOOT/bootx64.efi \
        -no-emul-boot \
        . 2>/dev/null || true

    success "ISO created: $BUILD_DIR/ShahidOS-$VERSION-amd64.iso"
}

# Test with QEMU
test_qemu() {
    log "Testing ISO with QEMU..."
    if command -v qemu-system-x86_64 &> /dev/null; then
        qemu-system-x86_64 \
            -m 4G \
            -smp 4 \
            -cdrom "$BUILD_DIR/ShahidOS-$VERSION-amd64.iso" \
            -boot d \
            -nic user \
            -display gtk 2>&1 &
        success "QEMU started. Close window to exit."
    else
        apt install -y qemu-system-x86
        test_qemu
    fi
}

# Main
main() {
    mkdir -p "$BUILD_DIR" "$WORK_DIR" "$ISO_DIR"
    
    install_deps
    download_iso
    extract_iso
    customize_system
    create_iso
    
    success "ShahidOS build complete!"
    success "Output: $BUILD_DIR/ShahidOS-$VERSION-amd64.iso"
    
    read -p "Test with QEMU? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        test_qemu
    fi
}

main "$@"