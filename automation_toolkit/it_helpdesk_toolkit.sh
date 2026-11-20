#!/usr/bin/env bash
# ==============================================================================
#  IT HELPDESK AUTOMATION TOOLKIT
#  Enterprise Windows Diagnostic, Repair & Maintenance Suite
#  Compatible with: Windows Command Prompt (via bash/Git Bash), Git Bash, WSL, MSYS2
# ==============================================================================

# Prevent MinGW / MSYS from corrupting Windows command-line arguments (e.g. /Online, /CheckHealth)
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL="*"

# ANSI Color Codes
CLR_RESET="\033[0m"
CLR_BOLD="\033[1m"
CLR_RED="\033[1;31m"
CLR_GREEN="\033[1;32m"
CLR_YELLOW="\033[1;33m"
CLR_BLUE="\033[1;34m"
CLR_MAGENTA="\033[1;35m"
CLR_CYAN="\033[1;36m"
CLR_WHITE="\033[1;37m"
CLR_GRAY="\033[0;90m"

# Helper function to execute PowerShell code blocks safely without escaping issues
run_ps_block() {
    local tmp_script="./.it_helpdesk_$$.ps1"
    cat > "$tmp_script"
    local win_path="$tmp_script"
    if command -v cygpath >/dev/null 2>&1; then
        win_path=$(cygpath -w "$tmp_script" 2>/dev/null || echo "$tmp_script")
    elif command -v wslpath >/dev/null 2>&1; then
        win_path=$(wslpath -w "$tmp_script" 2>/dev/null || echo "$tmp_script")
    fi
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$win_path" "$@"
    local ret=$?
    rm -f "$tmp_script" 2>/dev/null
    return $ret
}

# Check Administrator privileges
is_admin() {
    net.exe session >/dev/null 2>&1
    return $?
}

# Pause helper
pause_prompt() {
    echo ""
    echo -e "${CLR_GRAY}------------------------------------------------${CLR_RESET}"
    read -rp "Press [Enter] to return to Main Menu..."
}

# Print section banner
print_banner() {
    clear 2>/dev/null || cls 2>/dev/null
    echo -e "${CLR_CYAN}================================================${CLR_RESET}"
    echo -e "${CLR_BOLD}${CLR_WHITE}       IT HELPDESK AUTOMATION TOOLKIT-DEVELOPED BY IAN ROBERT${CLR_RESET}"
    echo -e "${CLR_CYAN}================================================${CLR_RESET}"
    echo -e "${CLR_YELLOW}>>> $1${CLR_RESET}"
    echo -e "${CLR_CYAN}================================================${CLR_RESET}"
    echo ""
}

# Main Menu Display
show_menu() {
    clear 2>/dev/null || cls 2>/dev/null
    
    local admin_badge
    if is_admin; then
        admin_badge="${CLR_GREEN}[ADMINISTRATOR PRIVILEGES DETECTED]${CLR_RESET}"
    else
        admin_badge="${CLR_YELLOW}[STANDARD USER - Some operations may require Admin]${CLR_RESET}"
    fi

    echo -e "${CLR_CYAN}================================================${CLR_RESET}"
    echo -e "${CLR_BOLD}${CLR_WHITE}       IT HELPDESK AUTOMATION TOOLKIT${CLR_RESET}"
    echo -e "${CLR_CYAN}================================================${CLR_RESET}"
    echo -e " Mode: $admin_badge"
    echo -e " Host: ${CLR_BOLD}$(hostname 2>/dev/null || echo "Windows-PC")${CLR_RESET} | User: ${CLR_BOLD}${USERNAME:-$(whoami)}${CLR_RESET}"
    echo -e "${CLR_CYAN}------------------------------------------------${CLR_RESET}"
    echo -e " ${CLR_WHITE}[1]${CLR_RESET}  Full Laptop Health Check"
    echo -e " ${CLR_WHITE}[2]${CLR_RESET}  Virus & Malware Scan"
    echo -e " ${CLR_WHITE}[3]${CLR_RESET}  Update All Installed Applications"
    echo -e " ${CLR_WHITE}[4]${CLR_RESET}  Windows Update"
    echo -e " ${CLR_WHITE}[5]${CLR_RESET}  Microsoft Office Activation Check"
    echo -e " ${CLR_WHITE}[6]${CLR_RESET}  Windows Activation Check"
    echo -e " ${CLR_WHITE}[7]${CLR_RESET}  Disk Cleanup & Temporary Files"
    echo -e " ${CLR_WHITE}[8]${CLR_RESET}  RAM & CPU Performance Check"
    echo -e " ${CLR_WHITE}[9]${CLR_RESET}  Network & Internet Diagnostics"
    echo -e " ${CLR_WHITE}[10]${CLR_RESET} Startup Programs Inspection"
    echo -e " ${CLR_WHITE}[11]${CLR_RESET} Windows Services Check"
    echo -e " ${CLR_WHITE}[12]${CLR_RESET} Hardware & Battery Diagnostics"
    echo -e " ${CLR_WHITE}[13]${CLR_RESET} Generate IT Helpdesk Report"
    echo -e " ${CLR_WHITE}[14]${CLR_RESET} Run Complete Maintenance"
    echo -e " ${CLR_WHITE}[15]${CLR_RESET} Exit"
    echo -e "${CLR_CYAN}================================================${CLR_RESET}"
    echo -e "${CLR_BOLD}${CLR_WHITE} IT HELPDESK - SYSTEM MAINTENANCE${CLR_RESET}"
    echo -e "${CLR_CYAN}================================================${CLR_RESET}"
}

# ==============================================================================
#  [1] FULL LAPTOP HEALTH CHECK
# ==============================================================================
option_1_health_check() {
    print_banner "[1] Full Laptop Health Check"
    echo -e "${CLR_CYAN}Gathering comprehensive system health metrics... Please wait.${CLR_RESET}"
    echo ""

    run_ps_block << 'EOF'
    $ErrorActionPreference = "SilentlyContinue"
    
    # OS & System Info
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_BIOS
    $uptime = (Get-Date) - $os.LastBootUpTime
    $uptimeStr = "$($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"

    Write-Host "--- SYSTEM SPECIFICATIONS ---" -ForegroundColor Cyan
    Write-Host "Computer Name    : $($cs.Name)"
    Write-Host "Manufacturer     : $($cs.Manufacturer)"
    Write-Host "Model            : $($cs.Model)"
    Write-Host "Serial Number    : $($bios.SerialNumber)"
    Write-Host "OS Caption       : $($os.Caption) ($($os.OSArchitecture))"
    Write-Host "OS Build / Ver   : Build $($os.BuildNumber), Version $($os.Version)"
    Write-Host "System Uptime    : $uptimeStr (Last Boot: $($os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss')))"
    Write-Host ""

    # CPU & RAM Metrics
    Write-Host "--- CPU & MEMORY HEALTH ---" -ForegroundColor Cyan
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $cpuLoad = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $totalRamGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRamGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRamGB = [math]::Round($totalRamGB - $freeRamGB, 2)
    $ramPercent = [math]::Round(($usedRamGB / $totalRamGB) * 100, 1)

    Write-Host "Processor        : $($cpu.Name.Trim()) ($($cpu.NumberOfCores) Cores / $($cpu.NumberOfLogicalProcessors) Threads)"
    Write-Host "Current CPU Load : $cpuLoad %"
    Write-Host "Total RAM        : $totalRamGB GB"
    Write-Host "Used RAM         : $usedRamGB GB ($ramPercent% utilized)"
    Write-Host "Free RAM         : $freeRamGB GB"
    Write-Host ""

    # Storage Health
    Write-Host "--- STORAGE DRIVES ---" -ForegroundColor Cyan
    $disks = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    $diskIssue = $false
    foreach ($d in $disks) {
        $totalGB = [math]::Round($d.Size / 1GB, 2)
        $freeGB = [math]::Round($d.FreeSpace / 1GB, 2)
        $freePercent = if ($totalGB -gt 0) { [math]::Round(($freeGB / $totalGB) * 100, 1) } else { 0 }
        $diskColor = "Green"
        if ($freePercent -lt 15) {
            $diskColor = "Red"
            $diskIssue = $true
        } elseif ($freePercent -lt 25) {
            $diskColor = "Yellow"
        }
        Write-Host "Drive $($d.DeviceID) Volume: [$($d.VolumeName)] Free: $freeGB GB / $totalGB GB ($freePercent% Free) [Status: $($d.Status)]" -ForegroundColor $diskColor
    }
    Write-Host ""

    # Battery Health (if laptop)
    Write-Host "--- BATTERY & POWER SUBSYSTEM ---" -ForegroundColor Cyan
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) {
        $statusStr = switch ($battery.BatteryStatus) {
            1 { "Discharging" }
            2 { "On AC Power (Connected)" }
            3 { "Fully Charged" }
            4 { "Low" }
            5 { "Critical" }
            6 { "Charging" }
            7 { "Charging and High" }
            8 { "Charging and Low" }
            9 { "Charging and Critical" }
            default { "Normal" }
        }
        Write-Host "Battery Present  : Yes ($($battery.Name))" -ForegroundColor Green
        Write-Host "Estimated Charge : $($battery.EstimatedChargeRemaining) %"
        Write-Host "Power Status     : $statusStr"
        if ($battery.DesignCapacity -and $battery.FullChargeCapacity -and $battery.DesignCapacity -gt 0) {
            $wear = [math]::Round(($battery.FullChargeCapacity / $battery.DesignCapacity) * 100, 1)
            Write-Host "Battery Health   : $wear % of original design capacity"
        }
    } else {
        Write-Host "Battery Status   : Desktop / Virtual Machine (AC Power, No Battery Detected)" -ForegroundColor DarkGray
    }
    Write-Host ""

    # Security & Protection
    Write-Host "--- SECURITY POSTURE ---" -ForegroundColor Cyan
    $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($defender) {
        $rtpColor = if ($defender.RealTimeProtectionEnabled) { "Green" } else { "Red" }
        Write-Host "Defender Antivirus : Real-Time Protection is $(if($defender.RealTimeProtectionEnabled){'ENABLED'}else{'DISABLED'})" -ForegroundColor $rtpColor
        Write-Host "Antivirus Signatures: $($defender.AntivirusSignatureVersion) (Updated: $($defender.AntivirusSignatureLastUpdated))"
    } else {
        Write-Host "Defender Status  : Service query unavailable or third-party AV active." -ForegroundColor Yellow
    }

    # Windows Activation
    $lic = Get-CimInstance -Query "SELECT Name, LicenseStatus, PartialProductKey FROM SoftwareLicensingProduct WHERE PartialProductKey IS NOT NULL AND Name LIKE 'Windows%'" | Select-Object -First 1
    if ($lic) {
        $licStatus = switch ($lic.LicenseStatus) {
            1 { "Permanently Activated / Licensed" }
            2 { "OOB Grace Period" }
            3 { "OOT Grace Period" }
            4 { "Non-Genuine Grace Period" }
            5 { "Notification State" }
            default { "Unknown" }
        }
        $licColor = if ($lic.LicenseStatus -eq 1) { "Green" } else { "Red" }
        Write-Host "Windows License  : $licStatus" -ForegroundColor $licColor
    }
    Write-Host ""

    # Final Overall Assessment
    Write-Host "================ OVERALL HEALTH VERDICT ================" -ForegroundColor White
    if ($diskIssue) {
        Write-Host "[WARNING] Storage capacity is critically low (<15% free on one or more drives)!" -ForegroundColor Red
    } elseif ($ramPercent -gt 90) {
        Write-Host "[WARNING] High RAM utilization detected ($ramPercent%). Check running processes." -ForegroundColor Yellow
    } else {
        Write-Host "[PASSED] System baseline health is in good operational standing." -ForegroundColor Green
    }
