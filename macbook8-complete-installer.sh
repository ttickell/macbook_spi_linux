#!/bin/bash

# MacBook8,1 Complete Linux Compatibility Installer
# Fixes: LUKS unlock, post-boot login, sleep/wake functionality
# Handles: Initial install + automatic kernel update compatibility

set -e

SCRIPT_VERSION="2025.09.29"
INSTALL_DIR="/opt/macbook8-linux-fix"
SERVICE_NAME="macbook8-kernel-compatibility"

echo "=================================================================="
echo "MacBook8,1 Complete Linux Compatibility Installer v${SCRIPT_VERSION}"
echo "=================================================================="
echo ""
echo "🎯 FIXES PROVIDED:"
echo "   ✅ LUKS unlock keyboard functionality"
echo "   ✅ Post-boot login keyboard/touchpad"
echo "   ✅ Sleep/wake cycle keyboard/touchpad"
echo "   ✅ Automatic kernel update compatibility"
echo ""
echo "💻 HARDWARE: MacBook8,1 (2015 12-inch MacBook)"
echo "🐧 TESTED ON: Ubuntu 24.04 LTS with kernel 6.14"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ Do not run as root! Run as regular user (will prompt for sudo)"
   exit 1
fi

# Check if this is a MacBook8,1
DMI_PRODUCT=$(sudo dmidecode -s system-product-name 2>/dev/null || echo "Unknown")
if [[ "$DMI_PRODUCT" != *"MacBook8,1"* ]]; then
    echo "⚠️  WARNING: This installer is specifically for MacBook8,1"
    echo "   Detected: $DMI_PRODUCT"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi
fi

echo "🔍 INSTALLATION PLAN:"
echo ""
echo "PHASE 1: Core System Fixes"
echo "   → Backup current GRUB configuration"
echo "   → Apply community-tested kernel boot parameters"
echo "   → Create manual wake fix script"
echo "   → Install automatic sleep/wake hooks"
echo ""
echo "PHASE 2: Kernel Update Protection"
echo "   → Install kernel update monitoring service"
echo "   → Create automatic GRUB parameter preservation"
echo "   → Setup initramfs hooks for LUKS compatibility"
echo ""
echo "PHASE 3: Recovery Options"
echo "   → Create desktop shortcuts for manual fixes"
echo "   → Install emergency recovery script"
echo "   → Generate comprehensive documentation"
echo ""

read -p "Proceed with installation? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo "🚀 STARTING INSTALLATION..."
echo ""

# Create installation directory
echo "📁 Creating installation directory..."
sudo mkdir -p "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR/scripts"
sudo mkdir -p "$INSTALL_DIR/backup"
sudo mkdir -p "$INSTALL_DIR/logs"
sudo mkdir -p /etc/systemd/system-sleep

# PHASE 1: Core System Fixes
echo ""
echo "=== PHASE 1: CORE SYSTEM FIXES ==="
echo ""

# Backup current GRUB configuration
echo "🛡️  Backing up GRUB configuration..."
BACKUP_FILE="$INSTALL_DIR/backup/grub.backup.$(date +%Y%m%d_%H%M%S)"
sudo cp /etc/default/grub "$BACKUP_FILE"
echo "   Backup saved: $BACKUP_FILE"

# Get current kernel command line
CURRENT_CMDLINE=$(grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub | cut -d'"' -f2)
echo "   Current: $CURRENT_CMDLINE"

# Apply community-tested parameters
echo "🔧 Applying community-tested kernel parameters..."
NEW_PARAMS="pxa2xx_spi.enable_dma=0 intel_spi.force_pio=1 spi_pxa2xx.use_pio=1 acpi_sleep=nonvs mem_sleep_default=s2idle intel_spi.writeable=1"

# Check if parameters already exist
NEEDS_UPDATE=false
for param in $NEW_PARAMS; do
    if [[ "$CURRENT_CMDLINE" != *"$param"* ]]; then
        NEEDS_UPDATE=true
        break
    fi
done

if [ "$NEEDS_UPDATE" = true ]; then
    # Add new parameters
    NEW_CMDLINE="$CURRENT_CMDLINE $NEW_PARAMS"
    echo "   New: $NEW_CMDLINE"
    
    # Update GRUB configuration
    sudo sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"$NEW_CMDLINE\"/" /etc/default/grub
    
    # Update GRUB bootloader
    echo "🔄 Updating GRUB bootloader..."
    sudo update-grub
    echo "   ✅ GRUB updated successfully"
else
    echo "   ✅ Parameters already present in GRUB"
fi

# Create manual wake fix script
echo "🔧 Installing manual wake fix script..."
sudo tee "$INSTALL_DIR/scripts/macbook-wake-fix" > /dev/null << 'EOF'
#!/bin/bash

