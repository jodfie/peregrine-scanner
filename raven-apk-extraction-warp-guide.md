# Raven Scanner APK Extraction Guide - macOS + Warp Terminal

**Complete guide for extracting and analyzing the Raven Document Scanner APK**  
**Compatible with:** macOS Sonoma/Sequoia (14.x/15.x) | Warp Terminal

---

## 🚀 Quick Start - Automated Extraction

### One-Command Setup & Extract

Copy and paste this entire block into Warp Terminal:

```bash
# Install prerequisites (if needed)
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! command -v adb &> /dev/null; then
    echo "Installing Android Platform Tools..."
    brew install --cask android-platform-tools
fi

if ! command -v jadx &> /dev/null; then
    echo "Installing JADX decompiler..."
    brew install jadx
fi

echo "✅ All prerequisites installed!"
adb version
```

### Automated Extraction Script

Save this script or run directly in Warp:

```bash
#!/bin/bash
# raven-extract.sh - Automated Raven APK Extraction for macOS

set -e

echo "════════════════════════════════════════════════════════════"
echo "   Raven Scanner APK Extractor - macOS + Warp Terminal"
echo "════════════════════════════════════════════════════════════"
echo ""

# Colors for Warp
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check ADB installation
if ! command -v adb &> /dev/null; then
    echo -e "${RED}❌ ADB not found${NC}"
    echo "Install with: brew install --cask android-platform-tools"
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
    echo "Troubleshooting checklist:"
    echo "  1. Scanner connected via USB?"
    echo "  2. USB Debugging enabled on scanner?"
    echo "     Settings → About → Tap 'Build Number' 7 times"
    echo "     Settings → Developer Options → Enable USB Debugging"
    echo "  3. Authorized this computer on scanner?"
    echo "  4. Try: adb kill-server && adb start-server"
    exit 1
fi

echo -e "${GREEN}✓${NC} Device found: $DEVICE"

# Search for Raven/Scanner packages
echo ""
echo "Searching for Raven packages..."
echo ""

# Try multiple search patterns
PACKAGES=$(adb shell pm list packages -f 2>/dev/null | grep -i -E "raven|scan" | grep -v -E "scanner3|scannerdiesel|systemui")

if [ -z "$PACKAGES" ]; then
    echo -e "${YELLOW}⚠${NC} No obvious Raven packages found"
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
    echo "  - raven, scan, avision, innocomm, document"
    echo ""
    echo "Then run manually:"
    echo "  adb shell pm path <package-name>"
    echo "  adb pull <path-from-above> ./raven.apk"
    exit 1
fi

echo "Found packages:"
echo -e "${YELLOW}$PACKAGES${NC}"
echo ""

# Let user select if multiple packages found
PACKAGE_COUNT=$(echo "$PACKAGES" | wc -l | xargs)
if [ "$PACKAGE_COUNT" -gt 1 ]; then
    echo "Multiple packages found. Select one:"
    select SELECTED_PACKAGE in $PACKAGES "Exit"; do
        if [ "$SELECTED_PACKAGE" = "Exit" ]; then
            exit 0
        elif [ -n "$SELECTED_PACKAGE" ]; then
            PACKAGE=$(echo "$SELECTED_PACKAGE" | sed 's/package://g' | sed 's/=.*//g' | awk -F'/' '{print $NF}')
            break
        fi
    done
else
    PACKAGE=$(echo "$PACKAGES" | head -1 | sed 's/package://g' | sed 's/=.*//g' | awk -F'/' '{print $NF}')
fi

echo -e "${GREEN}Using package:${NC} $PACKAGE"

# Get APK paths
echo ""
echo "Getting APK paths..."
APK_PATHS=$(adb shell pm path "$PACKAGE" 2>/dev/null | sed 's/package://g')

if [ -z "$APK_PATHS" ]; then
    echo -e "${RED}❌ Could not find APK path for package: $PACKAGE${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Found APK(s):"
echo "$APK_PATHS"

# Create extraction directory
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
EXTRACT_DIR="$HOME/Desktop/raven-apk-${TIMESTAMP}"
mkdir -p "$EXTRACT_DIR"

echo ""
echo -e "${GREEN}Extracting to:${NC} $EXTRACT_DIR"
echo ""

# Pull all APKs
cd "$EXTRACT_DIR"
COUNT=0

while IFS= read -r apk_path; do
    COUNT=$((COUNT + 1))
    filename=$(basename "$apk_path")
    
    if [[ "$filename" == "base.apk" ]]; then
        output_name="raven-base.apk"
    else
        output_name="$filename"
    fi
    
    echo "  📦 Pulling: $filename"
    adb pull "$apk_path" "./$output_name" 2>&1 | grep -v "KB/s" || true
done <<< "$APK_PATHS"

echo ""
echo "════════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ Extraction Complete!${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📁 Location: $EXTRACT_DIR"
echo ""
echo "Files extracted:"
ls -lh *.apk | awk '{print "  " $9 " (" $5 ")"}'
echo ""
echo "📊 Next Steps:"
echo ""
echo "  1️⃣  Open in JADX GUI:"
echo "     jadx-gui $EXTRACT_DIR/raven-base.apk"
echo ""
echo "  2️⃣  Decompile with APKTool:"
echo "     cd $EXTRACT_DIR"
echo "     apktool d raven-base.apk -o raven-decompiled"
echo ""
echo "  3️⃣  Quick inspection:"
echo "     unzip -l raven-base.apk | head -20"
echo ""
echo "  4️⃣  Extract native libraries:"
echo "     unzip raven-base.apk 'lib/*' -d extracted-libs"
echo ""

# Offer to open in JADX
if command -v jadx-gui &> /dev/null; then
    echo ""
    read -p "Open in JADX GUI now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        jadx-gui "$EXTRACT_DIR/raven-base.apk" &
        echo -e "${GREEN}✓${NC} JADX GUI launched"
    fi
fi

echo ""
echo "🎉 Done! Happy analyzing!"
```

