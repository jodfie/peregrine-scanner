#!/bin/bash
# raven-extract.sh - Automated Raven Scanner APK Extraction for macOS
# Compatible with: macOS Sonoma/Sequoia, Warp Terminal
# Usage: ./raven-extract.sh

set -e

echo "════════════════════════════════════════════════════════════"
echo "   Raven Scanner APK Extractor - macOS + Warp Terminal"
echo "════════════════════════════════════════════════════════════"
echo ""

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check ADB installation
if ! command -v adb &> /dev/null; then
    echo -e "${RED}❌ ADB not found${NC}"
    echo ""
    echo "Install with: brew install --cask android-platform-tools"
    echo ""
    echo "Or run this command:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\" && brew install --cask android-platform-tools"
    exit 1
fi
echo -e "${GREEN}✓${NC} ADB found: $(adb version | head -1)"

# Start ADB server
echo ""
echo "Starting ADB server..."
adb start-server &> /dev/null
echo -e "${GREEN}✓${NC} ADB server started"

# Check for connected devices
echo ""
echo "Checking for connected devices..."
DEVICE=$(adb devices | grep -v "List" | grep "device" | awk '{print $1}')

if [ -z "$DEVICE" ]; then
    echo -e "${RED}❌ No device found${NC}"
    echo ""
    echo "📋 Troubleshooting checklist:"
    echo "  1. Is scanner connected via USB?"
    echo "  2. Is USB Debugging enabled on scanner?"
    echo "     → Settings → About → Tap 'Build Number' 7 times"
    echo "     → Settings → Developer Options → Enable USB Debugging"
    echo "  3. Did you authorize this computer on scanner?"
    echo "  4. Try running: adb kill-server && adb start-server"
    echo ""
    echo "Run this script again after fixing the above."
    exit 1
fi

echo -e "${GREEN}✓${NC} Device found: $DEVICE"

# Search for Raven/Scanner packages
echo ""
echo "Searching for Raven packages..."
echo ""

# Try multiple search patterns
PACKAGES=$(adb shell pm list packages -f 2>/dev/null | grep -i -E "raven|scan" | grep -v -E "scanner3|scannerdiesel|systemui|settings|launcher")

if [ -z "$PACKAGES" ]; then
    echo -e "${YELLOW}⚠${NC} No obvious Raven packages found with 'raven|scan'"
    echo "Searching for Avision/InnoComm packages..."
    PACKAGES=$(adb shell pm list packages -f 2>/dev/null | grep -i -E "avision|innocomm")
fi

if [ -z "$PACKAGES" ]; then
    echo -e "${RED}❌ No matching packages found${NC}"
    echo ""
    echo "Dumping all packages to ~/Desktop/all_scanner_packages.txt"
    adb shell pm list packages -f > ~/Desktop/all_scanner_packages.txt
    echo ""
    echo "Please review the file and look for packages related to:"
    echo "  • raven, scan, avision, innocomm, document"
    echo ""
    echo "Then run extraction manually:"
    echo "  1. adb shell pm path <package-name>"
    echo "  2. adb pull <path-from-above> ./raven.apk"
    echo ""
    open ~/Desktop/all_scanner_packages.txt
    exit 1
fi

echo -e "${BLUE}Found package(s):${NC}"
echo "$PACKAGES" | sed 's/^/  • /'
echo ""

# Extract package names for selection
PACKAGE_NAMES=$(echo "$PACKAGES" | sed 's/package://g' | sed 's/=.*//g' | awk -F'/' '{print $NF}' | sort -u)
PACKAGE_COUNT=$(echo "$PACKAGE_NAMES" | wc -l | xargs)

# Select package
if [ "$PACKAGE_COUNT" -gt 1 ]; then
    echo "Multiple packages found. Please select one:"
    echo ""
    PS3="Select package number: "
    select PACKAGE in $PACKAGE_NAMES "Exit"; do
        if [ "$PACKAGE" = "Exit" ]; then
            echo "Exiting..."
            exit 0
        elif [ -n "$PACKAGE" ]; then
            echo ""
            echo -e "${GREEN}Selected:${NC} $PACKAGE"
            break
        else
            echo "Invalid selection. Try again."
        fi
    done
else
    PACKAGE=$(echo "$PACKAGE_NAMES" | head -1)
    echo -e "${GREEN}Using package:${NC} $PACKAGE"
fi

# Get APK paths
echo ""
echo "Getting APK paths for: $PACKAGE"
APK_PATHS=$(adb shell pm path "$PACKAGE" 2>/dev/null | sed 's/package://g')

if [ -z "$APK_PATHS" ]; then
    echo -e "${RED}❌ Could not find APK path for package: $PACKAGE${NC}"
    echo ""
    echo "This might mean:"
    echo "  • Package name is incorrect"
    echo "  • App is not installed"
    echo "  • Permission denied"
    exit 1
fi

echo -e "${GREEN}✓${NC} Found APK path(s):"
echo "$APK_PATHS" | sed 's/^/  • /'
echo ""

# Count APKs
APK_COUNT=$(echo "$APK_PATHS" | wc -l | xargs)
echo "📦 Total APK files to extract: $APK_COUNT"