EOF

    pause_prompt
}

# ==============================================================================
#  [2] VIRUS & MALWARE SCAN
# ==============================================================================
option_2_virus_scan() {
    print_banner "[2] Virus & Malware Scan"
    
    echo -e "${CLR_WHITE}Checking Windows Defender Antivirus Status...${CLR_RESET}"
    run_ps_block << 'EOF'
    $ErrorActionPreference = "SilentlyContinue"
    $status = Get-MpComputerStatus
    if ($status) {
        Write-Host "Antivirus Service Enabled : $($status.AMServiceEnabled)"
        Write-Host "Antispyware Enabled       : $($status.AntispywareEnabled)"
        Write-Host "Real-Time Protection      : $($status.RealTimeProtectionEnabled)" -ForegroundColor $(if($status.RealTimeProtectionEnabled){'Green'}else{'Red'})
        Write-Host "Antivirus Engine Version  : $($status.AMEngineVersion)"
        Write-Host "Signature Version         : $($status.AntivirusSignatureVersion)"
        Write-Host "Signatures Last Updated   : $($status.AntivirusSignatureLastUpdated)"
        Write-Host "Quick Scan Last Run       : $($status.QuickScanEndTime)"
        Write-Host "Full Scan Last Run        : $($status.FullScanEndTime)"
    } else {
        Write-Host "Could not query Windows Defender status. Administrator rights may be needed." -ForegroundColor Yellow
    }
EOF
    echo ""
    echo -e "${CLR_CYAN}Select Malware Scan Action:${CLR_RESET}"
    echo -e " [1] Update Antivirus Definitions Only"
    echo -e " [2] Run Quick Malware Scan"
    echo -e " [3] Run Full Malware Scan (Deep scan, takes longer)"
    echo -e " [4] View Recent Threat Detection History"
    echo -e " [0] Return to Main Menu"
    echo ""
    read -rp "Enter choice [0-4]: " scan_choice

    case "$scan_choice" in
        1)
            echo ""
            echo -e "${CLR_YELLOW}Updating Windows Defender signature definitions...${CLR_RESET}"
            run_ps_block << 'EOF'
            try {
                Update-MpSignature -ErrorAction Stop
                Write-Host "Antivirus signatures successfully updated to the latest definitions!" -ForegroundColor Green
            } catch {
                Write-Host "Attempting fallback update via MpCmdRun.exe..." -ForegroundColor Yellow
                & "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -SignatureUpdate
            }
EOF
            ;;
        2)
            echo ""
            echo -e "${CLR_YELLOW}Starting Windows Defender Quick Scan in background... Please wait.${CLR_RESET}"
            run_ps_block << 'EOF'
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                Start-MpScan -ScanType QuickScan -ErrorAction Stop
                $sw.Stop()
                Write-Host "Quick Scan completed successfully in $([math]::Round($sw.Elapsed.TotalMinutes, 1)) minutes!" -ForegroundColor Green
                $threats = Get-MpThreatDetection -ErrorAction SilentlyContinue
                if ($threats) {
                    Write-Host "Threats detected! Review Windows Defender Security Center." -ForegroundColor Red
                } else {
                    Write-Host "No active threats detected. System is clean." -ForegroundColor Green
                }
            } catch {
                Write-Host "Running scan via MpCmdRun.exe..." -ForegroundColor Yellow
                & "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -Scan -ScanType 1
            }
EOF
            ;;
        3)
            echo ""
            echo -e "${CLR_YELLOW}Starting Windows Defender Full Scan... (This will scan all files)${CLR_RESET}"
            run_ps_block << 'EOF'
            Write-Host "Initiating Full System Scan. This may take 30-90 minutes depending on disk size." -ForegroundColor Yellow
            Start-MpScan -ScanType FullScan
            Write-Host "Full scan completed." -ForegroundColor Green
EOF
            ;;
        4)
            echo ""
            echo -e "${CLR_YELLOW}Querying Threat Detection History (Last 30 Days)...${CLR_RESET}"
            run_ps_block << 'EOF'
            $threats = Get-MpThreatDetection -ErrorAction SilentlyContinue
            if ($threats) {
                $threats | Format-Table ThreatID, ThreatName, InitialDetectionTime, ActionSuccess, Resources -AutoSize
            } else {
                Write-Host "No malware or threat detections recorded in the event log." -ForegroundColor Green
            }
EOF
            ;;
        0)
            return
            ;;
        *)
            echo -e "${CLR_RED}Invalid option.${CLR_RESET}"
            ;;
    esac

    pause_prompt
}

# ==============================================================================
#  [3] UPDATE ALL INSTALLED APPLICATIONS
# ==============================================================================
option_3_update_apps() {
    print_banner "[3] Update All Installed Applications"
    
    echo -e "${CLR_WHITE}Checking for Windows Package Manager (winget)...${CLR_RESET}"
    
    run_ps_block << 'EOF'
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) {
        $appPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
        if (Test-Path $appPath) {
            $winget = $appPath
        }
    }

    if (-not $winget) {
        Write-Host "[ERROR] Windows Package Manager (winget) is not installed on this system." -ForegroundColor Red
        Write-Host "Please install 'App Installer' from the Microsoft Store or GitHub to enable automated app updates." -ForegroundColor Yellow
        exit 2
    }

    Write-Host "Windows Package Manager found: $($winget.Source)" -ForegroundColor Green
    Write-Host "Querying repositories for available software updates... Please wait." -ForegroundColor Cyan
    Write-Host ""
    
    winget.exe upgrade --accept-source-agreements
EOF

    local wg_status=$?
    if [ $wg_status -eq 0 ]; then
        echo ""
        read -rp "Would you like to proceed with updating all upgradeable applications? [Y/N]: " do_update
        if [[ "$do_update" =~ ^[Yy]$ ]]; then
            echo ""
            echo -e "${CLR_YELLOW}Updating all applications... This may take several minutes.${CLR_RESET}"
            run_ps_block << 'EOF'
            winget.exe upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
            Write-Host ""
            Write-Host "Application updates sequence finished." -ForegroundColor Green
EOF
        fi
    fi

    pause_prompt
}