**To run this script:**

```bash
# Copy script to Desktop
curl -o ~/Desktop/raven-extract.sh https://raw.githubusercontent.com/YOUR-REPO/raven-extract.sh

# Or create it manually
nano ~/Desktop/raven-extract.sh
# Paste the script above, then Ctrl+X, Y, Enter

# Make executable
chmod +x ~/Desktop/raven-extract.sh

# Run it
~/Desktop/raven-extract.sh
```

---

## 📋 Manual Step-by-Step Process

### Step 1: Install Prerequisites

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Android Platform Tools
brew install --cask android-platform-tools

# Verify installation
adb version

# Install decompilation tools
brew install jadx apktool

# Verify JADX
jadx --version
```

### Step 2: Enable USB Debugging on Scanner

**On the Raven Scanner:**

1. Go to **Settings** → **About** (or "About Device")
2. Find **Build Number**
3. **Tap "Build Number" 7 times rapidly**
4. Message appears: "You are now a developer!"
5. Go back to **Settings**
6. Open **Developer Options** (may be under System → Advanced)
7. Toggle **ON** at top
8. Enable **USB Debugging**
9. Enable **Stay Awake**

### Step 3: Connect Scanner to Mac

```bash
# Connect scanner via USB cable

# Start ADB server
adb start-server

# Check if device is detected
adb devices

# Expected output:
# List of devices attached
# ABC123XYZ    device

# If you see "unauthorized":
# - Check scanner screen for authorization prompt
# - Tap "Always allow from this computer"
# - Tap "OK"

# If no device appears:
adb kill-server
adb start-server
adb devices
```

### Step 4: Find Raven Package

```bash
# Search for Raven package
adb shell pm list packages -f | grep -i raven

# Search for scanner-related packages
adb shell pm list packages -f | grep -i scan

# Search for Avision (OEM manufacturer)
adb shell pm list packages -f | grep -i avision

# If nothing found, dump all packages
adb shell pm list packages -f > ~/Desktop/all_packages.txt

# Open and search manually
open ~/Desktop/all_packages.txt
# Look for: raven, scan, avision, innocomm, document

