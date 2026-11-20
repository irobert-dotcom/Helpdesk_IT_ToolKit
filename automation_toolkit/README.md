# IT Helpdesk Automation Toolkit for Windows

An enterprise-grade, automated diagnostic, repair, and maintenance suite designed specifically for IT Helpdesk engineers, system administrators, and technical support teams. 

This toolkit provides an interactive terminal interface matching the exact 15-module system structure, capable of running smoothly in Windows Command Prompt (`cmd.exe`), Git Bash, MSYS2, or WSL.

---

## 📂 Toolkit File Structure

| File | Purpose | Environment |
| :--- | :--- | :--- |
| **`it_helpdesk_toolkit.sh`** | **Primary Bash Script** with full ANSI colors, safe PowerShell integration, and diagnostics. | Git Bash, WSL, MSYS2, or Windows CMD (`bash it_helpdesk_toolkit.sh`) |
| **`it_helpdesk_toolkit.bat`** | **Native Windows Batch Script** with zero dependencies, runs natively in standard Command Prompt. | Windows CMD (`cmd.exe`), Run as Administrator, or Double-Click |
| **`run_in_cmd.bat`** | **Universal Launcher** that auto-detects Git Bash/WSL on the machine and launches the bash script, or falls back to native batch. | Windows CMD or Desktop Shortcut |
| **`IT_Helpdesk_Reports/`** | Automatically created output directory for generated HTML and Text diagnostic reports. | Auto-generated |

---

## 🚀 How to Run in Windows Command Prompt (`cmd.exe`)

### Method 1: Universal Launcher (Recommended)
Simply open Windows Command Prompt or PowerShell, navigate to this folder, and run:
```cmd
run_in_cmd.bat
```
*Or double-click `run_in_cmd.bat` from Windows File Explorer.*

### Method 2: Direct Bash Execution (Git Bash / WSL / Git in PATH)
If Git for Windows or Git Bash is installed:
```cmd
bash it_helpdesk_toolkit.sh
```
Or with full path if `bash` is not in your system `%PATH%`:
```cmd
"C:\Program Files\Git\bin\bash.exe" it_helpdesk_toolkit.sh
```

### Method 3: Native Windows Batch (Zero Prerequisites)
If the target computer does not have Git or Bash installed (e.g. fresh Windows deployment):
```cmd
it_helpdesk_toolkit.bat
```

> [!NOTE]
> **WSL Dummy Alias Notice**: Windows 10/11 includes a stub alias at `AppData\Local\Microsoft\WindowsApps\bash.exe`. The included `run_in_cmd.bat` automatically bypasses this stub and locates genuine Git Bash (`C:\Program Files\Git\bin\bash.exe`), or seamlessly falls back to the native `it_helpdesk_toolkit.bat`.

> [!TIP]
> **Administrator Privileges**: While basic diagnostics (System specs, RAM, CPU, Battery, Startup items, Office/Windows activation) run under standard user accounts, maintenance tasks such as **SFC**, **DISM**, **Prefetch cleanup**, and **Service restarts** require Administrator elevation. Right-click your Command Prompt and select **"Run as administrator"** for full capabilities.

---

## 🖥️ System Structure & Menu

```text
================================================
       IT HELPDESK AUTOMATION TOOLKIT
================================================

 [1]  Full Laptop Health Check
 [2]  Virus & Malware Scan
 [3]  Update All Installed Applications
 [4]  Windows Update
 [5]  Microsoft Office Activation Check
 [6]  Windows Activation Check
 [7]  Disk Cleanup & Temporary Files
 [8]  RAM & CPU Performance Check
 [9]  Network & Internet Diagnostics
 [10] Startup Programs Inspection
 [11] Windows Services Check
 [12] Hardware & Battery Diagnostics
 [13] Generate IT Helpdesk Report
 [14] Run Complete Maintenance
 [15] Exit

================================================
 IT HELPDESK - SYSTEM MAINTENANCE
================================================
```

---

## 🔍 Module Details

### [1] Full Laptop Health Check
- Queries system make, model, serial number, OS build, and uptime.
- Inspects CPU load and memory utilization baseline.
- Scans all local storage partitions (C:, D:, etc.), flagging any drive with < 15% free space.
- Checks laptop battery presence, charge level, and capacity wear level.
- Checks Windows Defender Real-Time Protection and Windows activation state.
- Computes an overall diagnostic verdict: `[PASSED]`, `[WARNING]`, or `[CRITICAL]`.

### [2] Virus & Malware Scan
- Audits Windows Defender engine, signature update timestamp, and real-time status.
- Interactive actions:
  - **1**: Update definitions to latest Microsoft signatures (`MpCmdRun.exe -SignatureUpdate`).
  - **2**: Run Quick Malware Scan on active memory and boot sectors (`Start-MpScan -ScanType QuickScan`).
  - **3**: Run Full System Scan across all storage devices (`Start-MpScan -ScanType FullScan`).
  - **4**: View recent threat detections from Windows event logs (`Get-MpThreatDetection`).

### [3] Update All Installed Applications
- Connects to Windows Package Manager (`winget`).
- Lists all outdated installed applications with current version and available version.
- Offers automated batch upgrade with `--accept-source-agreements` and `--accept-package-agreements`.

### [4] Windows Update
- Inspects Windows Update Service (`wuauserv`) and BITS service status.
- Queries the last installed Windows Update (KB number and date).
- Scans Windows Update Agent API for missing security and cumulative patches.
- Actions:
  - Trigger background update download via Windows Update Orchestrator (`usoclient StartScan / StartDownload`).
  - Open modern Windows Update Settings GUI (`ms-settings:windowsupdate`).
  - Display the last 10 installed KBs (`Get-HotFix`).
  - Restart hung Windows Update services.