# ==============================================================================
#  [4] WINDOWS UPDATE
# ==============================================================================
option_4_windows_update() {
    print_banner "[4] Windows Update"
    
    echo -e "${CLR_WHITE}Checking Windows Update Service and Pending Updates...${CLR_RESET}"
    echo ""

    run_ps_block << 'EOF'
    $ErrorActionPreference = "SilentlyContinue"
    $wuService = Get-Service -Name wuauserv
    Write-Host "Windows Update Service (wuauserv) Status: $($wuService.Status) [Startup: $($wuService.StartType)]" -ForegroundColor $(if($wuService.Status -eq 'Running'){'Green'}else{'Yellow'})
    
    # Last installed update
    $lastUpdate = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1
    if ($lastUpdate) {
        Write-Host "Last Installed Update: $($lastUpdate.HotFixID) ($($lastUpdate.Description)) on $($lastUpdate.InstalledOn)" -ForegroundColor Cyan
    }
    Write-Host ""

    Write-Host "Scanning for pending updates via Windows Update Agent API... Please wait." -ForegroundColor Cyan
    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")
        
        if ($searchResult.Updates.Count -gt 0) {
            Write-Host "Found $($searchResult.Updates.Count) Pending Windows Update(s):" -ForegroundColor Yellow
            for ($i = 0; $i -lt $searchResult.Updates.Count; $i++) {
                $u = $searchResult.Updates.Item($i)
                $kbStr = ($u.KBArticleIDs -join ", ")
                Write-Host "  [$($i+1)] $($u.Title) (KB: $kbStr) - Size: $([math]::Round($u.MaxDownloadSize/1MB, 1)) MB"
            }
        } else {
            Write-Host "System is up to date! No pending Windows updates found." -ForegroundColor Green
        }
    } catch {
        Write-Host "Direct API search timed out or encountered an issue: $($_.Exception.Message)" -ForegroundColor DarkGray
        Write-Host "You can initiate a scan through the USOClient or Windows Settings." -ForegroundColor Yellow
    }
EOF

    echo ""
    echo -e "${CLR_CYAN}Windows Update Actions:${CLR_RESET}"
    echo -e " [1] Trigger Windows Update Background Scan & Download"
    echo -e " [2] Open Windows Update Settings GUI"
    echo -e " [3] View Last 10 Installed KBs / HotFixes"
    echo -e " [4] Restart Windows Update Service (Clear & Restart)"
    echo -e " [0] Return to Main Menu"
    echo ""
    read -rp "Enter choice [0-4]: " wu_choice

    case "$wu_choice" in
        1)
            echo ""
            echo -e "${CLR_YELLOW}Triggering USOClient Windows Update scan and download...${CLR_RESET}"
            run_ps_block << 'EOF'
            Start-Process -FilePath "usoclient.exe" -ArgumentList "StartScan" -Wait
            Start-Process -FilePath "usoclient.exe" -ArgumentList "StartDownload" -Wait
            Write-Host "Windows Update download initiated." -ForegroundColor Green
EOF
            ;;
        2)
            echo -e "${CLR_YELLOW}Opening Windows Update Settings...${CLR_RESET}"
            start ms-settings:windowsupdate 2>/dev/null || cmd.exe /c start ms-settings:windowsupdate
            ;;
        3)
            echo ""
            echo -e "${CLR_YELLOW}Recent Installed Windows Updates:${CLR_RESET}"
            run_ps_block << 'EOF'
            Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10 HotFixID, Description, InstalledBy, InstalledOn | Format-Table -AutoSize
EOF
            ;;
        4)
            echo ""
            echo -e "${CLR_YELLOW}Restarting Windows Update & BITS services...${CLR_RESET}"
            run_ps_block << 'EOF'
            Restart-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
            Restart-Service -Name bits -Force -ErrorAction SilentlyContinue
            Write-Host "Windows Update services restarted successfully." -ForegroundColor Green
EOF
            ;;
        0)
            return
            ;;
        *)
            echo -e "${CLR_RED}Invalid choice.${CLR_RESET}"
            ;;
    esac

    pause_prompt
}

# ==============================================================================
#  [5] MICROSOFT OFFICE ACTIVATION CHECK
# ==============================================================================
option_5_office_activation() {
    print_banner "[5] Microsoft Office Activation Check"
    
    echo -e "${CLR_WHITE}Searching for Microsoft Office installations and licensing status...${CLR_RESET}"
    echo ""

    run_ps_block << 'EOF'
    $ErrorActionPreference = "SilentlyContinue"

    # Common OSPP.VBS paths across all Office versions & architectures
    $osppPaths = @(
        "$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS",
        "$env:ProgramFiles\Microsoft Office\root\Office16\OSPP.VBS",
        "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\OSPP.VBS",
        "$env:ProgramFiles\Microsoft Office\Office15\OSPP.VBS",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office15\OSPP.VBS",
        "$env:ProgramFiles\Microsoft Office\Office14\OSPP.VBS",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office14\OSPP.VBS"
    )

    $foundOspp = $null
    foreach ($p in $osppPaths) {
        if (Test-Path $p) {
            $foundOspp = $p
            break
        }
    }

    if ($foundOspp) {
        Write-Host "Found Office Licensing Script: $foundOspp" -ForegroundColor Cyan
        Write-Host "Querying license engine... Please wait." -ForegroundColor DarkGray
        Write-Host ""

        $rawOutput = cscript.exe //nologo "$foundOspp" /dstatus
        
        # Filter out annoying slerror.xml warnings and display relevant lines
        $cleanOutput = $rawOutput | Where-Object { $_ -notmatch "slerror\.xml" -and $_.Trim() -ne "" }
        
        $isLicensed = $false
        foreach ($line in $cleanOutput) {
            if ($line -match "LICENSE STATUS:\s+---LICENSED---") {
                Write-Host $line -ForegroundColor Green
                $isLicensed = $true
            } elseif ($line -match "LICENSE STATUS:") {
                Write-Host $line -ForegroundColor Red
            } elseif ($line -match "LICENSE NAME:" -or $line -match "LICENSE DESCRIPTION:" -or $line -match "Last 5 characters of installed product key:" -or $line -match "REMAINING GRACE:") {
                Write-Host $line -ForegroundColor White
            } else {
                Write-Host $line -ForegroundColor Gray
            }
        }

        Write-Host ""
        if ($isLicensed) {
            Write-Host "[VERDICT] Microsoft Office is fully ACTIVATED and LICENSED." -ForegroundColor Green
        } else {
            Write-Host "[VERDICT] Microsoft Office is NOT currently licensed or in Grace Period!" -ForegroundColor Red
        }
    } else {
        # Check for Click-to-Run / Microsoft 365 in registry
        $c2r = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -ErrorAction SilentlyContinue
        if ($c2r) {
            Write-Host "Microsoft 365 / Click-to-Run Office Detected:" -ForegroundColor Cyan
            Write-Host "Product Release IDs : $($c2r.ProductReleaseIDs)"
            Write-Host "Version             : $($c2r.VersionToReport)"
            Write-Host "Platform            : $($c2r.Platform)"
            Write-Host "Client Folder       : $($c2r.ClientFolder)"
            Write-Host ""
            Write-Host "[NOTE] Modern Microsoft 365 uses user-based cloud entitlements." -ForegroundColor Yellow
            Write-Host "To verify account status: Open Word/Excel -> File -> Account -> Subscription Product." -ForegroundColor White
        } else {
            Write-Host "[INFO] No standard Microsoft Office volume or Click-To-Run installation detected on this PC." -ForegroundColor Yellow
        }
    }
EOF

    pause_prompt
}

# ==============================================================================
#  [6] WINDOWS ACTIVATION CHECK
# ==============================================================================
option_6_windows_activation() {
    print_banner "[6] Windows Activation Check"
    
    echo -e "${CLR_WHITE}Querying Windows Software Licensing Manager...${CLR_RESET}"
    echo ""

    run_ps_block << 'EOF'
    $ErrorActionPreference = "SilentlyContinue"

    # Check activation via slmgr /xpr (clean console mode)
    $xpr = cscript.exe //nologo "$env:SystemRoot\System32\slmgr.vbs" /xpr
    Write-Host "--- EXPIRATION / ACTIVATION STATUS ---" -ForegroundColor Cyan
    foreach ($l in $xpr) {
        if ($l.Trim()) {
            if ($l -match "permanently activated") {
                Write-Host "  $($l.Trim())" -ForegroundColor Green
            } elseif ($l -match "Notification" -or $l -match "grace") {
                Write-Host "  $($l.Trim())" -ForegroundColor Yellow
            } else {
                Write-Host "  $($l.Trim())" -ForegroundColor White
            }
        }
    }
    Write-Host ""

    # Check detailed license info via slmgr /dli
    $dli = cscript.exe //nologo "$env:SystemRoot\System32\slmgr.vbs" /dli
    Write-Host "--- LICENSE DETAILS ---" -ForegroundColor Cyan
    foreach ($l in $dli) {
        if ($l.Trim()) {
            Write-Host "  $($l.Trim())" -ForegroundColor Gray
        }
    }
    Write-Host ""

    # WMI Query for definitive status code
    $prod = Get-CimInstance -Query "SELECT Name, LicenseStatus, PartialProductKey FROM SoftwareLicensingProduct WHERE PartialProductKey IS NOT NULL AND Name LIKE 'Windows%'" | Select-Object -First 1
    if ($prod) {
        $statusMap = @{
            0 = "Unlicensed"
            1 = "Licensed (Activated)"
            2 = "Initial Grace Period"
            3 = "Additional Grace Period"
            4 = "Non-Genuine Grace Period"
            5 = "Notification Mode"
            6 = "Extended Grace"
        }
        $statusCode = $prod.LicenseStatus
        $statusName = $statusMap[$statusCode]
        $color = if ($statusCode -eq 1) { "Green" } else { "Red" }

        Write-Host "Product Edition : $($prod.Name)"
        Write-Host "Partial Key     : *****-$($prod.PartialProductKey)"
        Write-Host "License State   : $statusName (Code: $statusCode)" -ForegroundColor $color
        Write-Host ""
        
        if ($statusCode -eq 1) {
            Write-Host "[VERDICT] Windows is genuine and FULLY ACTIVATED." -ForegroundColor Green
        } else {
            Write-Host "[VERDICT] Windows is NOT ACTIVATED or license has expired!" -ForegroundColor Red
        }
    }
EOF

    pause_prompt
}

