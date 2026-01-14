#!/usr/bin/env bash
set -euo pipefail

# Raven Scanner archive fetch script
#
# This script downloads Raven manuals, quick start guides, drivers, and key
# support pages so they can be archived in this repo.
#
# It is designed to be idempotent: existing files are skipped when valid.
# If a file exists but is 0 bytes or its checksum does not match the last
# recorded value, it will be re-downloaded.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS_DIR="$ROOT_DIR/docs"
DOWNLOADS_DIR="$ROOT_DIR/downloads"
SUPPORT_DIR="$DOCS_DIR/support"
SITE_DIR="$DOCS_DIR/site"
CHECKSUM_FILE="$ROOT_DIR/raven-checksums-sha256.txt"

mkdir -p \
  "$DOCS_DIR/manuals/original-1st-gen" \
  "$DOCS_DIR/manuals/original-2nd-gen" \
  "$DOCS_DIR/manuals/pro" \
  "$DOCS_DIR/manuals/pro-max" \
  "$DOCS_DIR/manuals/standard-usb" \
  "$DOCS_DIR/manuals/compact-usb" \
  "$DOCS_DIR/manuals/compact-wifi" \
  "$DOCS_DIR/manuals/go-simplex-usb" \
  "$DOCS_DIR/manuals/go-duplex-usb" \
  "$SUPPORT_DIR" \
  "$SITE_DIR" \
  "$DOWNLOADS_DIR/drivers/original-1st-gen" \
  "$DOWNLOADS_DIR/drivers/original-2nd-gen" \
  "$DOWNLOADS_DIR/drivers/pro" \
  "$DOWNLOADS_DIR/drivers/pro-max" \
  "$DOWNLOADS_DIR/drivers/standard" \
  "$DOWNLOADS_DIR/drivers/compact" \
  "$DOWNLOADS_DIR/drivers/go" \
  "$DOWNLOADS_DIR/software" \
  "$DOWNLOADS_DIR/cdn-extra"

log() {
  printf '%s\n' "$*" >&2
}

# Look up the previously recorded SHA-256 checksum for a given file path, if any.
lookup_checksum() {
  local abs_path="$1"
  local rel_path

  # Normalize to path relative to ROOT_DIR to match raven-checksums-sha256.txt
  rel_path="${abs_path#"$ROOT_DIR/"}"

  if [[ -f "$CHECKSUM_FILE" ]]; then
    awk -v f="$rel_path" '$2 == f { print $1; exit }' "$CHECKSUM_FILE"
  fi
}

# Decide whether an existing file is valid based on size and (if available)
# checksum data. Returns 0 if the file is valid and can be skipped, 1 if it
# should be re-downloaded.
needs_redownload() {
  local dest="$1"

  # Re-download empty files
  if [[ ! -s "$dest" ]]; then
    log "[redo] $dest exists but is 0 bytes; re-downloading"
    return 1
  fi

  # If shasum or checksum file is missing, we can't validate further
  if ! command -v shasum >/dev/null 2>&1 || [[ ! -f "$CHECKSUM_FILE" ]]; then
    log "[skip] $dest (exists; no checksum validation available)"
    return 0
  fi

  local expected actual
  expected="$(lookup_checksum "$dest")"

  # No prior checksum recorded – treat as needing refresh so it gets captured
  if [[ -z "$expected" ]]; then
    log "[redo] $dest exists but has no recorded checksum; re-downloading"
    return 1
  fi

  actual="$(shasum -a 256 "$dest" | awk '{print $1}')"

  if [[ "$actual" == "$expected" ]]; then
    log "[skip] $dest (exists; checksum OK)"
    return 0
  else
    log "[redo] $dest exists but checksum mismatch; re-downloading"
    return 1
  fi
}

download() {
  local url="$1"
  local dest="$2"

  if [[ -f "$dest" ]]; then
    if ! needs_redownload "$dest"; then
      return 0
    fi
  fi

  log "[get ] $url -> $dest"
  if ! curl -fL "$url" -o "$dest"; then
    log "[fail] $url (download error)"
    rm -f "$dest" || true
  fi
}

