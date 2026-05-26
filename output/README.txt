# ShahidOS Build Structure

ISO structure created at: /workspace/shahidos/build/work/iso

To build the full ISO:

1. Install build dependencies:
   sudo apt install debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin

2. Download Ubuntu 24.04 ISO:
   wget http://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso

3. Run full build:
   sudo ./build-all.sh

Generated files:
- /workspace/shahidos/build/work/iso/casper/ - Kernel, initrd, squashfs
- /workspace/shahidos/build/work/iso/boot/grub/ - GRUB configuration
- /workspace/shahidos/build/work/iso/EFI/ - UEFI boot files