# Create extraction directory
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
EXTRACT_DIR="$HOME/Desktop/raven-apk-${TIMESTAMP}"
mkdir -p "$EXTRACT_DIR"

echo ""
echo -e "${BLUE}Extracting to:${NC} $EXTRACT_DIR"
echo ""

# Pull all APKs
cd "$EXTRACT_DIR"
COUNT=0
TOTAL_SIZE=0

while IFS= read -r apk_path; do
    COUNT=$((COUNT + 1))
    filename=$(basename "$apk_path")
    
    # Rename base.apk to something more descriptive
    if [[ "$filename" == "base.apk" ]]; then
        output_name="raven-base.apk"
    else
        output_name="$filename"
    fi
    
    echo -e "${YELLOW}[$COUNT/$APK_COUNT]${NC} Pulling: $filename → $output_name"
    
    # Pull and capture output for error handling
    if adb pull "$apk_path" "./$output_name" 2>&1 | grep -v "KB/s"; then
        SIZE=$(ls -lh "$output_name" 2>/dev/null | awk '{print $5}')
        echo -e "        ${GREEN}✓${NC} Success ($SIZE)"
    else
        echo -e "        ${RED}✗${NC} Failed to pull $filename"
    fi
    
done <<< "$APK_PATHS"

echo ""
echo "════════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ Extraction Complete!${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""

# Display extracted files
echo "📁 Location: $EXTRACT_DIR"
echo ""
echo "Files extracted:"
ls -lh *.apk | awk '{printf "  %-30s %10s\n", $9, $5}'
echo ""

# Calculate total size
TOTAL_SIZE=$(du -sh . | awk '{print $1}')
echo "💾 Total size: $TOTAL_SIZE"
echo ""

# Next steps guidance
echo "════════════════════════════════════════════════════════════"
echo "📊 Next Steps - Analysis Options:"
echo "════════════════════════════════════════════════════════════"
echo ""

echo "1️⃣  Open in JADX GUI (Visual Java decompiler):"
echo "   cd $EXTRACT_DIR"
echo "   jadx-gui raven-base.apk"
echo ""

echo "2️⃣  Decompile with APKTool (Smali bytecode):"
echo "   cd $EXTRACT_DIR"
echo "   apktool d raven-base.apk -o raven-decompiled"
echo ""

echo "3️⃣  Quick file inspection:"
echo "   cd $EXTRACT_DIR"
echo "   unzip -l raven-base.apk | head -30"
echo ""

echo "4️⃣  Extract native libraries (.so files):"
echo "   cd $EXTRACT_DIR"
echo "   unzip raven-base.apk 'lib/*' -d native-libs"
echo ""

echo "5️⃣  View AndroidManifest.xml:"
echo "   cd $EXTRACT_DIR"
echo "   apktool d raven-base.apk --no-src --no-res -o manifest-only"
echo "   cat manifest-only/AndroidManifest.xml"
echo ""

# Check if JADX is installed
if command -v jadx-gui &> /dev/null; then
    echo ""
    echo -e "${BLUE}JADX is installed!${NC}"
    read -p "Would you like to open the APK in JADX GUI now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Launching JADX GUI..."
        jadx-gui "$EXTRACT_DIR/raven-base.apk" &
        echo -e "${GREEN}✓${NC} JADX GUI launched in background"
    fi
else
    echo ""
    echo -e "${YELLOW}💡 Tip:${NC} Install JADX for easier code analysis:"
    echo "   brew install jadx"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "🔍 What to Look For in Decompiled Code:"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "• Scanner hardware interface (native methods, JNI calls)"
echo "• SMB/network implementation (smbj library, file transfer)"
echo "• Plugin loading system (APK loading, dynamic classes)"
echo "• Update mechanism (download URLs, version checks)"
echo "• Authentication/credentials handling"
echo ""

echo "📋 Key Search Terms (after decompiling):"
echo "  grep -r 'native.*scan' ."
echo "  grep -r 'SMB\\|smbj' ."
echo "  grep -r 'plugin.*load' ."
echo "  grep -r 'System.loadLibrary' ."
echo ""

echo "════════════════════════════════════════════════════════════"
echo "🎉 Done! Happy analyzing!"
echo "════════════════════════════════════════════════════════════"
echo ""

# Create a quick summary file
SUMMARY_FILE="$EXTRACT_DIR/EXTRACTION_SUMMARY.txt"
cat > "$SUMMARY_FILE" << EOF
Raven Scanner APK Extraction Summary
=====================================

Extraction Date: $(date)
Device ID: $DEVICE
Package Name: $PACKAGE
APK Count: $APK_COUNT
Total Size: $TOTAL_SIZE
Location: $EXTRACT_DIR

Extracted Files:
$(ls -lh *.apk | awk '{printf "  %-30s %10s\n", $9, $5}')

APK Paths on Device:
$APK_PATHS

Next Steps:
1. Decompile with JADX or APKTool
2. Analyze AndroidManifest.xml
3. Extract and examine native libraries
4. Search for SMB/scanner/plugin code

Documentation:
See raven-apk-extraction-warp-guide.md for full analysis guide
EOF

echo "📄 Summary saved to: $SUMMARY_FILE"
echo ""