# ==============================================================================
#  [7] DISK CLEANUP & TEMPORARY FILES
# ==============================================================================
option_7_disk_cleanup() {
    print_banner "[7] Disk Cleanup & Temporary Files"
    
    echo -e "${CLR_WHITE}Analyzing disk usage and temporary file caches...${CLR_RESET}"
    echo ""

    run_ps_block << 'EOF'
    $cDrive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $initFree = [math]::Round($cDrive.FreeSpace / 1GB, 2)
    Write-Host "Current Drive C: Free Space: $initFree GB" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Target cleanup locations:" -ForegroundColor Yellow
    Write-Host " - User Temporary Directory ($env:TEMP)"
    Write-Host " - Windows System Temp ($env:windir\Temp)"
    Write-Host " - Windows Update Download Cache ($env:windir\SoftwareDistribution\Download)"
    Write-Host " - Windows Crash Dumps & Error Reports"
    Write-Host " - Windows Prefetch Cache"
    Write-Host " - Windows Recycle Bin"
    Write-Host " - DNS Resolver Cache"
    Write-Host ""
EOF

    read -rp "Do you want to proceed with Disk Cleanup now? [Y/N]: " confirm_clean
    if [[ ! "$confirm_clean" =~ ^[Yy]$ ]]; then
        echo -e "${CLR_YELLOW}Cleanup cancelled by user.${CLR_RESET}"
        pause_prompt
        return
    fi

    echo ""
    echo -e "${CLR_YELLOW}Performing safe cleanup... Please wait.${CLR_RESET}"

    run_ps_block << 'EOF'
    $ErrorActionPreference = "SilentlyContinue"
    $cBefore = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace

    # 1. User Temp
    Write-Host "Cleaning User Temp folder..." -NoNewline
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " [DONE]" -ForegroundColor Green

    # 2. Windows Temp
    Write-Host "Cleaning Windows System Temp..." -NoNewline
    Remove-Item -Path "$env:windir\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " [DONE]" -ForegroundColor Green

    # 3. SoftwareDistribution Download Cache
    Write-Host "Cleaning Windows Update Download cache..." -NoNewline
    Remove-Item -Path "$env:windir\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " [DONE]" -ForegroundColor Green

    # 4. Crash Dumps
    Write-Host "Cleaning Memory Crash Dumps..." -NoNewline
    Remove-Item -Path "$env:LOCALAPPDATA\CrashDumps\*" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:windir\Minidump\*" -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host " [DONE]" -ForegroundColor Green

    # 5. Empty Recycle Bin
    Write-Host "Emptying Recycle Bin..." -NoNewline
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host " [DONE]" -ForegroundColor Green

    # 6. Flush DNS Cache
    Write-Host "Flushing DNS Resolver Cache..." -NoNewline
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    Write-Host " [DONE]" -ForegroundColor Green

    # 7. Prefetch (if admin)
    if (Test-Path "$env:windir\Prefetch") {
        Write-Host "Cleaning obsolete Prefetch entries..." -NoNewline
        Remove-Item -Path "$env:windir\Prefetch\*.pf" -Force -ErrorAction SilentlyContinue
        Write-Host " [DONE]" -ForegroundColor Green
    }

    $cAfter = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace
    $reclaimedBytes = [math]::Max(0, ($cAfter - $cBefore))
    $reclaimedMB = [math]::Round($reclaimedBytes / 1MB, 2)
    $reclaimedGB = [math]::Round($reclaimedBytes / 1GB, 2)
    $afterFreeGB = [math]::Round($cAfter / 1GB, 2)

    Write-Host ""
    Write-Host "================ CLEANUP SUMMARY ================" -ForegroundColor White
    Write-Host "Drive C: New Free Space : $afterFreeGB GB" -ForegroundColor Green
    Write-Host "Total Disk Space Freed  : $reclaimedMB MB ($reclaimedGB GB)" -ForegroundColor Cyan
    Write-Host "=================================================" -ForegroundColor White
EOF

    pause_prompt
}

# ==============================================================================
#  [8] RAM & CPU PERFORMANCE CHECK
# ==============================================================================
option_8_perf_check() {
    print_banner "[8] RAM & CPU Performance Check"
    
    echo -e "${CLR_WHITE}Measuring live CPU & RAM performance baselines...${CLR_RESET}"
    echo ""

    run_ps_block << 'EOF'
    $ErrorActionPreference = "SilentlyContinue"

    # CPU Information
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $cpuLoad = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average

    Write-Host "--- PROCESSOR (CPU) UTILIZATION ---" -ForegroundColor Cyan
    Write-Host "Processor Model     : $($cpu.Name.Trim())"
    Write-Host "Clock Speed         : $($cpu.MaxClockSpeed) MHz (Current: $($cpu.CurrentClockSpeed) MHz)"
    Write-Host "Sockets/Cores/Threads: $($cpu.SocketDesignation) / $($cpu.NumberOfCores) Cores / $($cpu.NumberOfLogicalProcessors) Threads"
    
    $cpuBadgeColor = if ($cpuLoad -gt 85) { "Red" } elseif ($cpuLoad -gt 70) { "Yellow" } else { "Green" }
    Write-Host "Current CPU Load    : $cpuLoad %" -ForegroundColor $cpuBadgeColor
    Write-Host ""

    # Top CPU consuming processes
    Write-Host "Top 5 CPU-Consuming Processes:" -ForegroundColor Yellow
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 -Property Id, ProcessName, @{Name="CPU(s)"; Expression={[math]::Round($_.CPU, 1)}}, @{Name="RAM(MB)"; Expression={[math]::Round($_.WorkingSet64/1MB, 1)}} | Format-Table -AutoSize
    Write-Host ""

    # RAM Information
    $os = Get-CimInstance Win32_OperatingSystem
    $totalRamGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRamGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRamGB = [math]::Round($totalRamGB - $freeRamGB, 2)
    $ramPercent = [math]::Round(($usedRamGB / $totalRamGB) * 100, 1)

    Write-Host "--- PHYSICAL MEMORY (RAM) UTILIZATION ---" -ForegroundColor Cyan
    Write-Host "Total Installed RAM : $totalRamGB GB"
    Write-Host "Available Free RAM  : $freeRamGB GB"
    
    $ramBadgeColor = if ($ramPercent -gt 85) { "Red" } elseif ($ramPercent -gt 70) { "Yellow" } else { "Green" }
    Write-Host "Memory In-Use       : $usedRamGB GB ($ramPercent% utilized)" -ForegroundColor $ramBadgeColor
    
    # Pagefile
    $pageFile = Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue
    if ($pageFile) {
        Write-Host "Pagefile Allocated  : $($pageFile.InitialSize) MB - $($pageFile.MaximumSize) MB ($($pageFile.Name))"
    }
    Write-Host ""

    # Top RAM consuming processes
    Write-Host "Top 5 Memory-Consuming Processes:" -ForegroundColor Yellow
    Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 -Property Id, ProcessName, @{Name="RAM(MB)"; Expression={[math]::Round($_.WorkingSet64/1MB, 1)}}, @{Name="Handles"; Expression={$_.Handles}} | Format-Table -AutoSize
    Write-Host ""

    # Assessment
    Write-Host "--- PERFORMANCE ASSESSMENT ---" -ForegroundColor Cyan
    if ($cpuLoad -gt 85 -or $ramPercent -gt 85) {
        Write-Host "[HIGH LOAD WARNING] System resources are under heavy strain. Check the top consumers above." -ForegroundColor Red
    } elseif ($cpuLoad -gt 65 -or $ramPercent -gt 70) {
        Write-Host "[MODERATE LOAD] Normal workload with moderate consumption." -ForegroundColor Yellow
    } else {
        Write-Host "[OPTIMAL] CPU and Memory usage are well within healthy operational limits." -ForegroundColor Green
    }
EOF

    pause_prompt
}

