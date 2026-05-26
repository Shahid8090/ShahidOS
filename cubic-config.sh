#!/bin/bash
# ShahidOS Cubic Configuration File
# For use with Cubic (Custom Ubuntu ISO Creator)

# Cubic project directory
PROJECT_DIR="$1"

if [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR="/tmp/shahidos-cubic"
fi

mkdir -p "$PROJECT_DIR"

# Set version
export CUSTOM_VERSION="1.0.0"
export CUSTOM_CODENAME="ShahidOS"
export DISTRIBUTION="noble"

# Source ISO
SOURCE_ISO="$2"
if [ -z "$SOURCE_ISO" ]; then
    SOURCE_ISO="/tmp/ubuntu-24.04-desktop-amd64.iso"
fi

# Packages to add
ADD_PACKAGES=(
    "plasma-desktop"
    "systemsettings"
    "dolphin"
    "ark"
    "konsole"
    "kate"
    "firefox"
    "thunderbird"
    "libreoffice-calc"
    "libreoffice-writer"
    "libreoffice-impress"
    "network-manager"
    "network-manager-gnome"
    "blueman"
    "pavucontrol"
    "plasma-systemmonitor"
    "breeze-gtk-theme"
    "kde-config-gtk-module"
    "lightdm"
    "lightdm-gtk-greeter"
)

# Packages to remove
REMOVE_PACKAGES=(
    "snapd"
    "gnome-software"
    "libreoffice-gnome"
    "libreoffice-gtk"
)

# Post-install script
cat > "$PROJECT_DIR/custom-post-install.sh" << 'POSTINSTALL'
#!/bin/bash
set -e

echo "[ShahidOS] Post-install customization..."

# Set hostname
echo "ShahidOS" > /etc/hostname
sed -i 's/ubuntu/ShahidOS/g' /etc/hosts

# Create user
if ! id shahidos &>/dev/null; then
    useradd -m -G sudo,adm,cdrom,dip,plugdev,lpadmin,sambashare -s /bin/bash shahidos
    echo "shahidos:shahidos" | chpasswd
fi

# Configure sudo
echo "shahidos ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/shahidos
chmod 0440 /etc/sudoers.d/shahidos

# Create branding
mkdir -p /usr/share/shahidos/icons
mkdir -p /usr/share/shahidos/backgrounds

# Create simple icon
python3 << 'EOF'
import struct, zlib

def create_png(filename, width, height):
    def crc(data):
        return zlib.crc32(data) & 0xffffffff
    
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'
        for x in range(width):
            r = int(26 + (x/width) * 50)
            g = int(115 + (y/height) * 100)
            b = 232
            raw_data += struct.pack('BBB', r, g, b)
    
    def chunk(chunk_type, data):
        return struct.pack('>I', len(data)) + chunk_type + data + struct.pack('>I', crc(chunk_type + data))
    
    png = b'\x89PNG\r\n\x1a\n'
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    png += chunk(b'IHDR', ihdr_data)
    compressed = zlib.compress(raw_data, 9)
    png += chunk(b'IDAT', compressed)
    png += chunk(b'IEND', b'')
    
    with open(filename, 'wb') as f:
        f.write(png)

create_png('/usr/share/shahidos/icons/shahidos-logo.png', 256, 256)
print("Icon created")
EOF

# Configure LightDM
cat > /etc/lightdm/lightdm.conf << 'LIGHTDM'
[Seat:*]
user-session=plasma
greeter-session=lightdm-gtk-greeter
greeter-hide-users=false
LIGHTDM

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
[Containments][2]
plugin=org.kde.plasma.panel
PLASMA

# Enable services
systemctl enable lightdm 2>/dev/null || true
systemctl enable NetworkManager 2>/dev/null || true

echo "[ShahidOS] Post-install complete!"
POSTINSTALL

chmod +x "$PROJECT_DIR/custom-post-install.sh"

# Theme configuration
cat > "$PROJECT_DIR/custom-theme-config.sh" << 'THEME'
#!/bin/bash
set -e

# Set dark theme
mkdir -p /etc/skel/.config

cat > /etc/skel/.config/kdeglobals << 'KDE'
[General]
ColorScheme=Dark
XftAntialias=1

[Icons]
Theme=breeze

[KDE]
LookAndFeelPackage=org.kde.breeze.desktop
KDE

# Taskbar configuration
cat > /etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc << 'TASKBAR'
[ActionPlugins][0]
MidButton;SecondaryClient;Primary
LeftButton;NoModifier;NewInstance
MiddleButton;NoModifier;NewInstance

[Containments][2]
plugin=org.kde.plasma.panel

[Containments][2][Configuration]
PreloadWeight=60

[Containments][2][Applets][StatusNotifierItem]
plugin=org.kde.plasma.systemtray

[Containments][2][Applets][kicker]
plugin=org.kde.plasma.kicker

[Containments][2][Applets][digitalclock]
plugin=org.kde.plasma.digitalclock
TASKBAR

echo "[ShahidOS] Theme configured!"
THEME

chmod +x "$PROJECT_DIR/custom-theme-config.sh"

echo "Cubic configuration created at: $PROJECT_DIR"