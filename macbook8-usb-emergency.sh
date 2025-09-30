#!/bin/bash

# MacBook8,1 USB Emergency Recovery Script
# Use this with USB keyboard/mouse when main keyboard is broken
# Minimal script to restore functionality after kernel updates

SCRIPT_VERSION="2025.09.29"

echo "=================================================================="
echo "MacBook8,1 USB Emergency Recovery v${SCRIPT_VERSION}"
echo "=================================================================="
echo ""
echo "🚨 EMERGENCY RECOVERY MODE"
echo "   Use this script when keyboard/touchpad stop working"
echo "   Requires USB keyboard/mouse to run"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ Do not run as root! Run as regular user (will prompt for sudo)"
   exit 1
fi

# Verify USB keyboard is working
echo "🔍 USB Keyboard Test:"
echo "   Type 'yes' and press Enter to continue..."
read -p "   Input: " response
if [[ "$response" != "yes" ]]; then
    echo "❌ USB keyboard not working or user cancelled"
    exit 1
fi

echo ""
echo "🔧 APPLYING EMERGENCY FIXES..."
echo ""

# 1. Immediate manual wake fix (if previous installation exists)
if [ -x "/usr/local/bin/macbook-wake-fix" ]; then
    echo "📱 Running existing wake fix..."
    sudo /usr/local/bin/macbook-wake-fix
    
    echo ""
    echo "🧪 Test built-in keyboard now:"
    echo "   Try typing on the MacBook keyboard..."
    read -p "   Does built-in keyboard work? (y/n): " kb_test
    
    if [[ "$kb_test" =~ ^[Yy]$ ]]; then
        echo "✅ Built-in keyboard working! Emergency recovery complete."
        exit 0
    fi
    
    echo "❌ Built-in keyboard still broken, continuing with full fix..."
    echo ""
else
    echo "⚠️  No previous installation found, applying fresh fixes..."
    echo ""
fi

# 2. Backup current GRUB configuration
echo "🛡️  Backing up GRUB configuration..."
sudo cp /etc/default/grub /etc/default/grub.emergency.backup.$(date +%Y%m%d_%H%M%S)

# 3. Apply kernel parameters
echo "🔧 Applying MacBook8,1 kernel parameters..."

# Get current parameters
CURRENT_CMDLINE=$(grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub | cut -d'"' -f2)
echo "   Current: $CURRENT_CMDLINE"

# Required parameters for MacBook8,1
REQUIRED_PARAMS="pxa2xx_spi.enable_dma=0 intel_spi.force_pio=1 spi_pxa2xx.use_pio=1 acpi_sleep=nonvs mem_sleep_default=s2idle intel_spi.writeable=1"

# Check which parameters are missing
MISSING_PARAMS=""
for param in $REQUIRED_PARAMS; do
    if [[ "$CURRENT_CMDLINE" != *"$param"* ]]; then
        MISSING_PARAMS="$MISSING_PARAMS $param"
    fi
done

if [ -n "$MISSING_PARAMS" ]; then
    echo "   Adding missing parameters:$MISSING_PARAMS"
    NEW_CMDLINE="$CURRENT_CMDLINE $MISSING_PARAMS"
    echo "   New: $NEW_CMDLINE"
    
    # Update GRUB
    sudo sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"$NEW_CMDLINE\"/" /etc/default/grub
    
    echo "🔄 Updating GRUB bootloader..."
    if sudo update-grub; then
        echo "   ✅ GRUB updated successfully"
    else
        echo "   ❌ GRUB update failed!"
        exit 1
    fi
else
    echo "   ✅ All required parameters already present"
fi

# 4. Create/update manual wake fix script
echo "🔧 Installing manual wake fix script..."
sudo tee /usr/local/bin/macbook-wake-fix > /dev/null << 'EOF'
#!/bin/bash
echo "🔧 MacBook8,1 manual wake fix..."
echo "0000:00:15.4" | sudo tee /sys/bus/pci/drivers/intel-lpss/unbind > /dev/null 2>&1 || true
sleep 2
echo "0000:00:15.4" | sudo tee /sys/bus/pci/drivers/intel-lpss/bind > /dev/null 2>&1 || true
sleep 2
sudo modprobe -r applespi 2>/dev/null || true
sleep 1
sudo modprobe applespi
sleep 2
echo "✅ Wake fix complete - test keyboard now"
EOF

sudo chmod +x /usr/local/bin/macbook-wake-fix
echo "   ✅ Manual fix installed: sudo macbook-wake-fix"

# 5. Try immediate SPI module reload
echo "🔄 Reloading SPI modules..."
sudo modprobe -r applespi 2>/dev/null || true
sleep 2
sudo modprobe applespi
sleep 3

# 6. Test keyboard functionality
echo ""
echo "🧪 TESTING BUILT-IN KEYBOARD:"
echo "   Try typing on the MacBook keyboard now..."
read -p "   Does the built-in keyboard work? (y/n): " final_test

if [[ "$final_test" =~ ^[Yy]$ ]]; then
    echo ""
    echo "🎉 SUCCESS! Built-in keyboard working!"
    echo ""
    echo "📋 WHAT WAS FIXED:"
    echo "   ✅ Kernel boot parameters applied"
    echo "   ✅ SPI modules reloaded"
    echo "   ✅ Manual wake fix script installed"
    echo ""
    echo "🔄 NEXT STEPS:"
    echo "   1. Reboot to ensure parameters take effect"
    echo "   2. Test sleep/wake cycle after reboot"
    echo "   3. If keyboard breaks after wake: sudo macbook-wake-fix"
    echo ""
    echo "💾 BACKUP CREATED:"
    echo "   Original GRUB: /etc/default/grub.emergency.backup.*"
    echo ""
else
    echo ""
    echo "❌ Built-in keyboard still not working"
    echo ""
    echo "🔄 TRY REBOOT:"
    echo "   Kernel parameters may require reboot to take effect"
    echo "   After reboot, run: sudo macbook-wake-fix"
    echo ""
    echo "🆘 IF STILL BROKEN AFTER REBOOT:"
    echo "   1. Boot with USB keyboard attached"
    echo "   2. Run: sudo macbook-wake-fix"
    echo "   3. Check hardware connection (rare hardware failure)"
    echo ""
    echo "📧 REPORT ISSUE:"
    echo "   If this script doesn't work, please report:"
    echo "   - MacBook model: $(sudo dmidecode -s system-product-name 2>/dev/null || echo 'Unknown')"
    echo "   - Kernel version: $(uname -r)"
    echo "   - Distribution: $(lsb_release -d 2>/dev/null || echo 'Unknown')"
    echo ""
fi

echo ""
echo "=================================================================="
echo "Emergency recovery script complete"
echo "=================================================================="
echo ""