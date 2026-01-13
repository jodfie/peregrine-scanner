# Raven Scanner Reverse Engineering Notebook

> Living research notebook for the Raven Document Scanner (Avision AN335W white-label / InnoComm "Puzzle-B3").
>
> This document is structured so it can later be migrated directly into a GitHub Wiki page.

---

## 1. Overview

### 1.1 Goals

- Document the hardware, firmware, and software architecture of the Raven Scanner.
- Enable operation of the device after vendor cloud shutdown.
- Provide a foundation for potential community-run APIs or replacement software.

### 1.2 High-Level Facts (Snapshot)

- **Device name**: Raven Scanner
- **Hardware OEM**: Avision (AN335W white-label)
- **Regulatory platform**: InnoComm "Puzzle-B3"
- **FCC ID**: YAI2213
- **Operating system**: Android-based (touchscreen interface, app updates via APK)
- **Scanner features** (from product docs / reviews): SMB/FTP/FTPS/SFTP, Email, USB, multiple cloud destinations, built-in OCR, 8" touchscreen UI.
- **Cloud status**: Raven cloud services shut down 2023-12-31; device can still operate in offline / non-Raven modes.

> Keep this section short and periodically updated as new high-confidence facts are discovered.

---

## 2. Hardware Profile

### 2.1 Regulatory & Identification

- **FCC ID**: YAI2213
- **Certifying company**: InnoComm Mobile Technology Corp. (Taiwan)
- **Equipment class**: DTS (2.4 GHz WiFi, 2.412–2.462 GHz, ~361 mW output)

#### 2.1.1 Source Links

- FCC listing for YAI2213 (internal photos, external photos, RF reports, etc.).
- Internal photos: _link to `Internal-Photos-rev-3129652.pdf` once saved locally or bookmarked_.

_(Schematics and detailed block diagrams appear to be confidential in FCC filings; only high-level artifacts are publicly accessible.)_

### 2.2 Board-Level Components

> Populate this section from FCC internal photos and physical inspection.

- **Main SoC**: _(to be identified from silkscreen in internal photos)_
- **RAM**: _(capacity, package)_
- **Flash storage**: _(e.g., eMMC, capacity)_
- **WiFi module**: _(chipset / module name)_
- **Other notable ICs**: _(e.g., PMICs, USB PHY, etc.)_

### 2.3 Debug & Expansion Interfaces

- **UART headers**: _(location, pin count, likely pinout if known)_
- **JTAG / SWD**: _(any identified headers or test pads)_
- **Other connectors**: _(e.g., SD card, internal USB, etc.)_

---

## 3. Firmware & OS Profile

### 3.1 Android Build Information

> Fill with `adb shell getprop` and manifest data once ADB is accessible.

- **Android version**: _unknown_
- **SDK level**: _unknown_
- **Build fingerprint**: _unknown_
- **Build ID**: _unknown_
- **Security patch level**: _unknown_

#### 3.1.1 Commands Used

- `adb shell getprop ro.build.fingerprint`
- `adb shell getprop ro.build.version.release`
- `adb shell getprop ro.build.version.sdk`
- `adb shell getprop ro.product.model`

### 3.2 Boot & Update Mechanisms

- **Bootloader status**: _unknown (locked/unlocked?)_
- **Update mechanism**:
  - Updates appear to be delivered as APKs and installed through the Android package system.
  - Update flow observed: device downloads update → prompts to install → app named "Raven" updates → reboot.

_(Add details here as you reverse engineer the update path, URLs, and any signature checks.)_

---

## 4. Software Stack & Applications

### 4.0 Functional Overview (Observed / Documented)

> High-level software capabilities gathered from manuals, reviews, and prior research.

- Supports scanning to: SMB, FTP/FTPS/SFTP, email, USB, and various cloud destinations.
- Performs on-device OCR.
- Uses an Android app-based UX on an 8" touchscreen.

### 4.1 Package Inventory

> Discovered via `adb shell pm list packages -f` once ADB is functional.

- **Likely Raven / scanner packages** (hypotheses):
  - `com.raven.scanner`
  - `com.raven.app`
  - `com.avision.scanner`
  - `com.innocomm.scanner`

Maintain a table once confirmed:

- Package name | Role | Notes | APK path(s)
- ------------ | ---- | ----- | ----------

### 4.2 Extracted APKs

> Record every extraction session to ensure reproducibility.

- **Archive location(s)**: e.g. `~/Archive/raven/apk-originals/YYYY-MM-DD/`
- **Files**:
  - `raven-base.apk` – base app
  - `...` – split configuration APKs (if any)
- **Hashes**:
  - Record `sha256` hashes for each file.

### 4.3 Decompilation Artifacts

Document where analysis outputs live on disk and what each contains.

- **JADX output**: `raven-jadx-output/`
  - `sources/` – decompiled Java/Kotlin
- **APKTool output**: `raven-decompiled/`
  - `AndroidManifest.xml`
  - `smali/`, `res/`, `assets/`, `lib/`
- **dex / jar artifacts**: e.g. `raven.jar` from dex2jar

---

## 5. Key Subsystems Under Study

### 5.1 Scanner Hardware Interface

**Questions:**
- How does the app talk to the scan engine (native libraries, HAL, direct USB, other)?
- Are there JNI bindings that expose scan operations to Java/Kotlin code?