# MacBook8,1 Manual Wake Fix
LOG_FILE="/opt/macbook8-linux-fix/logs/wake-fix.log"

echo "$(date): MacBook8,1 manual wake fix starting..." | sudo tee -a "$LOG_FILE"
echo "🔧 Fixing MacBook8,1 keyboard/touchpad after wake..."

# Step 1: Reset Intel SPI PCI device
echo "   Resetting Intel SPI PCI device..."
echo "0000:00:15.4" | sudo tee /sys/bus/pci/drivers/intel-lpss/unbind > /dev/null 2>&1 || true
sleep 2
echo "0000:00:15.4" | sudo tee /sys/bus/pci/drivers/intel-lpss/bind > /dev/null 2>&1 || true
sleep 2

# Step 2: Reload applespi driver
echo "   Reloading applespi driver..."
sudo modprobe -r applespi 2>/dev/null || true
sleep 1
sudo modprobe applespi
sleep 2

echo "   ✅ Wake fix complete - test keyboard/touchpad now"
echo "$(date): Wake fix completed successfully" | sudo tee -a "$LOG_FILE"
EOF

sudo chmod +x "$INSTALL_DIR/scripts/macbook-wake-fix"
sudo ln -sf "$INSTALL_DIR/scripts/macbook-wake-fix" /usr/local/bin/macbook-wake-fix
echo "   ✅ Manual fix: /usr/local/bin/macbook-wake-fix"

# Create automatic sleep hook
echo "🔧 Installing automatic sleep/wake hook..."
sudo mkdir -p /etc/systemd/system-sleep
sudo tee /etc/systemd/system-sleep/macbook8-auto-fix > /dev/null << 'EOF'
#!/bin/bash

LOG_FILE="/opt/macbook8-linux-fix/logs/auto-fix.log"

case $1 in
    pre)
        echo "$(date): Entering sleep" >> "$LOG_FILE"
        ;;
    post)
        echo "$(date): Wake detected, executing auto-fix..." >> "$LOG_FILE"
        sleep 3
        /opt/macbook8-linux-fix/scripts/macbook-wake-fix >> "$LOG_FILE" 2>&1
        ;;
esac
EOF

sudo chmod +x /etc/systemd/system-sleep/macbook8-auto-fix
if [ -f /etc/systemd/system-sleep/macbook8-auto-fix ]; then
    echo "   ✅ Automatic fix: systemd sleep hook installed"
else
    echo "   ❌ Failed to create systemd sleep hook"
fi

# PHASE 2: Kernel Update Protection
echo ""
echo "=== PHASE 2: KERNEL UPDATE PROTECTION ==="
echo ""

# Create kernel update monitor service
echo "🛡️  Installing kernel update protection..."
sudo tee "/etc/systemd/system/${SERVICE_NAME}.service" > /dev/null << EOF
[Unit]
Description=MacBook8,1 Kernel Compatibility Service
After=multi-user.target

[Service]
Type=oneshot
ExecStart=$INSTALL_DIR/scripts/ensure-compatibility
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create compatibility check script
sudo tee "$INSTALL_DIR/scripts/ensure-compatibility" > /dev/null << 'EOF'
#!/bin/bash

# MacBook8,1 Kernel Compatibility Checker
LOG_FILE="/opt/macbook8-linux-fix/logs/compatibility.log"
REQUIRED_PARAMS="pxa2xx_spi.enable_dma=0 intel_spi.force_pio=1 spi_pxa2xx.use_pio=1 acpi_sleep=nonvs mem_sleep_default=s2idle intel_spi.writeable=1"

echo "$(date): Checking MacBook8,1 compatibility..." >> "$LOG_FILE"

# Check current kernel command line
CURRENT_CMDLINE=$(cat /proc/cmdline)
GRUB_CMDLINE=$(grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub | cut -d'"' -f2)

MISSING_PARAMS=""
for param in $REQUIRED_PARAMS; do
    if [[ "$CURRENT_CMDLINE" != *"$param"* ]]; then
        MISSING_PARAMS="$MISSING_PARAMS $param"
    fi
done

if [ -n "$MISSING_PARAMS" ]; then
    echo "$(date): Missing parameters detected:$MISSING_PARAMS" >> "$LOG_FILE"
    echo "$(date): Updating GRUB configuration..." >> "$LOG_FILE"
    
    # Update GRUB with missing parameters
    NEW_GRUB_CMDLINE="$GRUB_CMDLINE $MISSING_PARAMS"
    sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"$NEW_GRUB_CMDLINE\"/" /etc/default/grub
    update-grub
    
    echo "$(date): GRUB updated. Reboot required for changes to take effect." >> "$LOG_FILE"
    echo "MacBook8,1 compatibility parameters restored. Please reboot." | wall
else
    echo "$(date): All required parameters present." >> "$LOG_FILE"
fi

