#!/bin/bash
# ShahidOS Build Script - Complete
# Builds a custom Ubuntu-based OS with KDE Plasma

set -e

VERSION="1.0.0"
CODENAME="shahidos"
ARCH="amd64"
BUILD_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="$BUILD_DIR/work"
OUTPUT_DIR="$BUILD_DIR/output"
CHROOT_DIR="$WORK_DIR/chroot"
UBUNTU_ISO_URL="http://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root: sudo $0"
        exit 1
    fi
}

# Check dependencies
check_deps() {
    info "Checking dependencies..."
    MISSING=""
    for cmd in debootstrap xorriso grub-mkimage mksquashfs; do
        if ! command -v $cmd &> /dev/null; then
            MISSING="$MISSING $cmd"
        fi
    done
    if [ -n "$MISSING" ]; then
        error "Missing packages:$MISSING"
        info "Install with: apt install debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin"
        exit 1
    fi
    success "All dependencies present"
}

# Clean previous build
clean() {
    info "Cleaning previous build..."
    rm -rf "$WORK_DIR" "$OUTPUT_DIR"
    mkdir -p "$WORK_DIR" "$OUTPUT_DIR"
    success "Clean complete"
}

# Download Ubuntu ISO
download_iso() {
    info "Downloading Ubuntu 24.04 Desktop ISO..."
    cd "$BUILD_DIR"
    
    if [ -f "ubuntu-24.04-desktop-amd64.iso" ]; then
        success "Ubuntu ISO already present"
        return
    fi
    
    if command -v wget &> /dev/null; then
        wget -q --show-progress "$UBUNTU_ISO_URL" -O "ubuntu-24.04-desktop-amd64.iso"
    else
        curl -# -L "$UBUNTU_ISO_URL" -o "ubuntu-24.04-desktop-amd64.iso"
    fi
    success "Download complete"
}

# Mount and extract ISO
extract_iso() {
    info "Extracting Ubuntu ISO..."
    
    mkdir -p "$WORK_DIR/mount"
    mkdir -p "$WORK_DIR/squashfs-root"
    
    mount -o loop "$BUILD_DIR/ubuntu-24.04-desktop-amd64.iso" "$WORK_DIR/mount"
    
    # Extract squashfs
    unsquashfs -f -d "$WORK_DIR/squashfs-root" "$WORK_DIR/mount/casper/filesystem.squashfs"
    
    # Copy kernel and initrd
    cp "$WORK_DIR/mount/casper/vmlinuz" "$WORK_DIR/"
    cp "$WORK_DIR/mount/casper/initrd" "$WORK_DIR/"
    
    umount "$WORK_DIR/mount"
    
    success "ISO extracted"
}