# Alternative: Check currently running app
# (Launch Raven app on scanner first, then run:)
adb shell dumpsys activity top | grep ACTIVITY
```

**Likely package names:**
- `com.raven.scanner`
- `com.raven.app`
- `com.avision.scanner`
- `raven.scanner`
- `com.innocomm.scanner`

### Step 5: Extract APK

```bash
# Replace PACKAGE_NAME with actual package from Step 4
PACKAGE_NAME="com.raven.scanner"

# Get APK path(s)
adb shell pm path $PACKAGE_NAME

# Output example:
# package:/data/app/com.raven.scanner-AbC123XyZ==/base.apk
# package:/data/app/com.raven.scanner-AbC123XyZ==/split_config.arm64_v8a.apk

# Create extraction directory
mkdir -p ~/Desktop/raven-apk-extracted
cd ~/Desktop/raven-apk-extracted

# Pull base APK (use exact path from pm path command)
adb pull /data/app/com.raven.scanner-AbC123XyZ==/base.apk ./raven-base.apk

# Pull all split APKs (if they exist)
adb pull /data/app/com.raven.scanner-AbC123XyZ==/split_config.arm64_v8a.apk ./
adb pull /data/app/com.raven.scanner-AbC123XyZ==/split_config.xxhdpi.apk ./

# Verify extraction
ls -lh *.apk
```

### Alternative: Pull Entire App Directory

```bash
# Get app directory
APP_DIR=$(adb shell pm path com.raven.scanner | head -1 | sed 's/package://g' | sed 's/\/base.apk//g')

# Pull entire directory
adb pull "$APP_DIR" ~/Desktop/raven-apk-extracted/

# This gets everything in one command
```

---

## 🔍 Analysis Tools & Commands

### Quick Inspection

```bash
cd ~/Desktop/raven-apk-extracted

# List APK contents
unzip -l raven-base.apk | less

# Extract specific files
unzip raven-base.apk AndroidManifest.xml -d manifest-dir
unzip raven-base.apk 'lib/*' -d native-libs
unzip raven-base.apk 'assets/*' -d assets-dir

# Get basic APK info (requires build-tools)
aapt dump badging raven-base.apk | grep "package:"
aapt dump badging raven-base.apk | grep "application-label:"
aapt dump permissions raven-base.apk
```

### Decompile with JADX (Recommended)

```bash
# Open in JADX GUI
jadx-gui ~/Desktop/raven-apk-extracted/raven-base.apk

# Or decompile to directory
jadx raven-base.apk -d raven-jadx-output

# Browse decompiled Java code
cd raven-jadx-output/sources
ls -la

# Search for specific functionality
grep -r "SMB" .
grep -r "scanner" .
grep -r "plugin" .
```

### Decompile with APKTool

```bash
cd ~/Desktop/raven-apk-extracted

# Decompile to smali
apktool d raven-base.apk -o raven-decompiled

# Explore structure
cd raven-decompiled
tree -L 2

# Key directories:
# - smali/          # Decompiled Dalvik bytecode
# - lib/            # Native libraries (.so files)
# - res/            # Resources (layouts, images, etc)
# - assets/         # App assets
# - AndroidManifest.xml  # App manifest (now readable)

# View AndroidManifest
cat AndroidManifest.xml | less

# Recompile after modifications (advanced)
apktool b raven-decompiled -o raven-modified.apk
```

### Extract and Analyze Native Libraries

```bash
# Extract native libraries
unzip raven-base.apk 'lib/*' -d native-libs
cd native-libs/lib

# List architectures
ls -la

# Typical structure:
# arm64-v8a/  - 64-bit ARM (most common)
# armeabi-v7a/  - 32-bit ARM
# x86_64/     - 64-bit Intel (rare on tablets)

# List .so files
find . -name "*.so" -exec ls -lh {} \;

# Check library dependencies (requires otool)
cd arm64-v8a
otool -L *.so | less

# Search for scanner-related functions
strings libscanner.so | grep -i scan
strings libscanner.so | grep -i avision
```

### Search for Keywords in Decompiled Code

```bash
cd ~/Desktop/raven-apk-extracted/raven-jadx-output/sources

# Find SMB implementation
grep -r "smbj" . | head -20
grep -r "SMBClient" .
grep -r "SmbFile" .

# Find scanner hardware interface
grep -r "scan" . | grep -i "hardware\|device\|driver"

