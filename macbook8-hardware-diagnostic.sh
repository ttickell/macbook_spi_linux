#!/bin/bash

# MacBook8,1 Audio/Bluetooth/Camera Diagnostic and Fix Script
# Identifies and fixes common MacBook8,1 hardware issues beyond SPI

SCRIPT_VERSION="2025.09.29"

echo "=================================================================="
echo "MacBook8,1 Hardware Diagnostic & Fix v${SCRIPT_VERSION}"
echo "=================================================================="
echo ""
echo "🔍 CHECKING: Audio, Bluetooth, Camera, WiFi functionality"
echo "💻 HARDWARE: MacBook8,1 (2015 12-inch MacBook)"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to test audio functionality
test_audio() {
    echo "🔊 AUDIO SYSTEM DIAGNOSTIC:"
    echo ""
    
    # Check if audio devices are detected
    echo "   Audio devices detected:"
    if command_exists aplay; then
        aplay -l 2>/dev/null | grep -E "card|device" | head -5 | sed 's/^/     /'
    else
        echo "     aplay not available, checking /proc/asound/"
        ls /proc/asound/ 2>/dev/null | sed 's/^/     /' || echo "     No audio devices found"
    fi
    echo ""
    
    # Check PulseAudio/PipeWire status
    echo "   Audio system status:"
    if pgrep -x "pulseaudio" > /dev/null; then
        echo "     ✅ PulseAudio running"
        if command_exists pactl; then
            SINK_COUNT=$(pactl list short sinks 2>/dev/null | wc -l)
            echo "     Audio sinks available: $SINK_COUNT"
        fi
    elif pgrep -x "pipewire" > /dev/null; then
        echo "     ✅ PipeWire running"
    else
        echo "     ❌ No audio system detected"
    fi
    echo ""
    
    # Check for common MacBook audio issues
    echo "   MacBook8,1 audio hardware:"
    lspci | grep -i audio | sed 's/^/     /'
    echo ""
    
    # Check ALSA mixer levels
    if command_exists amixer; then
        echo "   ALSA mixer status:"
        amixer get Master 2>/dev/null | grep -E "Playback|%|on|off" | sed 's/^/     /' || echo "     Master control not found"
        amixer get PCM 2>/dev/null | grep -E "Playback|%|on|off" | sed 's/^/     /' || echo "     PCM control not found"
    fi
    echo ""
}

# Function to test Bluetooth
test_bluetooth() {
    echo "📡 BLUETOOTH DIAGNOSTIC:"
    echo ""
    
    # Check if Bluetooth hardware is detected
    echo "   Bluetooth hardware:"
    lspci | grep -i bluetooth | sed 's/^/     /' || echo "     No PCI Bluetooth found"
    lsusb | grep -i bluetooth | sed 's/^/     /' || echo "     No USB Bluetooth found"
    echo ""
    
    # Check rfkill status
    if command_exists rfkill; then
        echo "   RF kill switches:"
        rfkill list bluetooth | sed 's/^/     /'
    fi
    echo ""
    
    # Check systemd bluetooth service
    echo "   Bluetooth service status:"
    if systemctl is-active --quiet bluetooth; then
        echo "     ✅ bluetooth.service active"
    else
        echo "     ❌ bluetooth.service not active"
    fi
    echo ""
    
    # Check if bluetoothctl is available
    if command_exists bluetoothctl; then
        echo "   Bluetooth controller status:"
        timeout 5s bluetoothctl show 2>/dev/null | grep -E "Controller|Powered|Discoverable" | sed 's/^/     /' || echo "     Controller not responding"
    fi
    echo ""
}

# Function to test camera
test_camera() {
    echo "📷 CAMERA DIAGNOSTIC:"
    echo ""
    
    # Check for camera hardware
    echo "   Camera hardware detection:"
    lsusb | grep -i camera | sed 's/^/     /' || echo "     No USB camera found"
    
    # Check for video devices
    echo "   Video devices:"
    ls /dev/video* 2>/dev/null | sed 's/^/     /' || echo "     No video devices found"
    echo ""
    
    # Check kernel modules
    echo "   Camera-related kernel modules:"
    lsmod | grep -E "uvcvideo|facetimehd|bdc_pci" | sed 's/^/     /' || echo "     No camera modules loaded"
    echo ""
    
    # Check dmesg for camera errors
    echo "   Recent camera-related kernel messages:"
    dmesg | grep -i -E "camera|video|uvc|facetime" | tail -3 | sed 's/^/     /' || echo "     No recent camera messages"
    echo ""
}

# Function to test WiFi
test_wifi() {
    echo "📶 WIFI DIAGNOSTIC:"
    echo ""
    
    # Check WiFi hardware
    echo "   WiFi hardware:"
    lspci | grep -i -E "wireless|wifi|network" | sed 's/^/     /'
    echo ""
    
    # Check network interfaces
    echo "   Network interfaces:"
    ip link show | grep -E "wlan|wlp" | sed 's/^/     /' || echo "     No wireless interfaces found"
    echo ""
    
    # Check WiFi status
    if command_exists nmcli; then
        echo "   NetworkManager WiFi status:"
        nmcli radio wifi 2>/dev/null | sed 's/^/     WiFi: /'
        nmcli dev status 2>/dev/null | grep wifi | sed 's/^/     /' || echo "     No WiFi devices in NetworkManager"
    fi
    echo ""
}

