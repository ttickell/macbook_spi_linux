#!/bin/bash

# MacBook8,1 Complete Hardware Emergency Fix
# Quick recovery for all hardware when something breaks after updates
# Based on proven drivers + bastiansg/macbook-pro-13-2017-ubuntu-drivers

SCRIPT_VERSION="2025.09.29"

echo "=================================================================="
echo "MacBook8,1 Complete Hardware Emergency Fix v${SCRIPT_VERSION}"
echo "=================================================================="
echo ""
echo "🚨 EMERGENCY RECOVERY MODE"
echo "   Use this script when ANY hardware stops working"
echo "   Fixes: Keyboard, Audio, Camera, Bluetooth, WiFi"
echo "   Requires: USB keyboard/mouse may be needed initially"
echo ""

# Verify we can type
echo "🔍 USB Keyboard Test:"
echo "   Type 'yes' and press Enter to continue..."
read -p "   Input: " response
if [[ "$response" != "yes" ]]; then
    echo "❌ USB keyboard not working or user cancelled"
    exit 1
fi

echo ""
echo "🔧 APPLYING EMERGENCY HARDWARE FIXES..."
echo ""

# 1. SPI Keyboard/Touchpad Emergency Fix
echo "⌨️  FIXING SPI KEYBOARD/TOUCHPAD..."

# Apply kernel parameters if missing
CURRENT_CMDLINE=$(grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub | cut -d'"' -f2)
REQUIRED_SPI="pxa2xx_spi.enable_dma=0 intel_spi.force_pio=1 spi_pxa2xx.use_pio=1 acpi_sleep=nonvs mem_sleep_default=s2idle intel_spi.writeable=1"

MISSING_SPI=""
for param in $REQUIRED_SPI; do
    if [[ "$CURRENT_CMDLINE" != *"$param"* ]]; then
        MISSING_SPI="$MISSING_SPI $param"
    fi
done

if [ -n "$MISSING_SPI" ]; then
    echo "   Adding missing SPI parameters..."
    sudo cp /etc/default/grub /etc/default/grub.emergency.backup.$(date +%Y%m%d_%H%M%S)
    NEW_CMDLINE="$CURRENT_CMDLINE $MISSING_SPI"
    sudo sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"$NEW_CMDLINE\"/" /etc/default/grub
    sudo update-grub
    echo "   ✅ SPI parameters updated"
else
    echo "   ✅ SPI parameters already present"
fi

# Manual SPI reset
echo "   Performing manual SPI reset..."
echo "0000:00:15.4" | sudo tee /sys/bus/pci/drivers/intel-lpss/unbind > /dev/null 2>&1 || true
sleep 2
echo "0000:00:15.4" | sudo tee /sys/bus/pci/drivers/intel-lpss/bind > /dev/null 2>&1 || true
sleep 2
sudo modprobe -r applespi 2>/dev/null || true
sleep 1
sudo modprobe applespi
sleep 2
echo "   ✅ SPI reset complete"

# 2. Audio Emergency Fix
echo ""
echo "🔊 FIXING AUDIO SYSTEM..."

# Kill and restart audio
pulseaudio -k 2>/dev/null || true
sleep 1
pulseaudio --start 2>/dev/null || true

# Create/update audio configuration
sudo tee /etc/modprobe.d/macbook8-audio-emergency.conf > /dev/null << 'EOF'
# MacBook8,1 Emergency Audio Configuration
options snd_hda_intel enable_msi=0
options snd_hda_intel probe_mask=1
options snd_hda_intel model=macbook-pro
EOF

# Reload audio modules
sudo modprobe -r snd_hda_intel 2>/dev/null || true
sleep 1
sudo modprobe snd_hda_intel 2>/dev/null || true

echo "   ✅ Audio system reset"

# 3. Camera Emergency Fix
echo ""
echo "📷 FIXING CAMERA SYSTEM..."