# Download an HTML page via Wayback Machine (latest snapshot)
download_wayback() {
  local url="$1"   # e.g. https://support.raven.com/hc/en-us/...
  local dest="$2"

  if [[ -f "$dest" ]]; then
    if ! needs_redownload "$dest"; then
      return 0
    fi
  fi

  local wb_url="https://web.archive.org/web/0/$url"
  log "[wb  ] $wb_url -> $dest"
  if ! curl -fL "$wb_url" -o "$dest"; then
    log "[fail-wb] $wb_url (download error)"
    rm -f "$dest" || true
  fi
}

log "Root directory: $ROOT_DIR"

###############################################################################
# Manuals & Quick Start Guides (PDFs)
###############################################################################

# Raven Original 1st Gen
# User Manual
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Raven_Original_Scanner_User_Manual_122020.pdf?v=1608228742" \
  "$DOCS_DIR/manuals/original-1st-gen/Raven_Original_1st_Gen_User_Manual_122020.pdf"

# Quick Start Guide (EN)
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Original_QuickStart_Guide-V5.pdf?50688=" \
  "$DOCS_DIR/manuals/original-1st-gen/Raven_Original_1st_Gen_QuickStart_EN.pdf"

# Raven Original 2nd Gen
# User Manual
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Raven_Scanner_Original_2nd_Gen_User_Manual_03142022.pdf?v=1647268445" \
  "$DOCS_DIR/manuals/original-2nd-gen/Raven_Original_2nd_Gen_User_Manual_03142022.pdf"

# Quick Start Guide (EN)
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Original-2nd-gen-White_QuickStart_Guide.pdf" \
  "$DOCS_DIR/manuals/original-2nd-gen/Raven_Original_2nd_Gen_QuickStart_EN.pdf"

# Raven Pro (1st gen)
# User Manual
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Raven_Scanner_Pro_User_Manual.docx_7.pdf?v=1677039931" \
  "$DOCS_DIR/manuals/pro/Raven_Pro_User_Manual.pdf"

# Raven Pro Max
# User Manual
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Raven_Scanner_Pro_Max_User_Manual.pdf?v=1648145912" \
  "$DOCS_DIR/manuals/pro-max/Raven_Pro_Max_User_Manual_01132023.pdf"

# Quick Start Guide (EN)
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Raven_Pro_Max_Quick_Start_Guide_English.pdf?v=1677027777" \
  "$DOCS_DIR/manuals/pro-max/Raven_Pro_Max_QuickStart_EN.pdf"

# Raven Standard USB
# User Manual
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Raven_Standard_Scanner_User_Manual_USB_02142022.pdf?v=1644865526" \
  "$DOCS_DIR/manuals/standard-usb/Raven_Standard_USB_User_Manual_02142022.pdf"

# Quick Start Guide (EN)
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Standard_QuickStart_Guide_USB_EN.pdf?v=1621257082" \
  "$DOCS_DIR/manuals/standard-usb/Raven_Standard_USB_QuickStart_EN.pdf"

# Quick Start Guide (ES)
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Standard_QuickStart_Guide_USB_SP.pdf?v=1621257082" \
  "$DOCS_DIR/manuals/standard-usb/Raven_Standard_USB_QuickStart_ES.pdf"

# Raven Compact USB
# User Manual
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Raven_Compact_Scanner_User_Manual_USB_.docx.pdf?v=1644528494" \
  "$DOCS_DIR/manuals/compact-usb/Raven_Compact_USB_User_Manual.pdf"

# Quick Start Guide (EN)
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Compact_QuickStart_Guide_EN.pdf?v=1614737704" \
  "$DOCS_DIR/manuals/compact-usb/Raven_Compact_USB_QuickStart_EN.pdf"

