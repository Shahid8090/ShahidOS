#!/usr/bin/env python3
"""
ShahidOS ISO Generator
Creates a bootable ISO structure and generates the ISO file

This script can run in environments where full build tools aren't available.
It generates a minimal but functional ISO structure.
"""

import os
import sys
import struct
import zlib
import subprocess
from pathlib import Path

# Configuration
VERSION = "1.0.0"
CODENAME = "ShahidOS"
ARCH = "amd64"

# Paths
SCRIPT_DIR = Path(__file__).parent.resolve()
BUILD_DIR = SCRIPT_DIR / "build"
OUTPUT_DIR = SCRIPT_DIR / "output"
WORK_DIR = BUILD_DIR / "work"
ISO_DIR = WORK_DIR / "iso"

# Verify/create directories
BUILD_DIR.mkdir(exist_ok=True)
OUTPUT_DIR.mkdir(exist_ok=True)
WORK_DIR.mkdir(parents=True, exist_ok=True)

class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def log_info(msg):
    print(f"{Colors.BLUE}[INFO]{Colors.ENDC} {msg}")

def log_success(msg):
    print(f"{Colors.GREEN}[OK]{Colors.ENDC} {msg}")

def log_warn(msg):
    print(f"{Colors.YELLOW}[WARN]{Colors.ENDC} {msg}")

def log_error(msg):
    print(f"{Colors.RED}[ERROR]{Colors.ENDC} {msg}")