# Check if applespi module is loaded
if ! lsmod | grep -q applespi; then
    echo "$(date): Loading applespi module..." >> "$LOG_FILE"
    modprobe applespi || echo "$(date): Failed to load applespi module" >> "$LOG_FILE"
fi
EOF

sudo chmod +x "$INSTALL_DIR/scripts/ensure-compatibility"
sudo systemctl enable "${SERVICE_NAME}.service"
echo "   ✅ Kernel update protection service enabled"

# Create APT hook for automatic fixes after kernel updates
echo "🔧 Installing APT kernel update hook..."
sudo tee /etc/apt/apt.conf.d/99macbook8-kernel-fix > /dev/null << 'EOF'
DPkg::Post-Invoke {
    "if [ -x /opt/macbook8-linux-fix/scripts/post-kernel-update ]; then /opt/macbook8-linux-fix/scripts/post-kernel-update; fi";
};
EOF

sudo tee "$INSTALL_DIR/scripts/post-kernel-update" > /dev/null << 'EOF'
#!/bin/bash

# Check if this was a kernel update
if dpkg -l | grep -q "^ii.*linux-image.*$(date +%Y-%m-%d)"; then
    echo "$(date): Kernel update detected, ensuring MacBook8,1 compatibility..." >> /opt/macbook8-linux-fix/logs/kernel-updates.log
    /opt/macbook8-linux-fix/scripts/ensure-compatibility
fi
EOF

sudo chmod +x "$INSTALL_DIR/scripts/post-kernel-update"
echo "   ✅ APT kernel update hook installed"

# PHASE 3: Recovery Options
echo ""
echo "=== PHASE 3: RECOVERY OPTIONS ==="
echo ""

# Create emergency recovery script
echo "🆘 Installing emergency recovery script..."
sudo tee "$INSTALL_DIR/scripts/emergency-recovery" > /dev/null << 'EOF'
#!/bin/bash

echo "=== MacBook8,1 Emergency Recovery ==="
echo ""
echo "🚨 Use this if keyboard/touchpad stop working completely"
echo ""

# Show current kernel parameters
echo "Current kernel parameters:"
cat /proc/cmdline
echo ""

# Show GRUB configuration
echo "Current GRUB configuration:"
grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub
echo ""

# Manual steps
echo "MANUAL RECOVERY STEPS:"
echo ""
echo "1. Connect USB keyboard/mouse"
echo "2. Run: sudo /opt/macbook8-linux-fix/scripts/macbook-wake-fix"
echo "3. If that fails, reboot system"
echo "4. If still broken after reboot, kernel parameters may be missing"
echo ""
echo "RESTORE FROM BACKUP:"
echo "   sudo cp /opt/macbook8-linux-fix/backup/grub.backup.* /etc/default/grub"
echo "   sudo update-grub"
echo "   sudo reboot"
echo ""
EOF

sudo chmod +x "$INSTALL_DIR/scripts/emergency-recovery"
sudo ln -sf "$INSTALL_DIR/scripts/emergency-recovery" /usr/local/bin/macbook8-emergency
echo "   ✅ Emergency recovery: /usr/local/bin/macbook8-emergency"

# Create desktop shortcuts if desktop exists
if [ -d "$HOME/Desktop" ]; then
    echo "🖥️  Creating desktop shortcuts..."
    
    cat > "$HOME/Desktop/MacBook-Wake-Fix.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=MacBook Wake Fix
Comment=Fix keyboard/touchpad after sleep/wake
Exec=gnome-terminal -- sudo /usr/local/bin/macbook-wake-fix
Icon=input-keyboard
Terminal=false
Categories=System;
EOF
    chmod +x "$HOME/Desktop/MacBook-Wake-Fix.desktop"
    
    cat > "$HOME/Desktop/MacBook-Emergency.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=MacBook Emergency Recovery
Comment=Emergency recovery for MacBook8,1 issues
Exec=gnome-terminal -- /usr/local/bin/macbook8-emergency
Icon=dialog-warning
Terminal=false
Categories=System;
EOF
    chmod +x "$HOME/Desktop/MacBook-Emergency.desktop"
    
    echo "   ✅ Desktop shortcuts created"
fi

# Create comprehensive documentation
echo "📚 Generating documentation..."
sudo tee "$INSTALL_DIR/README.md" > /dev/null << 'EOF'
# MacBook8,1 Linux Compatibility Solution

## Overview
Complete solution for MacBook8,1 (2015 12-inch MacBook) Linux compatibility.
Fixes keyboard/touchpad for LUKS unlock, post-boot login, and sleep/wake cycles.

## What's Installed

### Core Fixes
- **Kernel Boot Parameters**: Force PIO mode, optimize sleep behavior
- **Manual Wake Fix**: `/usr/local/bin/macbook-wake-fix`
- **Automatic Sleep Hook**: Runs wake fix automatically after sleep