# Ensure user is in video group
sudo usermod -a -G video $USER 2>/dev/null || true

# Try to load camera modules
sudo modprobe facetimehd 2>/dev/null && echo "   ✅ FaceTime HD loaded" || echo "   ⚠️  FaceTime HD not available"
sudo modprobe uvcvideo 2>/dev/null && echo "   ✅ UVC video loaded" || echo "   ⚠️  UVC video not available"

# Check for video devices
if ls /dev/video* >/dev/null 2>&1; then
    echo "   ✅ Video devices detected"
else
    echo "   ⚠️  No video devices found"
fi

# 4. Bluetooth Emergency Fix
echo ""
echo "📡 FIXING BLUETOOTH..."

# Unblock and restart Bluetooth
sudo rfkill unblock bluetooth 2>/dev/null || true
sudo systemctl stop bluetooth 2>/dev/null || true
sleep 1
sudo systemctl start bluetooth 2>/dev/null || true
sudo systemctl enable bluetooth 2>/dev/null || true

if systemctl is-active --quiet bluetooth; then
    echo "   ✅ Bluetooth service active"
else
    echo "   ⚠️  Bluetooth service failed to start"
fi

# 5. WiFi Emergency Fix
echo ""
echo "📶 FIXING WIFI..."

# Restart NetworkManager
sudo systemctl restart NetworkManager 2>/dev/null || true

# Create WiFi optimization if missing
sudo tee /etc/NetworkManager/conf.d/macbook8-wifi-emergency.conf > /dev/null << 'EOF'
# MacBook8,1 Emergency WiFi Configuration
[device-macbook8-wifi]
match-device=driver:brcmfmac
wifi.powersave=2
wifi.scan-rand-mac-address=no
EOF

# Check WiFi status
if nmcli radio wifi | grep -q "enabled"; then
    echo "   ✅ WiFi enabled"
else
    echo "   ⚠️  WiFi may be disabled"
fi

# 6. Install Emergency Fix Scripts
echo ""
echo "🛠️  INSTALLING EMERGENCY FIX SCRIPTS..."

sudo mkdir -p /usr/local/bin

# Create quick SPI fix
sudo tee /usr/local/bin/macbook8-spi-emergency > /dev/null << 'EOF'
#!/bin/bash
echo "🔧 Emergency SPI fix..."
echo "0000:00:15.4" | sudo tee /sys/bus/pci/drivers/intel-lpss/unbind > /dev/null 2>&1 || true
sleep 2
echo "0000:00:15.4" | sudo tee /sys/bus/pci/drivers/intel-lpss/bind > /dev/null 2>&1 || true
sleep 2
sudo modprobe -r applespi 2>/dev/null || true
sleep 1
sudo modprobe applespi
echo "✅ SPI emergency fix complete"
EOF

# Create complete hardware fix
sudo tee /usr/local/bin/macbook8-hardware-emergency > /dev/null << 'EOF'
#!/bin/bash
echo "🔧 Complete hardware emergency fix..."
echo ""

echo "⌨️  SPI fix..."
macbook8-spi-emergency

echo ""
echo "🔊 Audio fix..."
pulseaudio -k 2>/dev/null || true
pulseaudio --start

echo ""
echo "📡 Bluetooth fix..."
sudo systemctl restart bluetooth
sudo rfkill unblock bluetooth

echo ""
echo "📷 Camera fix..."
sudo modprobe facetimehd 2>/dev/null || true
sudo modprobe uvcvideo 2>/dev/null || true

echo ""
echo "📶 WiFi fix..."
sudo systemctl restart NetworkManager

echo ""
echo "✅ Complete hardware emergency fix finished"
EOF

sudo chmod +x /usr/local/bin/macbook8-spi-emergency
sudo chmod +x /usr/local/bin/macbook8-hardware-emergency

echo "   ✅ Emergency scripts installed"

# 7. Test Hardware
echo ""
echo "🧪 TESTING HARDWARE..."
echo ""