### [5] Microsoft Office Activation Check
- Scans all 32-bit and 64-bit Office directories for the Software Protection Platform (`OSPP.VBS`):
  - Office 2016, 2019, 2021, 2024, and Microsoft 365.
- Queries `cscript.exe //nologo OSPP.VBS /dstatus` with XML noise filtering.
- Displays: License Name, License Status (`---LICENSED---`), partial product key, remaining grace days, and KMS host.
- Detects modern Microsoft 365 Click-to-Run configuration and licensing channels via registry.

### [6] Windows Activation Check
- Queries Software Licensing Manager (`slmgr.vbs /xpr` and `/dli`) in non-blocking console mode.
- Executes optimized WMI query to retrieve licensing status code, product edition, and license channel (Retail, OEM, Volume KMS/MAK).
- Formats a colored status badge indicating whether Windows is genuine and permanently activated.

### [7] Disk Cleanup & Temporary Files
- Measures baseline drive free space before purge.
- Safely purges:
  - User `%TEMP%` cache (`AppData\Local\Temp\*`).
  - System `%WINDIR%\Temp\*`.
  - Windows Update download cache (`%WINDIR%\SoftwareDistribution\Download\*`).
  - Windows Crash Dumps (`*.dmp`, `minidump\*`, `MEMORY.DMP`).
  - Empty Windows Recycle Bin across all drives.
  - Flushes DNS Resolver cache (`Clear-DnsClientCache`).
- Calculates and displays exact disk space reclaimed in Megabytes and Gigabytes.

### [8] RAM & CPU Performance Check
- **Processor**: Model, base clock speed, physical cores, logical processors, and live CPU load %.
- **Top 5 CPU Processes**: Enumerates processes consuming the highest CPU time with PID and memory footprint.
- **Physical Memory**: Total RAM (GB), Free RAM (GB), In-Use RAM (GB), and % utilization.
- **Top 5 Memory Processes**: Enumerates top RAM consumers sorted by Working Set size.
- Flags high load warnings if memory or processor exceeds 85%.

### [9] Network & Internet Diagnostics
- Displays active network adapter configuration (IPv4, Subnet Mask, Gateway, DNS, MAC, DHCP).
- Executes 4-stage network pipeline:
  1. Default Gateway Ping (LAN / Local Router).
  2. Public DNS Ping `8.8.8.8` (Internet WAN).
  3. DNS Domain Resolution for `google.com` (DNS Server health).
  4. TCP Port 443 Handshake to `https://www.google.com` (Web traffic accessibility).
- Displays Wi-Fi SSID, signal quality %, and radio type.
- Built-in repair tools: Flush DNS & renew DHCP (`ipconfig /release && /renew`) and reset Winsock/IP stack.

### [10] Startup Programs Inspection
- Enumerates all startup hooks across the operating system:
  - `HKLM\Software\Microsoft\Windows\CurrentVersion\Run`
  - `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
  - `HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run`
  - Common Startup Folder (`ProgramData\...\Startup`)
  - User Startup Folder (`AppData\...\Startup`)
- Formats table displaying program name, execution path/command, and registry location.

### [11] Windows Services Check
- Audits critical Windows system services:
  - `wuauserv` (Windows Update)
  - `bits` (Background Transfer)
  - `WinDefend` (Microsoft Defender)
  - `MpsSvc` (Windows Firewall)
  - `Spooler` (Print Spooler)
  - `Dnscache` (DNS Client)
  - `Dhcp` (DHCP Client)
  - `EventLog` (Windows Event Log)
  - `TermService` (Remote Desktop)
  - `W32Time` (Windows Time)
- Displays current state (`Running` / `Stopped`) and startup type.
- One-click repair action to start/recover any stopped essential services.

### [12] Hardware & Battery Diagnostics
- **Hardware Audit**: Motherboard manufacturer, board product name, serial number, BIOS version, release date, and physical disk SMART status.
- **Display Subsystem**: Video controllers, GPU driver version, and VRAM.
- **Battery Subsystem**:
  - Detects if device is a laptop or desktop/virtual machine.
  - On laptops: displays battery manufacturer, chemistry, charge %, design capacity, full charge capacity, and health wear percentage.
  - Generates official Microsoft HTML battery report (`powercfg /batteryreport`).

### [13] Generate IT Helpdesk Report
- Aggregates system metrics into two report formats in `IT_Helpdesk_Reports/`:
  1. **Plain Text Report (`.txt`)**: Formatted with ASCII boundaries, ideal for attaching or pasting directly into ticketing systems (ServiceNow, Jira, Zendesk).
  2. **Modern HTML Dashboard (`.html`)**: Features responsive CSS grid layout, colored status badges, storage capacity bars, and critical system event log entries from the last 24 hours.
- Prompts to open the generated report in default browser automatically.

### [14] Run Complete Maintenance
- Automated "one-click" tune-up sequence executing:
  1. Disk & Temporary File Cleanup.
  2. DNS Flush & Network Refresh.
  3. Antivirus Definition Updates & Quick Scan.
  4. Application Upgrades via Winget.
  5. Windows Component Store Health Scan (`DISM /ScanHealth`).
  6. System File Integrity Scan (`SFC /scannow`).
  7. Essential Services Verification.
  8. Generation of Final Post-Maintenance IT Diagnostic Report.

### [15] Exit
- Exits the toolkit cleanly.

---

## 🔒 Requirements & Compatibility
- **Operating System**: Windows 10, Windows 11, Windows Server 2016/2019/2022.
- **Shell**: Windows Command Prompt (`cmd.exe`), Git Bash (`bash`), or PowerShell.
- **Dependencies**: None required (native Windows CLI and PowerShell 5.1+ used).