**Targets:**
- Classes matching `*Scanner*`, `*Device*`, `*Hardware*`, `*Driver*`.
- Methods like `initScanner()`, `scan()`, `getScannerStatus()`.
- `System.loadLibrary(...)` calls and corresponding `.so` files.

**Findings:**
- _[Add bullet points as you identify relevant classes, methods, and native libraries.]_

### 5.2 SMB / Network Storage Integration

**Questions:**
- Which SMB library is used (e.g., JCIFS, SMBJ, custom)?
- How are credentials and sessions managed?
- Are there hard-coded endpoints or assumptions?

**Search Targets:**
- Imports: `jcifs.*`, `com.hierynomus.smbj.*`, etc.
- Identifiers: `SmbFile`, `SMBClient`, `NtlmPasswordAuthentication`.

**Findings:**
- _[Record library choice, main connection/setup flows, and config formats.]_

### 5.3 Cloud & Update Mechanisms

**Questions:**
- How were cloud services integrated before shutdown?
- Is there a plugin or modular update system for features?
- How are APK updates discovered, downloaded, and validated?

**Search Targets:**
- `update`, `upgrade`, `plugin`, `DexClassLoader`, `PathClassLoader`.
- Network calls: HTTP(S) clients, known hostnames/URLs.

**Findings:**
- _[Document any discovered endpoints, update flows, and security checks.]_

---

## 6. Debug & Access Paths

### 6.1 Debug / Developer Mode

> Use this section to capture **exact steps** for entering debug mode or developer options on the device.

**Current knowledge from community reports (e.g., Bogleheads):**
- A "debug" or base firmware mode exists that boots into the underlying Avision software without the Raven overlay.
- In this mode, core scanning and network destinations continue to function without Raven cloud.

**To be documented with precise, reproducible steps:**
- Exact menu sequence and/or key combinations to enter debug/base Avision mode.
- Steps to enable Developer Options in Android (if exposed in this mode).
- Steps to enable USB Debugging.
- Any other hidden or engineering menus exposed in debug mode.

### 6.2 ADB Connectivity

- **Status**: _unknown_
- **Checklist:**
  - [ ] `adb devices` shows scanner as `device`.
  - [ ] USB authorization accepted on device screen.
  - [ ] Wireless ADB tested (if supported).

Record troubleshooting notes here (e.g., `adb kill-server`, cable issues, USB mode settings).

---

## 7. Network Behaviour & Protocols

### 7.1 SMB/FTP/Cloud Traffic

> Summarize observations from packet captures (mitmproxy, tcpdump, Wireshark).

- Capture setup (topology, tools, certificates installed on device, etc.).
- Protocols observed (SMB, FTP/FTPS/SFTP, HTTPS).
- Authentication methods (plain password, NTLM, tokens, etc.).

### 7.2 Local Services & Ports

- Any services exposed by the scanner on the LAN.
- Ports and protocols identified via scanning.

---

## 8. Current Workarounds (Non-RE Operation)

> Operational notes for using the device while reverse engineering is ongoing.

**Confirmed from community reports:**
- A base Avision/debug mode allows operation without Raven cloud, while still supporting core scanning.
- Vendor TWAIN drivers allow USB-connected scanning from PC/Mac.
- SMB network share scanning continues to function post-cloud-shutdown.
- Some built-in cloud integrations (e.g., Google Drive, Dropbox) may still function independently of Raven cloud.

**To be further detailed:**
- Exact configuration steps and limitations for each of the above.
- Any quirks, reliability issues, or performance notes.

---

## 9. Open Questions & TODOs

Track unresolved research items here. This section should stay short and actively maintained.

- **OS / security profile**
  - [ ] Exact Android version and security patch level.
  - [ ] Bootloader locked/unlocked? Any OEM unlock options?
  - [ ] SELinux status (enforcing/permissive) and other hardening measures.
- **Developer / low-level access**
  - [ ] Reliable method to enable Developer Options and USB Debugging.
  - [ ] Whether ADB is exposed over USB and/or network; any authentication prompts.
  - [ ] Viable paths (if any) to root or otherwise gain privileged access.
  - [ ] Whether a bootloader unlock or custom firmware path is realistic.
- **Permissions & capabilities**
  - [ ] List effective app permissions from `AndroidManifest.xml`.
  - [ ] Note any sensitive or unusual permissions.
- **Update / replacement paths**
  - [ ] Is it feasible to sideload alternative apps to handle scanning and destinations?
  - [ ] Does the device enforce signature verification for updates?
  - [ ] How updates are discovered, downloaded, and verified (URLs, signatures, fallback behavior).
- **Ecosystem / community state**
  - [ ] Depth of existing reverse engineering efforts (e.g., `cbrooker/Raven-Scanner-Wiki`).
  - [ ] Any in-progress open-source replacement apps or APIs.

---

## 10. Change Log

Use this section to track major discoveries and document edits. This makes it easier to port into a GitHub Wiki history later.

- **2026-01-13** – Initial notebook skeleton created in `docs/raven-research-notebook.md`.
- **2026-01-13** – Integrated initial desk research:
  - Documented Android-based OS, core scanning features, and Raven cloud shutdown.
  - Captured FCC ID YAI2213 context and noted available FCC artifacts.
  - Recorded existence of debug/base Avision mode and offline workarounds (TWAIN, SMB, cloud).
  - Enumerated major open questions around ADB, rooting, and update mechanisms.
- _[Add entries as you learn more or reorganize sections.]_