# Test built-in keyboard
echo "⌨️  Testing built-in keyboard:"
echo "   Try typing on the MacBook keyboard now..."
read -p "   Does the built-in keyboard work? (y/n): " kb_test

if [[ "$kb_test" =~ ^[Yy]$ ]]; then
    echo "   ✅ Keyboard working!"
else
    echo "   ❌ Keyboard still broken - reboot may be required"
fi

# Test audio
echo ""
echo "🔊 Testing audio:"
if pgrep -x "pulseaudio" > /dev/null; then
    echo "   ✅ Audio system running"
    if pactl list short sinks | wc -l | grep -q "^[1-9]"; then
        echo "   ✅ Audio devices available"
    else
        echo "   ⚠️  No audio devices found"
    fi
else
    echo "   ❌ Audio system not running"
fi

# Test camera
echo ""
echo "📷 Testing camera:"
if ls /dev/video* >/dev/null 2>&1; then
    echo "   ✅ Video devices present"
else
    echo "   ❌ No video devices found"
fi

# Test Bluetooth
echo ""
echo "📡 Testing Bluetooth:"
if systemctl is-active --quiet bluetooth; then
    echo "   ✅ Bluetooth service active"
else
    echo "   ❌ Bluetooth service not active"
fi

# Test WiFi
echo ""
echo "📶 Testing WiFi:"
if nmcli radio wifi | grep -q "enabled"; then
    echo "   ✅ WiFi enabled"
else
    echo "   ❌ WiFi disabled"
fi

echo ""
echo "=================================================================="
echo "🏁 EMERGENCY RECOVERY COMPLETE"
echo "=================================================================="
echo ""

# Summary
WORKING_COUNT=0
if [[ "$kb_test" =~ ^[Yy]$ ]]; then ((WORKING_COUNT++)); fi
if pgrep -x "pulseaudio" > /dev/null; then ((WORKING_COUNT++)); fi
if ls /dev/video* >/dev/null 2>&1; then ((WORKING_COUNT++)); fi
if systemctl is-active --quiet bluetooth; then ((WORKING_COUNT++)); fi
if nmcli radio wifi | grep -q "enabled"; then ((WORKING_COUNT++)); fi

echo "📊 HARDWARE STATUS: $WORKING_COUNT/5 components working"
echo ""

if [ "$WORKING_COUNT" -ge 4 ]; then
    echo "🎉 SUCCESS! Most hardware working"
    echo ""
    echo "🔄 NEXT STEPS:"
    echo "   1. Test all functionality thoroughly"
    echo "   2. If keyboard still broken: reboot system"
    echo "   3. For future issues: run macbook8-hardware-emergency"
    echo ""
elif [ "$WORKING_COUNT" -ge 2 ]; then
    echo "⚠️  PARTIAL SUCCESS - Some hardware needs attention"
    echo ""
    echo "🔄 NEXT STEPS:"
    echo "   1. Reboot system: sudo reboot"
    echo "   2. After reboot, run this script again if needed"
    echo "   3. Consider full hardware installer for complete fix"
    echo ""
else
    echo "❌ HARDWARE ISSUES PERSIST"
    echo ""
    echo "🔄 NEXT STEPS:"
    echo "   1. REBOOT REQUIRED: sudo reboot"
    echo "   2. Run this script again after reboot"
    echo "   3. If still broken: run complete hardware installer"
    echo "   4. Check hardware connections (rare hardware failure)"
    echo ""
fi

echo "🛠️  EMERGENCY COMMANDS INSTALLED:"
echo "   macbook8-spi-emergency       - Fix keyboard/touchpad only"
echo "   macbook8-hardware-emergency  - Fix all hardware quickly"
echo ""
echo "📋 REMEMBER:"
echo "   • Emergency scripts now available for future use"
echo "   • Reboot often fixes remaining issues"
echo "   • This repair can be run multiple times safely"
echo ""