# Find plugin loading
grep -r "plugin" . | grep -i "load\|install\|update"

# Find cloud/network code
grep -r "cloud" .
grep -r "upload" .
grep -r "http" . | grep -v "https://schemas"

# Find update mechanism
grep -r "update\|upgrade" . | grep -i "apk\|download"
```

---

## 🔧 Advanced Analysis

### Extract and Read AndroidManifest.xml

```bash
# Decompile to get readable manifest
apktool d raven-base.apk -o manifest-only --no-src --no-res

# Read manifest
cat manifest-only/AndroidManifest.xml | less

# Extract key information
cat manifest-only/AndroidManifest.xml | grep "permission"
cat manifest-only/AndroidManifest.xml | grep "activity"
cat manifest-only/AndroidManifest.xml | grep "service"
```

### Analyze Dex Files

```bash
# Extract dex files
unzip raven-base.apk classes.dex classes2.dex -d dex-files

# Convert dex to jar (requires d2j-dex2jar)
brew install dex2jar

d2j-dex2jar raven-base.apk -o raven.jar

# Analyze jar with JD-GUI
brew install --cask jd-gui
jd-gui raven.jar
```

### Check for Debug/Test Code

```bash
cd ~/Desktop/raven-apk-extracted/raven-jadx-output/sources

# Look for test/debug packages
find . -type d -name "*test*"
find . -type d -name "*debug*"

# Search for debug flags
grep -r "BuildConfig.DEBUG" .
grep -r "Log.d\|Log.v\|Log.i" . | wc -l
```

---

## 🛠️ Troubleshooting Commands

### ADB Connection Issues

```bash
# Kill and restart ADB server
adb kill-server
adb start-server

# Check USB connection
system_profiler SPUSBDataType | grep -A 10 "Android"

# Check ADB is in PATH
which adb
echo $PATH | grep platform-tools

# Manually add to PATH if needed
export PATH="/opt/homebrew/bin:$PATH"

# Reset USB debugging authorization on scanner
# Settings → Developer Options → Revoke USB Debugging Authorizations
# Then reconnect and reauthorize
```

### Device Not Detected

```bash
# Check device status
adb devices -l

# Try different USB connection mode
# On scanner: swipe down notifications → tap USB → change to "File Transfer"

# Check for conflicting processes
ps aux | grep adb

# Try wireless ADB (if scanner supports it)
# On scanner: Developer Options → Wireless debugging → enable
adb tcpip 5555
adb connect <scanner-ip>:5555
adb devices
```

### Package Not Found

```bash
# Dump all packages with detailed info
adb shell pm list packages -f -3 > ~/Desktop/user_packages.txt
adb shell pm list packages -f -s > ~/Desktop/system_packages.txt

# Search more broadly
cat ~/Desktop/user_packages.txt | grep -i "scan\|raven\|avision\|document"

# Check running processes
adb shell ps | grep -i "scan\|raven"

# Check running services
adb shell dumpsys activity services | grep -i "scan\|raven"
```

### Extraction Failed

```bash
# Try copying to accessible location first
adb shell cp /data/app/com.raven.scanner-xyz/base.apk /sdcard/Download/raven.apk
adb pull /sdcard/Download/raven.apk ~/Desktop/raven.apk

# Check available space
adb shell df -h