# Quick Start Guide (ES)
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Compact_QuickStart_Guide_SP.pdf?v=1614737704" \
  "$DOCS_DIR/manuals/compact-usb/Raven_Compact_USB_QuickStart_ES.pdf"

# Raven Compact WiFi
# User Manual
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Raven_Compact_Scanner_User_Manual_WIFI.docx-5.pdf?v=1644529078" \
  "$DOCS_DIR/manuals/compact-wifi/Raven_Compact_WiFi_User_Manual.pdf"

# Quick Start Guide (EN)
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Compact_WIFI_QuickStart_Guide_EN_2020.pdf?v=1613830582" \
  "$DOCS_DIR/manuals/compact-wifi/Raven_Compact_WiFi_QuickStart_EN.pdf"

# Quick Start Guide (ES)
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Compact_WIFI_QuickStart_Guide_SP_2020.pdf?v=1613830582" \
  "$DOCS_DIR/manuals/compact-wifi/Raven_Compact_WiFi_QuickStart_ES.pdf"

# Raven Go (Simplex USB)
# User Manual
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Raven_Go_User_Manual_Simplex_USB_.pdf?v=1641320708" \
  "$DOCS_DIR/manuals/go-simplex-usb/Raven_Go_Simplex_USB_User_Manual.pdf"

# Raven Go (Duplex USB)
# User Manual
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Raven_Go_User_Manual_Duplex_USB_.pdf?v=1641320869" \
  "$DOCS_DIR/manuals/go-duplex-usb/Raven_Go_Duplex_USB_User_Manual.pdf"

# Raven Go Quick Start Guide (covers both Simplex & Duplex)
# Quick Start Guide (EN)
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Go_QuickStart_Guide_EN.pdf?v=1639160170" \
  "$DOCS_DIR/manuals/go-duplex-usb/Raven_Go_QuickStart_EN.pdf"

# Quick Start Guide (ES)
download \
  "https://cdn.shopify.com/s/files/1/0236/9286/9696/files/Go_QuickStart_Guide_SP.pdf?v=1639160170" \
  "$DOCS_DIR/manuals/go-duplex-usb/Raven_Go_QuickStart_ES.pdf"

###############################################################################
# Drivers & utilities (TWAIN / ICA / VSL)
###############################################################################

# Raven Original 1st Gen
# Windows TWAIN driver
download \
  "https://storage.googleapis.com/raven-185914.appspot.com/Drivers/Raven%20Scanner%20Original%20V6.0.0.1%20Build1000.zip" \
  "$DOWNLOADS_DIR/drivers/original-1st-gen/Raven_Original1_Windows_TWAIN.zip"

# Mac ICA driver
download \
  "https://storage.googleapis.com/raven-185914.appspot.com/Drivers/Raven%20ICA%20Scanner_V1.0.0.3.dmg" \
  "$DOWNLOADS_DIR/drivers/original-1st-gen/Raven_Original1_Mac_ICA.dmg"

# Raven Original 2nd Gen
# Windows TWAIN driver
download \
  "https://storage.googleapis.com/desktop.storage.raven.com/Drivers/production/windows/Original2.zip" \
  "$DOWNLOADS_DIR/drivers/original-2nd-gen/Original2_Windows_TWAIN.zip"

# Mac TWAIN/ICA driver (Raven A driver, used by multiple models)
download \
  "https://storage.googleapis.com/desktop.storage.raven.com/Drivers/production/mac/Raven-A-Driver-latest.pkg" \
  "$DOWNLOADS_DIR/drivers/original-2nd-gen/Raven_A_Driver_Mac_TWAIN.pkg"

# Raven Pro (1st gen) & Pro Max
# Windows TWAIN driver
download \
  "https://storage.googleapis.com/raven-185914.appspot.com/Drivers/Raven_Scanner_Pro_Windows_Driver_20200408.zip" \
  "$DOWNLOADS_DIR/drivers/pro/Raven_Pro_Windows_TWAIN_20200408.zip"