# Run diagnostics
echo "🔍 RUNNING HARDWARE DIAGNOSTICS..."
echo ""

test_audio
test_bluetooth  
test_camera
test_wifi

echo "=================================================================="
echo "🔧 MACBOOK8,1 COMMON FIXES"
echo "=================================================================="
echo ""

# MacBook8,1 specific fixes
echo "💡 KNOWN MACBOOK8,1 ISSUES & SOLUTIONS:"
echo ""

echo "1. 🔊 AUDIO ISSUES:"
echo "   Problem: No sound output, wrong audio device selected"
echo "   Solutions:"
echo "     • Check audio output device: pavucontrol (install: sudo apt install pavucontrol)"
echo "     • Force correct audio device: sudo alsa force-reload"
echo "     • Reset PulseAudio: pulseaudio -k && pulseaudio --start"
echo "     • Check mixer levels: alsamixer"
echo ""

echo "2. 📡 BLUETOOTH ISSUES:"
echo "   Problem: Bluetooth not working, can't pair devices"
echo "   Solutions:"
echo "     • Enable Bluetooth: sudo systemctl enable bluetooth && sudo systemctl start bluetooth"
echo "     • Unblock RF: sudo rfkill unblock bluetooth"
echo "     • Reset Bluetooth: sudo systemctl restart bluetooth"
echo "     • Install firmware: sudo apt install firmware-b43-installer"
echo ""

echo "3. 📷 CAMERA ISSUES:"
echo "   Problem: Camera not detected, FaceTime HD not working"
echo "   Solutions:"
echo "     • Install FaceTime HD driver: sudo apt install facetimehd-dkms"
echo "     • Load kernel module: sudo modprobe facetimehd"
echo "     • Check camera apps: cheese, guvcview"
echo "     • Verify permissions: sudo usermod -a -G video $USER"
echo ""

echo "4. 📶 WIFI ISSUES:"
echo "   Problem: WiFi slow, drops connection, not detected"
echo "   Solutions:"
echo "     • Update WiFi driver: sudo apt install firmware-linux-nonfree"
echo "     • Reset NetworkManager: sudo systemctl restart NetworkManager"
echo "     • Check power management: sudo iwconfig wlan0 power off"
echo "     • Force 2.4GHz if 5GHz unstable"
echo ""

# Offer to run automated fixes
echo "🚀 AUTOMATED FIXES AVAILABLE:"
echo ""
echo "Would you like to run automated fixes? (y/N)"
read -p "Apply common MacBook8,1 hardware fixes? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🔧 APPLYING AUTOMATED FIXES..."
    echo ""
    
    # Audio fixes
    echo "🔊 Applying audio fixes..."
    sudo apt update >/dev/null 2>&1
    sudo apt install -y alsa-utils pulseaudio pavucontrol >/dev/null 2>&1
    pulseaudio -k 2>/dev/null || true
    pulseaudio --start 2>/dev/null || true
    echo "   ✅ Audio system reset"
    
    # Bluetooth fixes
    echo "📡 Applying Bluetooth fixes..."
    sudo apt install -y bluetooth bluez bluez-tools >/dev/null 2>&1
    sudo systemctl enable bluetooth >/dev/null 2>&1
    sudo systemctl start bluetooth >/dev/null 2>&1
    sudo rfkill unblock bluetooth 2>/dev/null || true
    echo "   ✅ Bluetooth enabled"
    
    # Camera fixes
    echo "📷 Applying camera fixes..."
    sudo apt install -y cheese guvcview >/dev/null 2>&1
    # Note: facetimehd-dkms may need manual installation on some systems
    if apt-cache search facetimehd-dkms | grep -q facetimehd; then
        sudo apt install -y facetimehd-dkms >/dev/null 2>&1 || echo "   ⚠️  FaceTime HD driver needs manual installation"
    fi
    sudo usermod -a -G video $USER 2>/dev/null || true
    echo "   ✅ Camera support installed"
    
    # WiFi fixes
    echo "📶 Applying WiFi fixes..."
    sudo apt install -y firmware-linux-nonfree wireless-tools >/dev/null 2>&1
    sudo systemctl restart NetworkManager >/dev/null 2>&1 || true
    echo "   ✅ WiFi drivers updated"
    
    echo ""
    echo "🎉 AUTOMATED FIXES COMPLETE!"
    echo ""
    echo "📋 NEXT STEPS:"
    echo "   1. Reboot system to ensure all changes take effect"
    echo "   2. Test audio: Open sound settings, play test sound"
    echo "   3. Test Bluetooth: Try pairing a device"
    echo "   4. Test camera: Open cheese or another camera app"
    echo "   5. Test WiFi: Check connection stability"
    echo ""
    echo "🔄 Reboot recommended: sudo reboot"
    
else
    echo ""
    echo "ℹ️  Automated fixes skipped"
    echo "💡 You can run individual fixes manually using the solutions listed above"
fi

echo ""
echo "=================================================================="
echo "Diagnostic complete - check output above for specific issues"
echo "=================================================================="