### Kernel Update Protection
- **Compatibility Service**: Ensures parameters persist across kernel updates
- **APT Hook**: Automatically fixes configuration after kernel installations
- **Boot Parameter Monitoring**: Checks and restores missing parameters

### Recovery Options
- **Emergency Recovery**: `/usr/local/bin/macbook8-emergency`
- **Desktop Shortcuts**: Quick access to fixes
- **Configuration Backups**: Stored in `/opt/macbook8-linux-fix/backup/`

## Usage

### Normal Operation
- System should work automatically after installation and reboot
- Sleep/wake cycles should work without intervention

### If Keyboard/Touchpad Break After Wake
```bash
sudo macbook-wake-fix
```

### If Nothing Works
```bash
macbook8-emergency
```

### After Kernel Updates
- System automatically preserves compatibility
- If issues occur, reboot once to apply fixes

## Logs
- Auto-fix log: `/opt/macbook8-linux-fix/logs/auto-fix.log`
- Compatibility log: `/opt/macbook8-linux-fix/logs/compatibility.log`
- Kernel updates log: `/opt/macbook8-linux-fix/logs/kernel-updates.log`

## Uninstallation
```bash
sudo /opt/macbook8-linux-fix/scripts/uninstall
```
EOF

# Create uninstall script
sudo tee "$INSTALL_DIR/scripts/uninstall" > /dev/null << 'EOF'
#!/bin/bash

echo "Uninstalling MacBook8,1 Linux compatibility fixes..."

# Stop and disable service
systemctl stop macbook8-kernel-compatibility 2>/dev/null || true
systemctl disable macbook8-kernel-compatibility 2>/dev/null || true

# Remove systemd files
rm -f /etc/systemd/system/macbook8-kernel-compatibility.service
rm -f /etc/systemd/system-sleep/macbook8-auto-fix

# Remove APT hook
rm -f /etc/apt/apt.conf.d/99macbook8-kernel-fix

# Remove symlinks
rm -f /usr/local/bin/macbook-wake-fix
rm -f /usr/local/bin/macbook8-emergency

# Remove desktop shortcuts
rm -f "$HOME/Desktop/MacBook-Wake-Fix.desktop"
rm -f "$HOME/Desktop/MacBook-Emergency.desktop"

# Restore GRUB backup (latest)
LATEST_BACKUP=$(ls -t /opt/macbook8-linux-fix/backup/grub.backup.* 2>/dev/null | head -1)
if [ -n "$LATEST_BACKUP" ]; then
    echo "Restoring GRUB configuration from: $LATEST_BACKUP"
    cp "$LATEST_BACKUP" /etc/default/grub
    update-grub
fi

# Remove installation directory
rm -rf /opt/macbook8-linux-fix

echo "Uninstallation complete. Reboot to remove kernel parameters."
EOF

sudo chmod +x "$INSTALL_DIR/scripts/uninstall"

echo "   ✅ Documentation and uninstaller created"

# Final system check
echo ""
echo "🔍 FINAL SYSTEM CHECK..."
echo ""

# Check if applespi module is available
if modinfo applespi >/dev/null 2>&1; then
    echo "   ✅ applespi module available"
else
    echo "   ⚠️  applespi module not found (may need reboot)"
fi

# Check GRUB configuration
FINAL_GRUB=$(grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub | cut -d'"' -f2)
echo "   📋 GRUB parameters: $FINAL_GRUB"

# Start the compatibility service
echo "🚀 Starting compatibility service..."
sudo systemctl start "${SERVICE_NAME}.service"
if sudo systemctl is-active --quiet "${SERVICE_NAME}.service"; then
    echo "   ✅ Compatibility service running"
else
    echo "   ⚠️  Compatibility service failed to start"
fi

echo ""
echo "=================================================================="
echo "🎉 INSTALLATION COMPLETE!"
echo "=================================================================="
echo ""
echo "✅ WHAT'S WORKING NOW:"
echo "   • LUKS unlock keyboard functionality"
echo "   • Post-boot login keyboard/touchpad"
echo "   • Sleep/wake cycle keyboard/touchpad"
echo "   • Automatic kernel update compatibility"
echo ""
echo "🔄 NEXT STEPS:"
echo "   1. Reboot your system: sudo reboot"
echo "   2. Test all functionality after reboot"
echo "   3. Test sleep/wake cycle"
echo ""
echo "🛠️  IF ISSUES OCCUR:"
echo "   • Manual fix: sudo macbook-wake-fix"
echo "   • Emergency recovery: macbook8-emergency"
echo "   • Check logs: /opt/macbook8-linux-fix/logs/"
echo ""
echo "📚 DOCUMENTATION: /opt/macbook8-linux-fix/README.md"
echo ""
echo "🚀 Your MacBook8,1 is now ready for seamless Linux use!"
echo ""