# Mac TWAIN driver (Raven A driver, shared pkg)
download \
  "https://storage.googleapis.com/desktop.storage.raven.com/Drivers/production/mac/Raven-A-Driver-latest.pkg" \
  "$DOWNLOADS_DIR/drivers/pro/Raven_A_Driver_Mac_TWAIN.pkg"

# Pro Wireless TWAIN link (Windows)
download \
  "https://storage.googleapis.com/raven-185914.appspot.com/Drivers/Raven_Pro_VSL20191121.zip" \
  "$DOWNLOADS_DIR/drivers/pro/Raven_Pro_Virtual_Scanner_Link_Windows_20191121.zip"

# Pro Virtual Scanner Link (Mac)
download \
  "https://storage.googleapis.com/desktop.storage.raven.com/Drivers/production/mac/Virtual%20Scanner%20Link.zip" \
  "$DOWNLOADS_DIR/drivers/pro/Raven_Pro_Virtual_Scanner_Link_Mac.zip"

# Raven Pro Max uses same TWAIN/Virtual Scanner packages as Pro
download \
  "https://storage.googleapis.com/desktop.storage.raven.com/Drivers/production/mac/Raven-A-Driver-latest.pkg" \
  "$DOWNLOADS_DIR/drivers/pro-max/Raven_A_Driver_Mac_TWAIN.pkg"

download \
  "https://storage.googleapis.com/raven-185914.appspot.com/Drivers/Raven_Scanner_Pro_Windows_Driver_20200408.zip" \
  "$DOWNLOADS_DIR/drivers/pro-max/Raven_ProMax_Windows_TWAIN_20200408.zip"

# Raven Standard (USB)
# Windows TWAIN driver
download \
  "https://storage.googleapis.com/desktop.storage.raven.com/Drivers/production/windows/Raven%20Standard.zip" \
  "$DOWNLOADS_DIR/drivers/standard/Raven_Standard_Windows_TWAIN.zip"

# Mac TWAIN driver (Raven A driver, shared)
download \
  "https://storage.googleapis.com/desktop.storage.raven.com/Drivers/production/mac/Raven-A-Driver-latest.pkg" \
  "$DOWNLOADS_DIR/drivers/standard/Raven_A_Driver_Mac_TWAIN.pkg"

# Raven Compact (USB & WiFi variants share drivers)
# Windows TWAIN driver
download \
  "https://storage.googleapis.com/desktop.storage.raven.com/Drivers/production/windows/Raven%20Compact.zip" \
  "$DOWNLOADS_DIR/drivers/compact/Raven_Compact_Windows_TWAIN.zip"

# Mac TWAIN driver (Raven A driver, shared)
download \
  "https://storage.googleapis.com/desktop.storage.raven.com/Drivers/production/mac/Raven-A-Driver-latest.pkg" \
  "$DOWNLOADS_DIR/drivers/compact/Raven_A_Driver_Mac_TWAIN.pkg"

# Raven Go (Simplex & Duplex USB)
# Windows TWAIN driver
download \
  "https://storage.googleapis.com/desktop.storage.raven.com/Drivers/production/windows/Go.zip" \
  "$DOWNLOADS_DIR/drivers/go/Raven_Go_Windows_TWAIN.zip"

# Mac TWAIN driver (Raven A driver, shared)
download \
  "https://storage.googleapis.com/desktop.storage.raven.com/Drivers/production/mac/Raven-A-Driver-latest.pkg" \
  "$DOWNLOADS_DIR/drivers/go/Raven_A_Driver_Mac_TWAIN.pkg"

###############################################################################
# Raven site pages (HTML snapshots)
###############################################################################

# Main downloads page
download \
  "https://raven.com/pages/downloads" \
  "$SITE_DIR/raven-downloads.html"

# User manuals index (older generation overview)
download \
  "https://raven.com/pages/user-manuals" \
  "$SITE_DIR/raven-user-manuals.html"