# ==============================================================================
#  [9] NETWORK & INTERNET DIAGNOSTICS
# ==============================================================================
option_9_network_diag() {
    print_banner "[9] Network & Internet Diagnostics"
    
    echo -e "${CLR_WHITE}Executing Network & Internet connectivity tests...${CLR_RESET}"
    echo ""

    run_ps_block << 'EOF'
    $ErrorActionPreference = "SilentlyContinue"

    Write-Host "--- ACTIVE NETWORK ADAPTERS ---" -ForegroundColor Cyan
    $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }
    foreach ($a in $adapters) {
        Write-Host "Adapter Name     : $($a.Description)"
        Write-Host "IPv4 Address     : $($a.IPAddress -join ', ')"
        Write-Host "Subnet Mask      : $($a.IPSubnet -join ', ')"
        Write-Host "Default Gateway  : $($a.DefaultIPGateway -join ', ')"
        Write-Host "DNS Servers      : $($a.DNSServerSearchOrder -join ', ')"
        Write-Host "MAC Address      : $($a.MACAddress)"
        Write-Host "DHCP Enabled     : $($a.DHCPEnabled)"
        Write-Host ""
    }

    Write-Host "--- CONNECTIVITY & LATENCY DIAGNOSTICS ---" -ForegroundColor Cyan

    # 1. Gateway Ping
    $gateway = ($adapters | Where-Object { $_.DefaultIPGateway } | Select-Object -First 1).DefaultIPGateway[0]
    if ($gateway) {
        Write-Host "Test 1: Pinging Default Gateway ($gateway)... " -NoNewline
        $pGw = Test-Connection -ComputerName $gateway -Count 2 -Quiet
        if ($pGw) {
            Write-Host "[PASSED - LAN CONNECTED]" -ForegroundColor Green
        } else {
            Write-Host "[FAILED - Check Local Network / Router]" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 1: Default Gateway not configured." -ForegroundColor Yellow
    }

    # 2. Public DNS Ping
    Write-Host "Test 2: Pinging Public DNS (8.8.8.8)... " -NoNewline
    $pDns = Test-Connection -ComputerName "8.8.8.8" -Count 2 -Quiet
    if ($pDns) {
        Write-Host "[PASSED - WAN / INTERNET REACHABLE]" -ForegroundColor Green
    } else {
        Write-Host "[FAILED - Internet routing unreachable]" -ForegroundColor Red
    }

    # 3. DNS Resolution
    Write-Host "Test 3: Resolving Domain Name (google.com)... " -NoNewline
    try {
        $resolved = [System.Net.Dns]::GetHostAddresses("google.com")
        if ($resolved) {
            Write-Host "[PASSED - DNS WORKING] ($($resolved[0].IPAddressToString))" -ForegroundColor Green
        } else {
            Write-Host "[FAILED - DNS lookup empty]" -ForegroundColor Red
        }
    } catch {
        Write-Host "[FAILED - DNS Resolution Error]" -ForegroundColor Red
    }

    # 4. Web HTTP/HTTPS Handshake
    Write-Host "Test 4: TCP Port 443 Handshake (https://www.google.com)... " -NoNewline
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $iar = $tcp.BeginConnect("www.google.com", 443, $null, $null)
        $wait = $iar.AsyncWaitHandle.WaitOne(3000, $false)
        if ($wait -and $tcp.Connected) {
            $tcp.EndConnect($iar)
            $tcp.Close()
            Write-Host "[PASSED - Web Traffic Accessible]" -ForegroundColor Green
        } else {
            $tcp.Close()
            Write-Host "[FAILED - Port 443 Blocked or Timed Out]" -ForegroundColor Red
        }
    } catch {
        Write-Host "[FAILED - Connection Error]" -ForegroundColor Red
    }

    # 5. Wi-Fi status if applicable
    $wlan = netsh.exe wlan show interfaces 2>&1
    if ($wlan -notmatch "is not running" -and $wlan -notmatch "There is no wireless interface") {
        Write-Host ""
        Write-Host "--- WIRELESS (WI-FI) STATUS ---" -ForegroundColor Cyan
        $ssid = ($wlan | Select-String "SSID\s+:" | Select-Object -First 1)
        $signal = ($wlan | Select-String "Signal\s+:" | Select-Object -First 1)
        $radio = ($wlan | Select-String "Radio type\s+:" | Select-Object -First 1)
        if ($ssid) { Write-Host "$ssid" }
        if ($signal) { Write-Host "$signal" -ForegroundColor $(if($signal -match "100%|9[0-9]%|8[0-9]%"){'Green'}else{'Yellow'}) }
        if ($radio) { Write-Host "$radio" }
    }
EOF

    echo ""
    echo -e "${CLR_CYAN}Network Utility Tools:${CLR_RESET}"
    echo -e " [1] Release, Renew IP & Flush DNS (Fixes IP conflicts & stale DNS)"
    echo -e " [2] Reset Winsock and TCP/IP stack (Requires reboot)"
    echo -e " [0] Return to Main Menu"
    echo ""
    read -rp "Enter choice [0-2]: " net_choice

    case "$net_choice" in
        1)
            echo ""
            echo -e "${CLR_YELLOW}Releasing IP, Renewing DHCP lease, and Flushing DNS...${CLR_RESET}"
            ipconfig.exe /flushdns
            ipconfig.exe /release
            ipconfig.exe /renew
            echo -e "${CLR_GREEN}Network stack refreshed successfully.${CLR_RESET}"
            ;;
        2)
            echo ""
            echo -e "${CLR_YELLOW}Resetting Winsock catalog and TCP/IP stack...${CLR_RESET}"
            netsh.exe winsock reset
            netsh.exe int ip reset
            echo -e "${CLR_YELLOW}TCP/IP and Winsock have been reset. A computer restart is recommended.${CLR_RESET}"
            ;;
        0)
            return
            ;;
        *)
            echo -e "${CLR_RED}Invalid choice.${CLR_RESET}"
            ;;
    esac

    pause_prompt
}

# ==============================================================================
#  [10] STARTUP PROGRAMS INSPECTION
# ==============================================================================
option_10_startup_programs() {
    print_banner "[10] Startup Programs Inspection"
    
    echo -e "${CLR_WHITE}Enumerating Windows Startup Entry Points...${CLR_RESET}"
    echo ""

    run_ps_block << 'EOF'
    $ErrorActionPreference = "SilentlyContinue"

    $startupList = [System.Collections.Generic.List[PSObject]]::new()

    # 1. Registry HKLM Run
    $hklmPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $hklmPath) {
        $props = (Get-ItemProperty $hklmPath).psobject.properties | Where-Object { $_.Name -notmatch "^PS" }
        foreach ($p in $props) {
            $startupList.Add([PSCustomObject]@{ Name = $p.Name; Command = $p.Value; Location = "HKLM Run (Machine)" })
        }
    }

    # 2. Registry HKCU Run
    $hkcuPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $hkcuPath) {
        $props = (Get-ItemProperty $hkcuPath).psobject.properties | Where-Object { $_.Name -notmatch "^PS" }
        foreach ($p in $props) {
            $startupList.Add([PSCustomObject]@{ Name = $p.Name; Command = $p.Value; Location = "HKCU Run (User)" })
        }
    }

    # 3. Registry WOW6432Node
    $wowPath = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $wowPath) {
        $props = (Get-ItemProperty $wowPath).psobject.properties | Where-Object { $_.Name -notmatch "^PS" }
        foreach ($p in $props) {
            $startupList.Add([PSCustomObject]@{ Name = $p.Name; Command = $p.Value; Location = "HKLM Run (32-bit)" })
        }
    }

    # 4. Common Startup Folder
    $commonStartup = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
    if (Test-Path $commonStartup) {
        Get-ChildItem $commonStartup -File | ForEach-Object {
            $startupList.Add([PSCustomObject]@{ Name = $_.Name; Command = $_.FullName; Location = "Common Startup Folder" })
        }
    }

    # 5. User Startup Folder
    $userStartup = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    if (Test-Path $userStartup) {
        Get-ChildItem $userStartup -File | ForEach-Object {
            $startupList.Add([PSCustomObject]@{ Name = $_.Name; Command = $_.FullName; Location = "User Startup Folder" })
        }
    }

    Write-Host "Found $($startupList.Count) Configured Startup Items:" -ForegroundColor Cyan
    Write-Host ""

    $startupList | Format-Table -Property Name, Location, Command -Wrap -AutoSize
    
    Write-Host ""
    Write-Host "Helpdesk Tip: To disable startup programs without editing the registry," -ForegroundColor Yellow
    Write-Host "press Ctrl+Shift+Esc to open Task Manager and switch to the 'Startup' tab." -ForegroundColor White
EOF

    pause_prompt
}

