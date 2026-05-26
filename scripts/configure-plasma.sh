#!/bin/bash
# Kubectl Configuration Script for ShahidOS
# Applies KDE Plasma customizations after base system is set up

set -e

CHROOT_DIR="${1:-/workspace/shahidos/chroot}"

echo "[ShahidOS] Configuring KDE Plasma..."

# Set up default plasma config
mkdir -p "$CHROOT_DIR/etc/skel/.config"
mkdir -p "$CHROOT_DIR/etc/skel/.local/share"
mkdir -p "$CHROOT_DIR/home/shahidos/.config"
mkdir -p "$CHROOT_DIR/home/shahidos/.local/share"

# Taskbar / Panel configuration (Windows 11 style)
cat > "$CHROOT_DIR/etc/skel/.config/plasmashellrc" << 'PLASMA'
[Containments][1]
plugin=org.kde.plasma.taskmanager
[Containments][2]
plugin=org.kde.plasma.panel
ItemAllocation=0
Items=org.kde.plasma.systemtray,org.kde.plasma.kicker,org.kde.plasma.clock
PLASMA

# Desktop layout configuration (Windows 11 style with centered taskbar)
cat > "$CHROOT_DIR/etc/skel/.config/kwinrc" << 'KWIN'
[Desktop]
MultiMonitor=false

[org.kde.kdecoration2]
theme=Breeze-ShahidOS
ButtonsOnLeft=
ButtonsOnRight=IA

[TabBox]
LayoutName=org.kde.tabbox.windows

[Windows]
Placement=Centered
FocusPolicy=ClickToRaise

[KDE]
SingleProcess=false
KDECompat=false
KWIN
# Menu / Kickoff configuration
cat > "$CHROOT_DIR/etc/skel/.config/kickoffrc" << 'KICKOFF'
[General]
UseButtonColors=true
ButtonColor=#1a73e8
ButtonTextColor=#ffffff
Position=BottomCenter
Alignment=Center
FullWidth=true
FullHeight=false
KICKOFF

# System tray configuration
cat > "$CHROOT_DIR/etc/skel/.config/plasma-systemtrayrc" << 'SYSTRAY'
[Configuration]
PluginsStarted=org.kde.plasma.networkmanagement,org.kde.plasma.bluetooth,org.kde.plasma.volume,org.kde.thermal,org.kde.battery
SYSTRAY

# Plasma workspace settings
cat > "$CHROOT_DIR/etc/skel/.config/plasmarc" << 'PLASMAWS'
[Desktop]
ShowDesktopWidget=false

[Plasma]
ShowWelcomeWidget=false
PLASMAWS

# GTK/Qt theme configuration
cat > "$CHROOT_DIR/etc/skel/.config/kdeglobals" << 'KDEGLOBAL'
[General]
ColorScheme=ShahidOSDark
XftAntialias=1
XftHintStyle=hintslight
XftSubPixel=none

[Icons]
Theme=breeze-shahidos

[KDE]
LookAndFeelPackage=org.kde.shahidOS.desktop

[SettingsWindow]
FontForceDPI=0
FontSize=10

[Toolbar]
ToolButtonStyle=ToolButtonFollowStyle

[KFileDialog]
Recent URLs[$e]=

[KDE]
SingleProcess=false
KDEGLOBAL

# Application launcher settings
cat > "$CHROOT_DIR/etc/skel/.config/kglobalshortcutsrc" << 'GLOBALSHORT'
[Global Shortcuts]
krunner=Alt+Space
kwin-toggle-maximize=Meta+Up
kwin-tile-top=Meta+Up
kwin-tile-bottom=Meta+Down
kwin-tile-left=Meta+Left
kwin-tile-right=Meta+Right
plasma-show-desktop=Meta+D
GLOBALSHORT

# Cursor settings
cat > "$CHROOT_DIR/etc/skel/.config/kcminputrc" << 'INPUT'
[Mouse]
cursorTheme=breeze_shahidos_cursors
cursorSize=24
INPUT

# Font configuration
cat > "$CHROOT_DIR/etc/skel/.config/fontinst.ini" << 'FONT'
[Fallback]
Sans=/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf
Serif=/usr/share/fonts/truetype/noto/NotoSerif-Regular.ttf
Mono=/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf
FONT

# NetworkManager configuration
mkdir -p "$CHROOT_DIR/etc/NetworkManager/system-connections"
cat > "$CHROOT_DIR/etc/NetworkManager/NetworkManager.conf" << 'NM'
[main]
plugins=ifupdown,keyfile
dns=default

[ifupdown]
managed=false

[device]
wifi.scan-rand-mac-address=no
NM

# Bluetooth configuration
mkdir -p "$CHROOT_DIR/etc/bluetooth"
cat > "$CHROOT_DIR/etc/bluetooth/main.conf" << 'BT'
[General]
Enable=Source,Sink,Media,RemoteEndpoint
ControllerMode=dual
Name=ShahidOS
Class=0x000000
Discoverable=true
Pairable=true
BT

# Audio/PulseAudio configuration
mkdir -p "$CHROOT_DIR/etc/pulse"
cat > "$CHROOT_DIR/etc/pulse/daemon.conf" << 'PULSE'
daemon.conf = false
default-script = /etc/pulse/default.pa
system-instance = no
local-server-type = user
PULSE

echo "[ShahidOS] KDE Plasma configuration complete"