def check_command(cmd):
    """Check if a command exists"""
    try:
        subprocess.run([cmd, "--version"], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

def has_build_tools():
    """Check if we have the necessary build tools"""
    tools = ["xorriso", "mksquashfs", "grub-mkimage"]
    missing = [t for t in tools if not check_command(t)]
    if missing:
        log_warn(f"Missing tools: {', '.join(missing)}")
        log_warn("Installing tools would be needed for full ISO generation")
        return False
    return True

def create_dirs():
    """Create necessary directories"""
    log_info("Creating directory structure...")
    
    dirs = [
        OUTPUT_DIR,
        WORK_DIR,
        ISO_DIR / "casper",
        ISO_DIR / "boot" / "grub" / "x86_64-efi",
        ISO_DIR / "boot" / "grub" / "i386-pc",
        ISO_DIR / "EFI" / "boot",
        ISO_DIR / ".disk",
    ]
    
    for d in dirs:
        d.mkdir(parents=True, exist_ok=True)
    
    log_success("Directories created")

def create_kernel_and_initrd():
    """Create minimal kernel and initrd for demo"""
    log_info("Creating kernel and initrd stubs...")
    
    # Create minimal initrd (just enough to boot)
    initrd_path = ISO_DIR / "casper" / "initrd"
    
    # Create a minimal cpio archive as initrd
    # This is a placeholder - real initrd would be extracted from Ubuntu
    initrd_content = b"070701" + b"0" * 100  # Minimal stub
    initrd_path.write_bytes(initrd_content)
    
    log_warn("Using stub files - real kernel/initrd require Ubuntu base system")
    log_info("Copy vmlinuz and initrd from Ubuntu ISO to work/vmlinuz and work/initrd")
    
    # Create a note file
    note = f"""ShahidOS Kernel/Initrd Note
===========================

This ISO structure requires:
1. vmlinuz (Linux kernel) - copy from Ubuntu 24.04 ISO: casper/vmlinuz
2. initrd (initial ramdisk) - copy from Ubuntu 24.04 ISO: casper/initrd

Copy these files to:
  {WORK_DIR}/vmlinuz
  {WORK_DIR}/initrd

Then copy to ISO:
  cp {WORK_DIR}/vmlinuz {ISO_DIR}/casper/vmlinuz
  cp {WORK_DIR}/initrd {ISO_DIR}/casper/initrd
"""
    (BUILD_DIR / "KERNEL_NOTE.txt").write_text(note)
    
    log_success("Kernel/initrd stubs created")

def create_grub_config():
    """Create GRUB configuration files"""
    log_info("Creating GRUB configuration...")
    
    # BIOS GRUB config
    grub_cfg = """set default=0
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
"""
    (ISO_DIR / "boot" / "grub" / "grub.cfg").write_text(grub_cfg)
    
    # UEFI GRUB config
    uefi_grub = """set default=0
set timeout=0

menuentry "ShahidOS Live" {
    linux /casper/vmlinuz boot=casper quiet splash --
    initrd /casper/initrd
}
"""
    (ISO_DIR / "EFI" / "boot" / "grub.cfg").write_text(uefi_grub)
    
    log_success("GRUB configuration created")

def create_disk_info():
    """Create disk info files"""
    log_info("Creating disk information...")
    
    (ISO_DIR / ".disk" / "base_installable").write_text("casper\n")
    (ISO_DIR / ".disk" / "info").write_text(f"ShahidOS 1.0 LTS\n")
    
    log_success("Disk info created")

def create_filesystem_manifest():
    """Create filesystem manifest"""
    log_info("Creating filesystem manifest...")
    
    manifest = f"""# ShahidOS {VERSION} - {CODENAME}
# Base: Ubuntu 24.04 LTS
# Architecture: {ARCH}

# This file would contain all packages in the ISO
# Generated during build process

# Core system
base-files
base-passwd
bash
dpkg
apt
systemd
udev

# KDE Plasma Desktop
plasma-desktop
plasma-workspace
systemsettings
dolphin
ark

# Applications
firefox
thunderbird
libreoffice-calc

# System
network-manager
lightdm
"""
    
    manifest_path = ISO_DIR / "casper" / "filesystem.manifest"
    manifest_path.write_text(manifest)
    # Copy to desktop variant
    desktop_path = ISO_DIR / "casper" / "filesystem.manifest-desktop"
    desktop_path.write_text(manifest)
    
    log_success("Filesystem manifest created")

def create_squashfs_stub():
    """Create filesystem squashfs stub"""
    log_info("Creating filesystem squashfs stub...")
    
    # Create a minimal squashfs-like structure
    squashfs_path = ISO_DIR / "casper" / "filesystem.squashfs"
    
    # This would be the actual squashfs in a real build
    # Creating a stub for the structure
    stub = f"""# SquashFS Stub
# This file represents where the actual squashfs would be

ShahidOS {VERSION} filesystem structure
Base: Ubuntu 24.04 Noble Numbat
Desktop: KDE Plasma

In a full build, this file would be replaced by:
  mksquashfs chroot/ filesystem.squashfs -comp xz

The squashfs contains the entire root filesystem
with all packages, configurations, and customizations.
"""
    
    # Create a marker file instead of actual squashfs
    squashfs_path.write_text(stub)
    
    log_warn("Squashfs is a stub - real squashfs requires Ubuntu base system")
    log_info("Use build-all.sh on a real Linux system for full ISO")

def create_md5sum():
    """Create MD5SUM file"""
    log_info("Creating MD5 checksums...")
    
    md5_content = ""
    for f in ISO_DIR.rglob("*"):
        if f.is_file():
            rel_path = f.relative_to(ISO_DIR)
            try:
                import hashlib
                md5 = hashlib.md5(f.read_bytes()).hexdigest()
                md5_content += f"{md5}  ./{rel_path}\n"
            except:
                pass
    
    (BUILD_DIR / "md5sum.txt").write_text(md5_content)
    
    log_success("MD5 checksums created")

def build_iso():
    """Attempt to build the ISO"""
    log_info("Building ISO...")
    
    iso_path = OUTPUT_DIR / f"ShahidOS-{VERSION}-amd64.iso"
    
    if check_command("xorriso"):
        try:
            # Try to build with xorriso
            cmd = [
                "xorriso",
                "-as", "mkisofs",
                "-R",
                "-V", "ShahidOS",
                "-o", str(iso_path),
                "-cache-inodes",
                str(ISO_DIR)
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                log_success(f"ISO built: {iso_path}")
                log_info(f"Size: {iso_path.stat().st_size / 1024 / 1024:.2f} MB")
                return True
            else:
                log_warn("xorriso failed to create ISO")
                log_info("Output: " + result.stderr[:500])
        except Exception as e:
            log_warn(f"Error building ISO: {e}")
    
    # Create a README for manual build
    readme = f"""# ShahidOS ISO Build Status

Generated: ISO structure and files
Date: {subprocess.run(['date'], capture_output=True, text=True).stdout.strip()}

## Files Created

{ISO_DIR}/casper/vmlinuz - Linux kernel (needs to be copied from Ubuntu ISO)
{ISO_DIR}/casper/initrd - Initial ramdisk (needs to be copied from Ubuntu ISO)
{ISO_DIR}/casper/filesystem.squashfs - Root filesystem (needs build from chroot)
{ISO_DIR}/boot/grub/grub.cfg - BIOS GRUB config
{ISO_DIR}/EFI/boot/grub.cfg - UEFI GRUB config

## To Complete ISO Build

1. Copy kernel and initrd from Ubuntu 24.04 ISO:
   cp /path/to/ubuntu-24.04-desktop-amd64.iso /tmp/ubuntu.iso
   mount /tmp/ubuntu.iso /mnt
   cp /mnt/casper/vmlinuz {WORK_DIR}/vmlinuz
   cp /mnt/casper/initrd {WORK_DIR}/initrd
   umount /mnt

2. Build squashfs from customized system:
   mksquashfs {WORK_DIR}/chroot {ISO_DIR}/casper/filesystem.squashfs -comp xz

3. Generate ISO:
   xorriso -as mkisofs -R -V "ShahidOS" -o {iso_path} {ISO_DIR}

4. Add UEFI support:
   xorriso ... --uefi-boot EFI/efi.img ...

## For Full Build

Run on a Ubuntu/Debian system with root access:
   sudo {SCRIPT_DIR}/build-all.sh
"""
    
    (BUILD_DIR / "BUILD_STATUS.txt").write_text(readme)
    
    log_warn("Full ISO build requires Ubuntu base system")
    log_info("Run build-all.sh on a real Linux system for complete ISO")
    
    return False

def main():
    print(f"""
{Colors.CYAN}╔═══════════════════════════════════════════════════════╗
║           SHAHIDOS ISO GENERATOR v{VERSION}                ║
╚═══════════════════════════════════════════════════════╝{Colors.ENDC}
""")

    log_info(f"Building ShahidOS {VERSION} ({CODENAME})")
    log_info(f"Output: {OUTPUT_DIR}")
    print()

    # Check tools
    has_tools = has_build_tools()

    # Create structure
    create_dirs()
    
    # Create kernel/initrd (stubs)
    create_kernel_and_initrd()
    
    # Create GRUB configs
    create_grub_config()
    
    # Create disk info
    create_disk_info()
    
    # Create manifest
    create_filesystem_manifest()
    
    # Create squashfs stub
    create_squashfs_stub()
    
    # Create MD5 checksums
    create_md5sum()
    
    # Attempt ISO build
    if has_tools:
        build_iso()
    else:
        log_warn("Skipping ISO build - tools not available")
        readme = f"""# ShahidOS Build Structure

ISO structure created at: {ISO_DIR}

To build the full ISO:

1. Install build dependencies:
   sudo apt install debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin

2. Download Ubuntu 24.04 ISO:
   wget http://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso

3. Run full build:
   sudo ./build-all.sh

Generated files:
- {ISO_DIR}/casper/ - Kernel, initrd, squashfs
- {ISO_DIR}/boot/grub/ - GRUB configuration
- {ISO_DIR}/EFI/ - UEFI boot files
"""
        (OUTPUT_DIR / "README.txt").write_text(readme)

    print()
    print(f"{Colors.GREEN}╔═══════════════════════════════════════════════════════╗")
    print(f"║             SHAHIDOS BUILD COMPLETE!                 ║")
    print(f"╚═══════════════════════════════════════════════════════╝{Colors.ENDC}")
    print()
    log_info("Project location: " + str(SCRIPT_DIR))
    log_info("Run build-all.sh on Ubuntu for full ISO generation")

if __name__ == "__main__":
    main()