# Verify APK path exists
adb shell ls -la /data/app/com.raven.scanner-xyz/
```

---

## 📝 What to Look For in Decompiled Code

### Scanner Hardware Interface

Look in JADX decompiled code:

**Key Classes:**
- `*Scanner*` classes
- `*Device*` classes  
- `*Hardware*` classes
- `*Driver*` classes

**Key Methods:**
- `initScanner()`
- `scan()`
- `getScannerStatus()`
- JNI native methods (will have `native` keyword)

**Example search:**
```bash
cd raven-jadx-output/sources
grep -r "native.*scan" .
grep -r "System.loadLibrary" .
```

### SMB Implementation

**Look for:**
- Package imports: `jcifs.*` or `com.hierynomus.smbj.*`
- SMB connection code
- Authentication handling
- File transfer logic

**Example search:**
```bash
grep -r "import.*smb" .
grep -r "SmbFile\|SmbClient" .
grep -r "NtlmPasswordAuthentication" .
```

### Plugin Loading Mechanism

**Look for:**
- Plugin package names
- APK loading code
- Dynamic class loading
- Plugin verification/signature checks

**Example search:**
```bash
grep -r "plugin" . | grep -i "load\|install"
grep -r "DexClassLoader\|PathClassLoader" .
grep -r "PackageManager.*installPackage" .
```

### Update Mechanism

**Look for:**
- Update URLs/endpoints
- APK download code
- Version checking
- Update installation

**Example search:**
```bash
grep -r "update" . | grep -i "url\|endpoint\|download"
grep -r "VERSION_CODE\|VERSION_NAME" .
```

---

## 📊 Analysis Checklist

After extraction, document:

- [ ] **Package name found:** `_______________`
- [ ] **APK size:** `_______________`
- [ ] **Number of split APKs:** `_______________`
- [ ] **Min Android version:** `_______________` (from AndroidManifest.xml)
- [ ] **Target Android version:** `_______________` (from AndroidManifest.xml)
- [ ] **Permissions used:** (list critical ones)
- [ ] **Native libraries found:** (list .so files)
- [ ] **SMB library identified:** Yes / No - `_______________`
- [ ] **Scanner interface identified:** Yes / No - Class: `_______________`
- [ ] **Plugin system identified:** Yes / No
- [ ] **Update mechanism found:** Yes / No - URL: `_______________`
- [ ] **Debug code present:** Yes / No
- [ ] **Obfuscation detected:** Yes / No (ProGuard/R8)

---

## 🎯 Quick Reference Commands

```bash
# === SETUP ===
brew install --cask android-platform-tools jadx apktool

# === CONNECTION ===
adb start-server
adb devices
adb kill-server && adb start-server  # Reset

# === PACKAGE DISCOVERY ===
adb shell pm list packages -f | grep -i raven
adb shell pm path com.raven.scanner

# === EXTRACTION ===
adb pull /data/app/com.raven.scanner-xyz/base.apk ./raven.apk

# === ANALYSIS ===
jadx-gui raven.apk
apktool d raven.apk -o raven-decompiled
unzip -l raven.apk | less

# === SEARCH ===
grep -r "keyword" raven-jadx-output/sources
find . -name "*.so"
```

---

## 📚 Additional Resources

### Tools
- **JADX:** https://github.com/skylot/jadx
- **APKTool:** https://ibotpeaches.github.io/Apktool/
- **dex2jar:** https://github.com/pxb1988/dex2jar
- **JD-GUI:** http://java-decompiler.github.io/

### Documentation
- **Android ADB:** https://developer.android.com/tools/adb
- **Android App Structure:** https://developer.android.com/guide/components/fundamentals
- **APK Format:** https://en.wikipedia.org/wiki/Apk_(file_format)

### Previous Research
- **Transcript:** `/mnt/transcripts/2026-01-13-22-09-13-raven-scanner-reverse-engineering-research.txt`
- **GitHub Repo:** https://github.com/cbrooker/Raven-Scanner-Wiki
- **FCC Database:** https://fccid.io/YAI2213

---

## ⚠️ Important Notes

1. **Legal:** Only extract and analyze apps you own for personal use
2. **Backup:** Keep original APK files - never modify scanner's system files
3. **Safety:** This is read-only extraction - no risk to scanner
4. **Privacy:** APK may contain credentials/tokens - don't share publicly
5. **Version:** Raven service shut down 12/31/2023 - scanner still works offline

---

## 🎉 Success Indicators

You've successfully extracted the APK if you see:

```
✅ adb devices shows your scanner
✅ Package name identified
✅ base.apk downloaded (several MB in size)
✅ JADX opens and shows Java code
✅ AndroidManifest.xml is readable
✅ Native libraries (.so files) extracted
```

---

**Questions? Issues?**

Common problems and solutions are in the Troubleshooting section above.

For Warp-specific features:
- Use Cmd+Shift+C to copy command blocks
- Use Cmd+R to search command history
- Use Cmd+D to open new terminal splits
- Use Cmd+T for new tabs

**Happy analyzing! 🔍**