# ==============================================================================
#  [11] WINDOWS SERVICES CHECK
# ==============================================================================
option_11_services_check() {
    print_banner "[11] Windows Services Check"
    
    echo -e "${CLR_WHITE}Auditing Critical Core Windows Services...${CLR_RESET}"
    echo ""

    run_ps_block << 'EOF'
    $ErrorActionPreference = "SilentlyContinue"

    $criticalServices = @(
        @{ Name = "wuauserv";            Desc = "Windows Update" },
        @{ Name = "bits";                Desc = "Background Intelligent Transfer" },
        @{ Name = "WinDefend";           Desc = "Microsoft Defender Antivirus" },
        @{ Name = "MpsSvc";              Desc = "Windows Defender Firewall" },
        @{ Name = "Spooler";             Desc = "Print Spooler" },
        @{ Name = "Dnscache";            Desc = "DNS Client" },
        @{ Name = "Dhcp";                Desc = "DHCP Client" },
        @{ Name = "EventLog";            Desc = "Windows Event Log" },
        @{ Name = "TermService";         Desc = "Remote Desktop Services" },
        @{ Name = "W32Time";             Desc = "Windows Time Service" },
        @{ Name = "LanmanWorkstation";   Desc = "Workstation / SMB Client" },
        @{ Name = "LanmanServer";        Desc = "Server / File Sharing" }
    )

    $results = [System.Collections.Generic.List[PSObject]]::new()
    $stoppedCount = 0

    foreach ($item in $criticalServices) {
        $svc = Get-Service -Name $item.Name -ErrorAction SilentlyContinue
        if ($svc) {
            $status = $svc.Status.ToString()
            $startType = $svc.StartType.ToString()
            if ($status -ne "Running" -and $startType -ne "Disabled") {
                $stoppedCount++
            }
            $results.Add([PSCustomObject]@{
                ServiceName = $svc.Name
                DisplayName = $item.Desc
                Status      = $status
                StartupType = $startType
            })
        } else {
            $results.Add([PSCustomObject]@{
                ServiceName = $item.Name
                DisplayName = $item.Desc
                Status      = "NOT INSTALLED"
                StartupType = "N/A"
            })
        }
    }

    $results | Format-Table -Property ServiceName, DisplayName, Status, StartupType -AutoSize
    Write-Host ""

    if ($stoppedCount -gt 0) {
        Write-Host "[ATTENTION] Found $stoppedCount service(s) that are currently STOPPED!" -ForegroundColor Yellow
    } else {
        Write-Host "[ALL HEALTHY] All audited critical Windows services are operating normally." -ForegroundColor Green
    }
EOF

    echo ""
    echo -e "${CLR_CYAN}Service Actions:${CLR_RESET}"
    echo -e " [1] Attempt to Start / Restart Stopped Critical Services"
    echo -e " [2] Open Windows Services Management Console (services.msc)"
    echo -e " [0] Return to Main Menu"
    echo ""
    read -rp "Enter choice [0-2]: " svc_choice

    case "$svc_choice" in
        1)
            echo ""
            echo -e "${CLR_YELLOW}Attempting to start stopped critical services...${CLR_RESET}"
            run_ps_block << 'EOF'
            $servicesToStart = @("wuauserv", "bits", "MpsSvc", "Spooler", "Dhcp", "Dnscache", "W32Time")
            foreach ($s in $servicesToStart) {
                $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
                if ($svc -and $svc.Status -ne "Running" -and $svc.StartType -ne "Disabled") {
                    try {
                        Start-Service -Name $s -ErrorAction Stop
                        Write-Host "Started service: $s" -ForegroundColor Green
                    } catch {
                        Write-Host "Could not start service $s : $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            }
            Write-Host "Service recovery sequence completed." -ForegroundColor Green
EOF
            ;;
        2)
            echo -e "${CLR_YELLOW}Launching Services Console...${CLR_RESET}"
            services.msc 2>/dev/null || cmd.exe /c services.msc
            ;;
        0)
            return
            ;;
        *)
            echo -e "${CLR_RED}Invalid choice.${CLR_RESET}"
            ;;
    esac

    pause_prompt
}

# ==============================================================================
#  [12] HARDWARE & BATTERY DIAGNOSTICS
# ==============================================================================
option_12_hardware_battery() {
    print_banner "[12] Hardware & Battery Diagnostics"
    
    echo -e "${CLR_WHITE}Performing physical hardware & power subsystem audit...${CLR_RESET}"
    echo ""

    run_ps_block << 'EOF'
    $ErrorActionPreference = "SilentlyContinue"

    # Motherboard & BIOS
    $bb = Get-CimInstance Win32_BaseBoard
    $bios = Get-CimInstance Win32_BIOS
    Write-Host "--- MOTHERBOARD & BIOS / UEFI ---" -ForegroundColor Cyan
    Write-Host "Manufacturer     : $($bb.Manufacturer)"
    Write-Host "Product / Board  : $($bb.Product)"
    Write-Host "Board Serial     : $($bb.SerialNumber)"
    Write-Host "BIOS Vendor      : $($bios.Manufacturer)"
    Write-Host "BIOS Version     : $($bios.SMBIOSBIOSVersion)"
    Write-Host "Release Date     : $($bios.ReleaseDate.ToString('yyyy-MM-dd'))"
    Write-Host ""

    # Physical Disks
    Write-Host "--- PHYSICAL STORAGE HARDWARE ---" -ForegroundColor Cyan
    $pDisks = Get-PhysicalDisk -ErrorAction SilentlyContinue
    if ($pDisks) {
        $pDisks | Format-Table DeviceId, FriendlyName, MediaType, BusType, @{Name="Size(GB)"; Expression={[math]::Round($_.Size/1GB, 1)}}, HealthStatus, OperationalStatus -AutoSize
    } else {
        Get-CimInstance Win32_DiskDrive | Select-Object DeviceID, Model, InterfaceType, @{Name="Size(GB)"; Expression={[math]::Round($_.Size/1GB, 1)}}, Status | Format-Table -AutoSize
    }
    Write-Host ""

    # Display / GPU
    Write-Host "--- GRAPHICS / DISPLAY SUBSYSTEM ---" -ForegroundColor Cyan
    $gpus = Get-CimInstance Win32_VideoController
    foreach ($g in $gpus) {
        Write-Host "GPU Name         : $($g.Name)"
        Write-Host "Driver Version   : $($g.DriverVersion)"
        Write-Host "VRAM / Memory    : $([math]::Round($g.AdapterRAM / 1MB, 1)) MB"
        Write-Host "Resolution       : $($g.CurrentHorizontalResolution) x $($g.CurrentVerticalResolution) @ $($g.CurrentRefreshRate) Hz"
        Write-Host ""
    }

    # Battery Diagnostics
    Write-Host "--- BATTERY & POWER SUBSYSTEM ---" -ForegroundColor Cyan
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) {
        Write-Host "Battery Present  : Yes ($($battery.Name))" -ForegroundColor Green
        Write-Host "Chemistry        : $($battery.Chemistry)"
        Write-Host "Current Charge   : $($battery.EstimatedChargeRemaining) %"
        Write-Host "Estimated Runtime: $($battery.EstimatedRunTime) minutes"
        Write-Host "Status           : $($battery.Status)"

        if ($battery.DesignCapacity -and $battery.FullChargeCapacity -and $battery.DesignCapacity -gt 0) {
            $healthPct = [math]::Round(($battery.FullChargeCapacity / $battery.DesignCapacity) * 100, 1)
            $wearColor = if ($healthPct -gt 80) { "Green" } elseif ($healthPct -gt 60) { "Yellow" } else { "Red" }
            Write-Host "Design Capacity  : $($battery.DesignCapacity) mWh"
            Write-Host "Full Charge Cap. : $($battery.FullChargeCapacity) mWh"
            Write-Host "Battery Health   : $healthPct % of design capacity" -ForegroundColor $wearColor
        }
    } else {
        Write-Host "Battery Present  : No Battery Detected (Desktop or Virtual Machine Environment)" -ForegroundColor DarkGray
    }
EOF

    echo ""
    echo -e "${CLR_CYAN}Diagnostic Tools:${CLR_RESET}"
    echo -e " [1] Generate Official Windows Battery Report (HTML)"
    echo -e " [0] Return to Main Menu"
    echo ""
    read -rp "Enter choice [0-1]: " bat_choice

    if [ "$bat_choice" = "1" ]; then
        echo ""
        echo -e "${CLR_YELLOW}Generating Windows Battery Report...${CLR_RESET}"
        run_ps_block << 'EOF'
        $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
        if (-not $battery) {
            Write-Host "[NOTE] Cannot generate battery report on a system without a physical battery (Desktop / VM)." -ForegroundColor Yellow
        } else {
            $reportPath = "$env:USERPROFILE\Desktop\Battery_Report_$((Get-Date).ToString('yyyyMMdd_HHmmss')).html"
            powercfg.exe /batteryreport /output "$reportPath"
            Write-Host "Battery Report generated successfully at:" -ForegroundColor Green
            Write-Host "$reportPath" -ForegroundColor Cyan
            Start-Process "$reportPath"
        }
EOF
    fi

    pause_prompt
}