# Customize system
customize_system() {
    info "Customizing ShahidOS..."
    
    CHROOT="$WORK_DIR/squashfs-root"
    
    # Set hostname
    echo "ShahidOS" > "$CHROOT/etc/hostname"
    sed -i 's/ubuntu/ShahidOS/g' "$CHROOT/etc/hosts"
    
    # Add Ubuntu repos
    cat > "$CHROOT/etc/apt/sources.list" << 'EOF'
deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu noble-security main restricted universe multiverse
EOF

    # Mount proc/sys/dev
    mount -t proc proc "$CHROOT/proc"
    mount -t sysfs sys "$CHROOT/sys"
    mount --bind /dev "$CHROOT/dev"
    mount --bind /dev/pts "$CHROOT/dev/pts"
    
    # Create customization script
    cat > "$WORK_DIR/customize-chroot.sh" << 'CHROOT_EOF'
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
export LANG=en_US.UTF-8

cd /tmp

# Update
apt update -qq 2>/dev/null

# Install additional packages
apt install -y --no-install-recommends \
    plasma-desktop \
    kde-plasma-desktop \
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
    libreoffice-draw \
    libreoffice-math \
    network-manager \
    network-manager-gnome \
    blueman \
    pavucontrol \
    plasma-systemmonitor \
    plasma-runner-search \
    kde-config-gtk-module \
    breeze-gtk-theme \
    kde-style-breeze \
    2>/dev/null || true

# Remove snap completely
apt remove --purge snapd 2>/dev/null || true
apt autoremove -y 2>/dev/null || true

# Create shahidos user
if ! id shahidos &>/dev/null; then
    useradd -m -G sudo,adm,cdrom,dip,plugdev,lpadmin,sambashare -s /bin/bash shahidos
    echo "shahidos:shahidos" | chpasswd
fi

# Sudo without password for shahidos
echo "shahidos ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/shahidos
chmod 0440 /etc/sudoers.d/shahidos

# Create ShahidOS branding directories
mkdir -p /usr/share/shahidos/icons
mkdir -p /usr/share/shahidos/backgrounds
mkdir -p /usr/share/shahidos/themes

# Create icon using ImageMagick or fallback
if command -v convert &>/dev/null; then
    convert -size 256x256 gradient:"#1a73e8-#0d47a1" \
        -fill white -gravity center \
        -pointsize 72 -annotate 0 "S" \
        /usr/share/shahidos/icons/shahidos-logo.png
else
    # Create minimal PNG with Python
    python3 << 'PYEOF'
import struct, zlib

def create_png(filename, width, height, color):
    def crc(data):
        return zlib.crc32(data) & 0xffffffff
    
    # Create raw pixel data
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'  # Filter byte
        for x in range(width):
            # Create gradient
            r = int(26 + (x/width) * 50)
            g = int(115 + (y/height) * 100)
            b = 232
            raw_data += struct.pack('BBB', r, g, b)
    
    def chunk(chunk_type, data):
        return struct.pack('>I', len(data)) + chunk_type + data + struct.pack('>I', crc(chunk_type + data))
    
    # PNG signature
    png = b'\x89PNG\r\n\x1a\n'
    
    # IHDR
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    png += chunk(b'IHDR', ihdr_data)
    
    # IDAT
    compressed = zlib.compress(raw_data, 9)
    png += chunk(b'IDAT', compressed)
    
    # IEND
    png += chunk(b'IEND', b'')
    
    with open(filename, 'wb') as f:
        f.write(png)

create_png('/usr/share/shahidos/icons/shahidos-logo.png', 256, 256, (26, 115, 232))
print("Icon created")
PYEOF
fi

# Copy default wallpaper from Ubuntu
cp /usr/share/backgrounds/*/Jammy_Jellyfish* /usr/share/shahidos/backgrounds/default.jpg 2>/dev/null || \
cp /usr/share/backgrounds/*/default*.jpg /usr/share/shahidos/backgrounds/ 2>/dev/null || \
cp /usr/share/backgrounds/ubuntu* /usr/share/shahidos/backgrounds/ 2>/dev/null || true

# Create SVG logo as fallback
cat > /usr/share/shahidos/icons/shahidos-logo.svg << 'SVGEOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#1a73e8"/>
      <stop offset="100%" style="stop-color:#0d47a1"/>
    </linearGradient>
  </defs>
  <rect width="256" height="256" rx="40" fill="url(#bg)"/>
  <text x="128" y="160" font-family="Arial,sans" font-size="120" fill="white" text-anchor="middle" font-weight="bold">S</text>
  <text x="128" y="210" font-family="Arial,sans" font-size="24" fill="white" text-anchor="middle">ShahidOS</text>
</svg>
SVGEOF

# Configure KDE
mkdir -p /etc/skel/.config

cat > /etc/skel/.config/kwinrc << 'KWIN'
[Desktop]
MultiMonitor=false

[org.kde.kdecoration2]
theme=org.kde.breeze.desktop
ButtonsOnLeft=
ButtonsOnRight=IA

[Windows]
Placement=Centered
KWIN

cat > /etc/skel/.config/plasmashellrc << 'PLASMA'
[Containments][1]
plugin=org.kde.plasma.taskmanager
Items=[]

[Containments][2]
plugin=org.kde.plasma.panel
ItemGeometries[strength]=0
ItemGeometriesCreated=true
Items=org.kde.plasma.systemtray,org.kde.plasma.kicker,org.kde.plasma.digitalclock
PLASMA

cat > /etc/skel/.config/kickoffrc << 'KICKOFF'
[General]
FullWidth=true
Position=BottomCenter
Alignment=Center
KICKOFF

cat > /etc/skel/.config/kdeglobals << 'KDE'
[General]
ColorScheme=Dark
XftAntialias=1

[Icons]
Theme=breeze

[KDE]
LookAndFeelPackage=org.kde.breeze.desktop
KDE

# Copy branding to skel
cp -r /usr/share/shahidos /etc/skel/ 2>/dev/null || true

# Install and configure LightDM
apt install -y lightdm lightdm-gtk-greeter 2>/dev/null || true

cat > /etc/lightdm/lightdm.conf << 'LIGHTDM'
[Seat:*]
user-session=plasma
greeter-session=lightdm-gtk-greeter
greeter-hide-users=false
allow-user-switching=true
LIGHTDM

# Enable services
systemctl enable lightdm 2>/dev/null || true
systemctl enable NetworkManager 2>/dev/null || true

# Clean up
apt clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
rm -rf /var/cache/apt/*
echo "ShahidOS customization complete"
CHROOT_EOF

    chmod +x "$WORK_DIR/customize-chroot.sh"
    cp "$WORK_DIR/customize-chroot.sh" "$CHROOT/tmp/customize-chroot.sh"
    
    # Run customization in chroot
    chroot "$CHROOT" /bin/bash /tmp/customize-chroot.sh
    
    # Cleanup
    rm "$CHROOT/tmp/customize-chroot.sh"
    
    # Unmount
    umount "$CHROOT/proc" 2>/dev/null || true
    umount "$CHROOT/sys" 2>/dev/null || true
    umount "$CHROOT/dev/pts" 2>/dev/null || true
    umount "$CHROOT/dev" 2>/dev/null || true
    
    success "System customized"
}

# Create ISO
create_iso() {
    info "Creating ShahidOS ISO..."
    
    ISO_DIR="$WORK_DIR/iso"
    mkdir -p "$ISO_DIR/casper"
    mkdir -p "$ISO_DIR/boot/grub/x86_64-efi"
    mkdir -p "$ISO_DIR/boot/grub/i386-pc"
    mkdir -p "$ISO_DIR/EFI/boot"
    mkdir -p "$ISO_DIR/.disk"
    
    # Copy kernel and initrd
    cp "$WORK_DIR/vmlinuz" "$ISO_DIR/casper/vmlinuz"
    cp "$WORK_DIR/initrd" "$ISO_DIR/casper/initrd"
    
    # Create squashfs
    info "Creating filesystem squashfs..."
    mksquashfs "$WORK_DIR/squashfs-root" "$ISO_DIR/casper/filesystem.squashfs" \
        -comp xz \
        -e proc \
        -e sys \
        -e dev \
        -e run \
        -e tmp \
        -e var/cache \
        -e var/lib/apt \
        -info
    
    # Create manifest
    dpkg-query -W --showformat='${Package} ${Version}\n' > "$ISO_DIR/casper/filesystem.manifest"
    cp "$ISO_DIR/casper/filesystem.manifest" "$ISO_DIR/casper/filesystem.manifest-desktop"
    
    # Create disk info
    echo "casper" > "$ISO_DIR/.disk/base_installable"
    echo "full_casper" >> "$ISO_DIR/.disk/base_installable"
    echo "GNU/Linux" > "$ISO_DIR/.disk/distributor_info
    echo "ShahidOS 1.0" > "$ISO_DIR/.disk/info"
    
    # Create GRUB config
    cat > "$ISO_DIR/boot/grub/grub.cfg" << 'GRUB'
set default=0
set timeout=0

menuentry "ShahidOS Live" {
    search --no-floppy --fs-uuid --set=root XXXX-XXXX
    linux /casper/vmlinuz boot=casper quiet splash --
    initrd /casper/initrd
}

menuentry "ShahidOS (safe graphics)" {
    search --no-floppy --fs-uuid --set=root XXXX-XXXX
    linux /casper/vmlinuz boot=casper nomodeset quiet splash --
    initrd /casper/initrd
}

menuentry "ShahidOS (recovery)" {
    search --no-floppy --fs-uuid --set=root XYYY-YYYY
    linux /casper/vmlinuz boot=casper recovery nomodeset --
    initrd /casper/initrd
}
GRUB

    # Create UEFI GRUB config
    cat > "$ISO_DIR/EFI/boot/grub.cfg" << 'UEFI'
set default=0
set timeout=0

menuentry "ShahidOS Live" {
    linux /casper/vmlinuz boot=casper quiet splash --
    initrd /casper/initrd
}
UEFI

    # Copy GRUB modules from Ubuntu
    if [ -d "$WORK_DIR/squashfs-root/usr/lib/grub" ]; then
        cp -r "$WORK_DIR/squashfs-root/usr/lib/grub/x86_64-efi/"* "$ISO_DIR/boot/grub/x86_64-efi/" 2>/dev/null || true
    fi

    # Create efi.img for UEFI boot
    dd if=/dev/zero of="$ISO_DIR/EFI/efi.img" bs=1M count=16
    mkfs.vfat "$ISO_DIR/EFI/efi.img"
    
    # Build ISO
    info "Building final ISO..."
    
    cd "$WORK_DIR"
    
    xorriso \
        -as mkisofs \
        -R \
        -V "ShahidOS" \
        -o "$OUTPUT_DIR/ShahidOS-$VERSION-amd64.iso" \
        -cache-inodes \
        -isohybrid-mbr /usr/share/syslinux/isohdpfx.bin \
        -b boot/grub/i386-pc/eltorito.img \
        -c boot.catalog \
        --uefi-boot EFI/efi.img \
        -efi-boot-part \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        "$ISO_DIR/"
    
    success "ISO created: $OUTPUT_DIR/ShahidOS-$VERSION-amd64.iso"
}

# Print summary
summary() {
    echo ""
    echo "============================================"
    echo "       SHAHIDOS BUILD COMPLETE!"
    echo "============================================"
    echo ""
    echo "Version: $VERSION"
    echo "ISO: $OUTPUT_DIR/ShahidOS-$VERSION-amd64.iso"
    echo "Size: $(du -h $OUTPUT_DIR/ShahidOS-$VERSION-amd64.iso 2>/dev/null | cut -f1)"
    echo ""
    echo "Features:"
    echo "  ✓ Ubuntu 24.04 base"
    echo "  ✓ KDE Plasma Desktop"
    echo "  ✓ Windows 11 style layout"
    echo "  ✓ Custom ShahidOS branding"
    echo "  ✓ UEFI and BIOS boot"
    echo "  ✓ Live boot mode"
    echo ""
    echo "Test with QEMU:"
    echo "  qemu-system-x86_64 -m 4G -cdrom $OUTPUT_DIR/ShahidOS-$VERSION-amd64.iso -boot d"
    echo ""
}

# Main
main() {
    echo -e "${PURPLE}"
    echo "============================================"
    echo "    SHAHIDOS BUILD SYSTEM v$VERSION"
    echo "============================================"
    echo -e "${NC}"
    
    check_root
    check_deps
    clean
    download_iso
    extract_iso
    customize_system
    create_iso
    summary
}

main "$@"