# Frequently Asked Questions
download \
  "https://raven.com/pages/frequently-asked-questions" \
  "$SITE_DIR/raven-faq.html"

# Raven Desktop product page
download \
  "https://raven.com/pages/desktop" \
  "$SITE_DIR/raven-desktop.html"

###############################################################################
# Support center & key articles via Wayback (HTML)
###############################################################################

# Help Center home (support.raven.com)
download_wayback \
  "https://support.raven.com/hc/en-us" \
  "$SUPPORT_DIR/support-raven-help-center.html"

# Raven Scanner Return Policy
# (original URL now dead; fetch via Wayback)
download_wayback \
  "https://support.raven.com/hc/en-us/articles/360028216192-Raven-Scanner-Return-Policy" \
  "$SUPPORT_DIR/360028216192-Raven-Scanner-Return-Policy.html"

# Scanning to Windows PC from Raven Scanner Pro using Network TWAIN
download_wayback \
  "https://support.raven.com/hc/en-us/articles/360031724051-Scanning-to-Windows-PC-from-Raven-Scanner-Pro" \
  "$SUPPORT_DIR/360031724051-Scanning-to-Windows-PC-from-Raven-Scanner-Pro.html"

# Scanning to your Mac from Raven Scanner Pro (Zendesk-hosted; archive via Wayback)
download_wayback \
  "https://starfish.zendesk.com/hc/en-us/articles/360033057632-Scanning-To-Your-Mac-From-Raven-Scanner-Pro" \
  "$SUPPORT_DIR/360033057632-Scanning-To-Your-Mac-From-Raven-Scanner-Pro.html"

###############################################################################
# Shopify CDN discovery & mirror
###############################################################################

# Scan archived HTML for Shopify CDN URLs and write an inventory file.
if command -v grep >/dev/null 2>&1; then
  log "Scanning archived HTML for Shopify CDN URLs..."
  (
    cd "$ROOT_DIR"
    find docs downloads -type f -name '*.html' -print0 \
      | xargs -0 grep -hoE 'https://cdn\\.shopify\\.com[^"[:space:]]+' \
      | sort -u > docs/shopify-cdn-urls.txt || true
  )
  log "Shopify CDN URL inventory written to docs/shopify-cdn-urls.txt"
else
  log "grep not found; skipping Shopify CDN URL scan"
fi

# Download any additional Shopify CDN assets referenced in HTML that don't yet
# have a matching local file.
if [[ -f "$DOCS_DIR/shopify-cdn-urls.txt" ]] && command -v curl >/dev/null 2>&1; then
  log "Ensuring all discovered Shopify CDN URLs have local copies..."
  while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    base="${url%%\?*}"
    base="$(basename "$base")"
    dest="$(find "$DOCS_DIR" "$DOWNLOADS_DIR" -name "$base" -print -quit || true)"
    if [[ -n "$dest" ]]; then
      log "[have-cdn] $url -> $dest"
      continue
    fi
    local_target="$DOWNLOADS_DIR/cdn-extra/$base"
    log "[get-cdn] $url -> $local_target"
    if curl -fL "$url" -o "$local_target"; then
      :
    else
      log "[fail-cdn] $url"
      rm -f "$local_target" || true
    fi
  done < "$DOCS_DIR/shopify-cdn-urls.txt"
fi

###############################################################################
# Checksums
###############################################################################

if command -v shasum >/dev/null 2>&1; then
  log "Generating SHA-256 checksums (docs & drivers)..."
  (
    cd "$ROOT_DIR"
    find docs downloads \
      -type f \
      \( -name '*.pdf' -o -name '*.zip' -o -name '*.pkg' -o -name '*.dmg' -o -name '*.html' \) \
      -print0 | sort -z | xargs -0 shasum -a 256 > raven-checksums-sha256.txt
  )
  log "Checksums written to raven-checksums-sha256.txt"
else
  log "shasum not found; skipping checksum generation"
fi

log "Done."
