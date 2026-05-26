#!/bin/bash
# ShahidOS QEMU Test Script
# Tests the built ISO in a virtual machine

ISO_PATH="${1:-/workspace/shahidos/output/ShahidOS-1.0.0-amd64.iso}"
RAM="${2:-4096}"
CORES="${3:-4}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }

if [ ! -f "$ISO_PATH" ]; then
    echo "ISO not found: $ISO_PATH"
    echo "Build it first with: ./build-all.sh"
    exit 1
fi

info "Testing ShahidOS ISO..."
info "ISO: $ISO_PATH"
info "RAM: ${RAM}MB, Cores: $CORES"
echo ""

# Check if KVM is available
if [ -e /dev/kvm ]; then
    info "KVM acceleration available!"
    KVM_FLAG="-enable-kvm"
else
    info "KVM not available, using software emulation"
    KVM_FLAG=""
fi

# Launch QEMU
qemu-system-x86_64 \
    $KVM_FLAG \
    -m "$RAM" \
    -smp "$CORES" \
    -cdrom "$ISO_PATH" \
    -boot d \
    -nic user \
    -display gtk \
    -soundhw hda \
    -device virtio-mouse-pci \
    -device virtio-keyboard-pci

echo ""
info "QEMU session ended"