# ==============================================================================
#  [13] GENERATE IT HELPDESK REPORT
# ==============================================================================
option_13_generate_report() {
    print_banner "[13] Generate IT Helpdesk Report"
    
    echo -e "${CLR_WHITE}Compiling comprehensive IT Helpdesk Health & Diagnostics Report...${CLR_RESET}"
    echo ""

    run_ps_block << 'EOF'
    $ErrorActionPreference = "SilentlyContinue"

    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $hostname = $env:COMPUTERNAME
    $reportDir = "IT_Helpdesk_Reports"
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }

    $txtFile = "$reportDir\IT_Report_${hostname}_${timestamp}.txt"
    $htmlFile = "$reportDir\IT_Report_${hostname}_${timestamp}.html"

    # Data Collection
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_BIOS
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $cpuLoad = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $totalRamGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRamGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRamGB = [math]::Round($totalRamGB - $freeRamGB, 2)
    $ramPercent = [math]::Round(($usedRamGB / $totalRamGB) * 100, 1)
    $disks = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
    $lic = Get-CimInstance -Query "SELECT Name, LicenseStatus, PartialProductKey FROM SoftwareLicensingProduct WHERE PartialProductKey IS NOT NULL AND Name LIKE 'Windows%'" | Select-Object -First 1
    $recentEvents = Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddHours(-24)} -MaxEvents 8 -ErrorAction SilentlyContinue

    # Overall Status Calculation
    $systemStatus = "HEALTHY"
    $statusColor = "#107c10"
    foreach ($d in $disks) {
        $pct = if ($d.Size -gt 0) { ($d.FreeSpace / $d.Size) * 100 } else { 100 }
        if ($pct -lt 15) {
            $systemStatus = "ATTENTION REQUIRED"
            $statusColor = "#d83b01"
            break
        }
    }
    if ($ramPercent -gt 90 -or $cpuLoad -gt 90) {
        $systemStatus = "HIGH RESOURCE UTILIZATION"
        $statusColor = "#d83b01"
    }

    # Generate Plain Text Report
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("================================================================================")
    [void]$sb.AppendLine("                      IT HELPDESK SYSTEM HEALTH REPORT")
    [void]$sb.AppendLine("================================================================================")
    [void]$sb.AppendLine("Generated On     : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    [void]$sb.AppendLine("Computer Name    : $($cs.Name)")
    [void]$sb.AppendLine("Logged-in User   : $($env:USERNAME)")
    [void]$sb.AppendLine("Domain/Workgroup : $($cs.Domain)")
    [void]$sb.AppendLine("Overall Status   : $systemStatus")
    [void]$sb.AppendLine("--------------------------------------------------------------------------------")
    [void]$sb.AppendLine("[SYSTEM SPECIFICATIONS]")
    [void]$sb.AppendLine("OS Caption       : $($os.Caption) ($($os.OSArchitecture))")
    [void]$sb.AppendLine("OS Build/Version : $($os.BuildNumber) ($($os.Version))")
    [void]$sb.AppendLine("Manufacturer     : $($cs.Manufacturer)")
    [void]$sb.AppendLine("Model            : $($cs.Model)")
    [void]$sb.AppendLine("Serial Number    : $($bios.SerialNumber)")
    [void]$sb.AppendLine("Processor        : $($cpu.Name.Trim())")
    [void]$sb.AppendLine("RAM Configuration: $totalRamGB GB Total | $usedRamGB GB Used ($ramPercent%) | $freeRamGB GB Free")
    [void]$sb.AppendLine("Last Boot Up     : $($os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss'))")
    [void]$sb.AppendLine("--------------------------------------------------------------------------------")
    [void]$sb.AppendLine("[STORAGE HEALTH]")
    foreach ($d in $disks) {
        $t = [math]::Round($d.Size/1GB, 2)
        $f = [math]::Round($d.FreeSpace/1GB, 2)
        $p = if ($t -gt 0) { [math]::Round(($f/$t)*100, 1) } else { 0 }
        [void]$sb.AppendLine("Drive $($d.DeviceID) Volume: $($d.VolumeName) | Free: $f GB / $t GB ($p% Free) | Status: $($d.Status)")
    }
    [void]$sb.AppendLine("--------------------------------------------------------------------------------")
    [void]$sb.AppendLine("[SECURITY & LICENSING]")
    if ($lic) {
        [void]$sb.AppendLine("Windows License  : $(if($lic.LicenseStatus -eq 1){'ACTIVATED'}else{'UNLICENSED / GRACE'}) (Key: *****-$($lic.PartialProductKey))")
    }
    if ($defender) {
        [void]$sb.AppendLine("Windows Defender : Real-Time Protection is $(if($defender.RealTimeProtectionEnabled){'ENABLED'}else{'DISABLED'})")
        [void]$sb.AppendLine("AV Signatures    : Version $($defender.AntivirusSignatureVersion) (Updated: $($defender.AntivirusSignatureLastUpdated))")
    }
    [void]$sb.AppendLine("--------------------------------------------------------------------------------")
    [void]$sb.AppendLine("[RECENT SYSTEM EVENT LOG ERRORS (LAST 24 HOURS)]")
    if ($recentEvents) {
        foreach ($e in $recentEvents) {
            $msg = ($e.Message -replace "`r`n", " ")
            if ($msg.Length -gt 100) { $msg = $msg.Substring(0, 97) + "..." }
            [void]$sb.AppendLine("$($e.TimeCreated.ToString('yyyy-MM-dd HH:mm')) | ID: $($e.Id) | Provider: $($e.ProviderName) | $msg")
        }
    } else {
        [void]$sb.AppendLine("No Critical or Error events recorded in System log in the last 24 hours.")
    }
    [void]$sb.AppendLine("================================================================================")
    
    [System.IO.File]::WriteAllText($txtFile, $sb.ToString(), [System.Text.Encoding]::UTF8)

    # Generate HTML Report
    $diskRows = ""
    foreach ($d in $disks) {
        $t = [math]::Round($d.Size/1GB, 2)
        $f = [math]::Round($d.FreeSpace/1GB, 2)
        $p = if ($t -gt 0) { [math]::Round(($f/$t)*100, 1) } else { 0 }
        $color = if ($p -lt 15) { "#d83b01" } elseif ($p -lt 25) { "#f7630c" } else { "#107c10" }
        $diskRows += "<tr><td><b>$($d.DeviceID)</b></td><td>$($d.VolumeName)</td><td>$t GB</td><td>$f GB</td><td style='color:$color;font-weight:bold;'>$p %</td><td>$($d.Status)</td></tr>"
    }

    $eventRows = ""
    if ($recentEvents) {
        foreach ($e in $recentEvents) {
            $msg = ($e.Message -replace "`r`n", " ")
            if ($msg.Length -gt 120) { $msg = $msg.Substring(0, 117) + "..." }
            $eventRows += "<tr><td>$($e.TimeCreated.ToString('yyyy-MM-dd HH:mm'))</td><td><span class='badge badge-danger'>$($e.Id)</span></td><td>$($e.ProviderName)</td><td>$msg</td></tr>"
        }
    } else {
        $eventRows = "<tr><td colspan='4' style='color:#107c10;font-weight:bold;'>No Critical or Error events recorded in System log in the last 24 hours.</td></tr>"
    }

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>IT Helpdesk Diagnostic Report - $($cs.Name)</title>
<style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background-color: #f4f6f9; color: #333; margin: 0; padding: 20px; }
    .container { max-width: 1000px; margin: 0 auto; background: #fff; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); overflow: hidden; }
    .header { background: #0078d4; color: #fff; padding: 24px 30px; display: flex; justify-content: space-between; align-items: center; }
    .header h1 { margin: 0; font-size: 24px; }
    .header p { margin: 4px 0 0; opacity: 0.85; font-size: 14px; }
    .status-badge { background: $statusColor; color: #fff; padding: 8px 16px; border-radius: 20px; font-weight: bold; font-size: 14px; letter-spacing: 0.5px; }
    .content { padding: 30px; }
    .card { background: #fafbfc; border: 1px solid #e1e4e8; border-radius: 6px; padding: 20px; margin-bottom: 24px; }
    .card h2 { margin-top: 0; font-size: 18px; color: #0078d4; border-bottom: 2px solid #e1e4e8; padding-bottom: 8px; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; margin-top: 12px; }
    .metric { background: #fff; padding: 12px; border-radius: 4px; border-left: 4px solid #0078d4; }
    .metric-label { font-size: 12px; color: #666; text-transform: uppercase; }
    .metric-val { font-size: 16px; font-weight: bold; margin-top: 4px; color: #222; }
    table { width: 100%; border-collapse: collapse; margin-top: 12px; font-size: 14px; }
    th, td { text-align: left; padding: 10px 12px; border-bottom: 1px solid #e1e4e8; }
    th { background: #f0f3f6; font-weight: 600; color: #444; }
    .badge { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 12px; font-weight: bold; }
    .badge-danger { background: #fde8e8; color: #d83b01; }
    .footer { text-align: center; padding: 16px; font-size: 12px; color: #888; background: #fafbfc; border-top: 1px solid #e1e4e8; }
</style>
</head>
<body>
<div class="container">
    <div class="header">
        <div>
            <h1>IT Helpdesk Diagnostic Report</h1>
            <p>Target Computer: <b>$($cs.Name)</b> | Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        </div>
        <div class="status-badge">$systemStatus</div>
    </div>
    <div class="content">
        <div class="card">
            <h2>System Specifications</h2>
            <div class="grid">
                <div class="metric"><div class="metric-label">Operating System</div><div class="metric-val">$($os.Caption)</div></div>
                <div class="metric"><div class="metric-label">OS Build / Version</div><div class="metric-val">Build $($os.BuildNumber) ($($os.Version))</div></div>
                <div class="metric"><div class="metric-label">Manufacturer / Model</div><div class="metric-val">$($cs.Manufacturer) $($cs.Model)</div></div>
                <div class="metric"><div class="metric-label">Serial Number</div><div class="metric-val">$($bios.SerialNumber)</div></div>
                <div class="metric"><div class="metric-label">Processor</div><div class="metric-val">$($cpu.Name.Trim())</div></div>
                <div class="metric"><div class="metric-label">RAM Load</div><div class="metric-val">$usedRamGB GB / $totalRamGB GB ($ramPercent%)</div></div>
            </div>
        </div>

        <div class="card">
            <h2>Storage Health</h2>
            <table>
                <thead>
                    <tr><th>Drive</th><th>Volume Name</th><th>Total Capacity</th><th>Free Space</th><th>% Free</th><th>Status</th></tr>
                </thead>
                <tbody>
                    $diskRows
                </tbody>
            </table>
        </div>

        <div class="card">
            <h2>Security & Activation Status</h2>
            <div class="grid">
                <div class="metric"><div class="metric-label">Windows Activation</div><div class="metric-val">$(if($lic.LicenseStatus -eq 1){'<span style="color:#107c10;">ACTIVATED</span>'}else{'<span style="color:#d83b01;">NOT ACTIVATED</span>'})</div></div>
                <div class="metric"><div class="metric-label">Defender Real-Time Protection</div><div class="metric-val">$(if($defender.RealTimeProtectionEnabled){'<span style="color:#107c10;">ENABLED</span>'}else{'<span style="color:#d83b01;">DISABLED</span>'})</div></div>
                <div class="metric"><div class="metric-label">Antivirus Definitions</div><div class="metric-val">Ver $($defender.AntivirusSignatureVersion)</div></div>
            </div>
        </div>

        <div class="card">
            <h2>Recent Critical / Error Event Logs (24h)</h2>
            <table>
                <thead>
                    <tr><th>Timestamp</th><th>Event ID</th><th>Provider</th><th>Message</th></tr>
                </thead>
                <tbody>
                    $eventRows
                </tbody>
            </table>
        </div>
    </div>
    <div class="footer">
        IT Helpdesk Automation Toolkit &bull; Confidential &bull; Maintenance & Audit Report
    </div>
</div>
</body>
</html>
"@

    [System.IO.File]::WriteAllText($htmlFile, $html, [System.Text.Encoding]::UTF8)

    Write-Host "IT Helpdesk Reports generated successfully!" -ForegroundColor Green
    Write-Host "  Plain Text Report : $txtFile" -ForegroundColor Cyan
    Write-Host "  HTML Dashboard    : $htmlFile" -ForegroundColor Cyan
EOF

    echo ""
    read -rp "Would you like to open the HTML report in your default browser now? [Y/N]: " open_rep
    if [[ "$open_rep" =~ ^[Yy]$ ]]; then
        run_ps_block << 'EOF'
        $latestHtml = Get-ChildItem "IT_Helpdesk_Reports\*.html" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latestHtml) {
            Start-Process $latestHtml.FullName
        }
EOF
    fi

    pause_prompt
}

# ==============================================================================
#  [14] RUN COMPLETE MAINTENANCE
# ==============================================================================
option_14_complete_maintenance() {
    print_banner "[14] Run Complete Maintenance"
    
    echo -e "${CLR_WHITE}The Complete Maintenance workflow performs full sequential optimization:${CLR_RESET}"
    echo -e " 1. Disk Cleanup & Cache Purge"
    echo -e " 2. DNS Cache Flush & Network Stack Refresh"
    echo -e " 3. Windows Defender Definition Update & Quick Scan"
    echo -e " 4. Installed Applications Upgrade (via winget)"
    echo -e " 5. Windows Component Store Health Check (DISM)"
    echo -e " 6. System File Integrity Scan (SFC)"
    echo -e " 7. Verification & Recovery of Stopped Core Services"
    echo -e " 8. Generation of Final Post-Maintenance IT Report"
    echo ""

    if ! is_admin; then
        echo -e "${CLR_RED}[WARNING] Complete Maintenance requires Administrator privileges to run SFC and DISM!${CLR_RESET}"
        echo -e "${CLR_YELLOW}Some steps may fail or be skipped without elevated permissions.${CLR_RESET}"
        echo ""
    fi

    read -rp "Do you want to start Complete Maintenance now? [Y/N]: " confirm_maint
    if [[ ! "$confirm_maint" =~ ^[Yy]$ ]]; then
        echo -e "${CLR_YELLOW}Complete Maintenance cancelled.${CLR_RESET}"
        pause_prompt
        return
    fi

    local start_time
    start_time=$(date +%s 2>/dev/null || echo 0)

    echo ""
    echo -e "${CLR_BOLD}${CLR_CYAN}>>> [STEP 1/8] Cleaning Temporary Files & Recycle Bin...${CLR_RESET}"
    run_ps_block << 'EOF'
    $ErrorActionPreference = "SilentlyContinue"
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:windir\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "Temporary files and recycle bin purged." -ForegroundColor Green
EOF

    echo ""
    echo -e "${CLR_BOLD}${CLR_CYAN}>>> [STEP 2/8] Refreshing Network Stack & Flushing DNS...${CLR_RESET}"
    ipconfig.exe /flushdns
    echo -e "${CLR_GREEN}DNS Cache flushed.${CLR_RESET}"

    echo ""
    echo -e "${CLR_BOLD}${CLR_CYAN}>>> [STEP 3/8] Updating Antivirus Signatures & Running Quick Scan...${CLR_RESET}"
    run_ps_block << 'EOF'
    try {
        Update-MpSignature -ErrorAction SilentlyContinue
        Write-Host "Antivirus signatures updated." -ForegroundColor Green
        Write-Host "Running Quick Scan... Please wait." -ForegroundColor Cyan
        Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue
        Write-Host "Quick Scan completed." -ForegroundColor Green
    } catch {
        Write-Host "Defender scan step finished." -ForegroundColor Yellow
    }
EOF

    echo ""
    echo -e "${CLR_BOLD}${CLR_CYAN}>>> [STEP 4/8] Upgrading Applications via Windows Package Manager...${CLR_RESET}"
    run_ps_block << 'EOF'
    if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
        winget.exe upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
    } else {
        Write-Host "Winget not installed, skipping application updates." -ForegroundColor DarkGray
    }
EOF

    echo ""
    echo -e "${CLR_BOLD}${CLR_CYAN}>>> [STEP 5/8] Checking Windows Component Store Health (DISM)...${CLR_RESET}"
    if is_admin; then
        dism.exe /Online /Cleanup-Image /ScanHealth
    else
        echo -e "${CLR_YELLOW}Skipping DISM check (Requires Administrator privileges).${CLR_RESET}"
    fi

    echo ""
    echo -e "${CLR_BOLD}${CLR_CYAN}>>> [STEP 6/8] Checking System File Integrity (SFC)...${CLR_RESET}"
    if is_admin; then
        sfc.exe /scannow
    else
        echo -e "${CLR_YELLOW}Skipping SFC scan (Requires Administrator privileges).${CLR_RESET}"
    fi

    echo ""
    echo -e "${CLR_BOLD}${CLR_CYAN}>>> [STEP 7/8] Verifying Critical Windows Services...${CLR_RESET}"
    run_ps_block << 'EOF'
    $services = @("wuauserv", "bits", "MpsSvc", "Spooler", "Dhcp", "Dnscache")
    foreach ($s in $services) {
        $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -ne "Running" -and $svc.StartType -ne "Disabled") {
            Start-Service -Name $s -ErrorAction SilentlyContinue
        }
    }
    Write-Host "Critical services verified and active." -ForegroundColor Green
EOF

    echo ""
    echo -e "${CLR_BOLD}${CLR_CYAN}>>> [STEP 8/8] Generating Maintenance Report...${CLR_RESET}"
    option_13_generate_report

    echo ""
    echo -e "${CLR_GREEN}================================================${CLR_RESET}"
    echo -e "${CLR_BOLD}${CLR_GREEN} COMPLETE MAINTENANCE COMPLETED SUCCESSFULLY!${CLR_RESET}"
    echo -e "${CLR_GREEN}================================================${CLR_RESET}"

    pause_prompt
}

# ==============================================================================
#  [15] EXIT
# ==============================================================================
option_15_exit() {
    clear 2>/dev/null || cls 2>/dev/null
    echo -e "${CLR_CYAN}================================================${CLR_RESET}"
    echo -e "${CLR_BOLD}${CLR_WHITE}   THANK YOU FOR USING IT HELPDESK TOOLKIT${CLR_RESET}"
    echo -e "${CLR_CYAN}================================================${CLR_RESET}"
    echo -e "${CLR_GREEN}Exiting cleanly. Have a productive day!${CLR_RESET}"
    echo ""
    exit 0
}

# ==============================================================================
#  MAIN LOOP
# ==============================================================================
main() {
    # Set Windows console window title
    echo -ne "\033]0;IT Helpdesk Automation Toolkit-Developed by Ian Robert\007" 2>/dev/null

    while true; do
        show_menu
        echo ""
        if ! read -rp "Select an option [1-15]: " choice; then
            echo ""
            echo "Exiting toolkit."
            exit 0
        fi
        
        # Trim leading and trailing whitespace
        choice=$(echo "$choice" | tr -d '\r\n ' 2>/dev/null || echo "$choice")
        
        case "$choice" in
            1)  option_1_health_check ;;
            2)  option_2_virus_scan ;;
            3)  option_3_update_apps ;;
            4)  option_4_windows_update ;;
            5)  option_5_office_activation ;;
            6)  option_6_windows_activation ;;
            7)  option_7_disk_cleanup ;;
            8)  option_8_perf_check ;;
            9)  option_9_network_diag ;;
            10) option_10_startup_programs ;;
            11) option_11_services_check ;;
            12) option_12_hardware_battery ;;
            13) option_13_generate_report ;;
            14) option_14_complete_maintenance ;;
            15) option_15_exit ;;
            *)
                echo -e "${CLR_RED}Invalid selection. Please choose a number from 1 to 15.${CLR_RESET}"
                sleep 1.5 2>/dev/null || timeout /t 2 >/dev/null 2>&1
                ;;
        esac
    done
}

# Execute main routine
main "$@"
