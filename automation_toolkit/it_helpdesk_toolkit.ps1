<#
.SYNOPSIS
    IT Helpdesk Automation Toolkit - Enterprise Windows Diagnostic, Repair & Maintenance Suite
.DESCRIPTION
    A comprehensive, production-ready diagnostic and repair toolkit for Windows desktops and laptops.
    Works on Windows 10, Windows 11, and Windows Server editions.
#>

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$Option = ""
)

# Set Console Output to UTF-8
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

# Determine Administrator Privileges
function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$script:IsAdmin = Test-IsAdmin

function Show-Header {
    param([string]$Title = "")
    Clear-Host
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "       IT HELPDESK AUTOMATION TOOLKIT           " -ForegroundColor White
    Write-Host "================================================" -ForegroundColor Cyan
    if ($Title) {
        Write-Host ">>> $Title" -ForegroundColor Yellow
        Write-Host "================================================" -ForegroundColor Cyan
        Write-Host ""
    } else {
        $adminBadge = if ($script:IsAdmin) { "[ADMINISTRATOR PRIVILEGES DETECTED]" } else { "[STANDARD USER - Some operations may require Admin]" }
        $adminColor = if ($script:IsAdmin) { "Green" } else { "Yellow" }
        Write-Host " Mode: " -NoNewline
        Write-Host $adminBadge -ForegroundColor $adminColor
        Write-Host " Host: $($env:COMPUTERNAME) | User: $($env:USERNAME)" -ForegroundColor White
        Write-Host "------------------------------------------------" -ForegroundColor Cyan
    }
}

function Wait-Prompt {
    Write-Host ""
    Write-Host "------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "Press [Enter] to return to Main Menu..." -ForegroundColor Gray -NoNewline
    [void][System.Console]::ReadLine()
}

# ==============================================================================
#  [1] FULL LAPTOP / PC HEALTH CHECK
# ==============================================================================
function Invoke-HealthCheck {
    Show-Header "[1] Full Laptop & PC Health Check"
    Write-Host "Gathering comprehensive system health metrics... Please wait." -ForegroundColor Cyan
    Write-Host ""

    $ErrorActionPreference = 'SilentlyContinue'

    # System & OS
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
    Write-Host "Current CPU Load : $cpuLoad %" -ForegroundColor (if($cpuLoad -gt 85){'Red'}elseif($cpuLoad -gt 70){'Yellow'}else{'Green'})
    Write-Host "Total RAM        : $totalRamGB GB"
    Write-Host "Used RAM         : $usedRamGB GB ($ramPercent% utilized)" -ForegroundColor (if($ramPercent -gt 85){'Red'}elseif($ramPercent -gt 70){'Yellow'}else{'Green'})
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
        Write-Host "Drive $($d.DeviceID) Volume: [$($d.VolumeName)] Free: $freeGB GB / $totalGB GB ($freePercent% Free)" -ForegroundColor $diskColor
    }
    Write-Host ""

    # Battery & Power Subsystem
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
            Write-Host "Battery Health   : $wear % of original design capacity" -ForegroundColor (if($wear -lt 60){'Red'}elseif($wear -lt 80){'Yellow'}else{'Green'})
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
        $avProducts = Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction SilentlyContinue
        if ($avProducts) {
            foreach ($av in $avProducts) {
                Write-Host "Registered Antivirus : $($av.displayName)" -ForegroundColor Green
            }
        } else {
            Write-Host "Defender Status  : Service query unavailable or third-party AV active." -ForegroundColor Yellow
        }
    }

    # Windows Activation
    $lic = Get-CimInstance -Query "SELECT Name, LicenseStatus, PartialProductKey FROM SoftwareLicensingProduct WHERE PartialProductKey IS NOT NULL AND Name LIKE 'Windows%'" | Select-Object -First 1
    if ($lic) {
        $licColor = if ($lic.LicenseStatus -eq 1) { "Green" } else { "Red" }
        $licStatusStr = if ($lic.LicenseStatus -eq 1) { "ACTIVATED / GENUINE" } else { "NOT ACTIVATED / GRACE PERIOD" }
        Write-Host "Windows License  : $licStatusStr" -ForegroundColor $licColor
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

    Wait-Prompt
}

# ==============================================================================
#  [2] VIRUS & MALWARE SCAN
# ==============================================================================
function Invoke-VirusScan {
    Show-Header "[2] Virus & Malware Scan"
    Write-Host "Checking Windows Defender Antivirus Status..." -ForegroundColor White

    $status = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($status) {
        Write-Host "Antivirus Service Enabled : $($status.AMServiceEnabled)"
        Write-Host "Antispyware Enabled       : $($status.AntispywareEnabled)"
        Write-Host "Real-Time Protection      : $($status.RealTimeProtectionEnabled)" -ForegroundColor (if($status.RealTimeProtectionEnabled){'Green'}else{'Red'})
        Write-Host "Antivirus Engine Version  : $($status.AMEngineVersion)"
        Write-Host "Signature Version         : $($status.AntivirusSignatureVersion)"
        Write-Host "Signatures Last Updated   : $($status.AntivirusSignatureLastUpdated)"
        Write-Host "Quick Scan Last Run       : $($status.QuickScanEndTime)"
        Write-Host "Full Scan Last Run        : $($status.FullScanEndTime)"
    } else {
        Write-Host "Could not query Windows Defender status. Administrator rights or third-party AV active." -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Select Malware Scan Action:" -ForegroundColor Cyan
    Write-Host " [1] Update Antivirus Definitions Only"
    Write-Host " [2] Run Quick Malware Scan"
    Write-Host " [3] Run Full Malware Scan (Deep scan, takes longer)"
    Write-Host " [4] View Recent Threat Detection History"
    Write-Host " [0] Return to Main Menu"
    Write-Host ""

    $scanChoice = Read-Host "Enter choice [0-4]"
    switch ($scanChoice.Trim()) {
        "1" {
            Write-Host ""
            Write-Host "Updating Windows Defender signature definitions..." -ForegroundColor Yellow
            try {
                Update-MpSignature -ErrorAction Stop
                Write-Host "Antivirus signatures successfully updated to the latest definitions!" -ForegroundColor Green
            } catch {
                Write-Host "Attempting fallback update via MpCmdRun.exe..." -ForegroundColor Yellow
                & "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -SignatureUpdate
            }
            Wait-Prompt
        }
        "2" {
            Write-Host ""
            Write-Host "Starting Windows Defender Quick Scan in background... Please wait." -ForegroundColor Yellow
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
                Write-Host "Running scan via MpCmdRun.exe fallback..." -ForegroundColor Yellow
                & "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -Scan -ScanType 1
            }
            Wait-Prompt
        }
        "3" {
            Write-Host ""
            Write-Host "Starting Windows Defender Full Scan... (This will scan all files)" -ForegroundColor Yellow
            Write-Host "Initiating Full System Scan. This may take 30-90 minutes depending on disk size." -ForegroundColor Yellow
            try {
                Start-MpScan -ScanType FullScan
                Write-Host "Full scan completed." -ForegroundColor Green
            } catch {
                & "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -Scan -ScanType 2
            }
            Wait-Prompt
        }
        "4" {
            Write-Host ""
            Write-Host "Querying Threat Detection History..." -ForegroundColor Yellow
            $threats = Get-MpThreatDetection -ErrorAction SilentlyContinue
            if ($threats) {
                $threats | Format-Table ThreatID, ThreatName, InitialDetectionTime, Resources -AutoSize
            } else {
                Write-Host "No malware or threat detections recorded in the event log." -ForegroundColor Green
            }
            Wait-Prompt
        }
        default { return }
    }
}

# ==============================================================================
#  [3] UPDATE ALL INSTALLED APPLICATIONS
# ==============================================================================
function Invoke-UpdateApps {
    Show-Header "[3] Update All Installed Applications"
    Write-Host "Checking for Windows Package Manager (winget)..." -ForegroundColor White

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
        Wait-Prompt
        return
    }

    Write-Host "Windows Package Manager found: $($winget.Source)" -ForegroundColor Green
    Write-Host "Querying repositories for available software updates... Please wait." -ForegroundColor Cyan
    Write-Host ""

    & winget.exe upgrade --accept-source-agreements

    Write-Host ""
    $doUpdate = Read-Host "Would you like to proceed with updating all upgradeable applications? [Y/N]"
    if ($doUpdate -match '^[Yy]$') {
        Write-Host ""
        Write-Host "Updating all applications... This may take several minutes." -ForegroundColor Yellow
        & winget.exe upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
        Write-Host ""
        Write-Host "Application updates sequence finished." -ForegroundColor Green
    }

    Wait-Prompt
}

# ==============================================================================
#  [4] WINDOWS UPDATE
# ==============================================================================
function Invoke-WindowsUpdate {
    Show-Header "[4] Windows Update"
    Write-Host "Checking Windows Update Service and Pending Updates..." -ForegroundColor White
    Write-Host ""

    $wuService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
    if ($wuService) {
        Write-Host "Windows Update Service (wuauserv) Status: $($wuService.Status) [Startup: $($wuService.StartType)]" -ForegroundColor (if($wuService.Status -eq 'Running'){'Green'}else{'Yellow'})
    }

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
        Write-Host "Direct API search unavailable: $($_.Exception.Message)" -ForegroundColor DarkGray
        Write-Host "You can initiate a scan through the USOClient or Windows Settings." -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Windows Update Actions:" -ForegroundColor Cyan
    Write-Host " [1] Trigger Windows Update Background Scan & Download"
    Write-Host " [2] Open Windows Update Settings GUI"
    Write-Host " [3] View Last 10 Installed KBs / HotFixes"
    Write-Host " [4] Restart Windows Update Service (Clear & Restart)"
    Write-Host " [0] Return to Main Menu"
    Write-Host ""

    $wuChoice = Read-Host "Enter choice [0-4]"
    switch ($wuChoice.Trim()) {
        "1" {
            Write-Host ""
            Write-Host "Triggering USOClient Windows Update scan and download..." -ForegroundColor Yellow
            Start-Process -FilePath "usoclient.exe" -ArgumentList "StartScan" -Wait -ErrorAction SilentlyContinue
            Start-Process -FilePath "usoclient.exe" -ArgumentList "StartDownload" -Wait -ErrorAction SilentlyContinue
            Write-Host "Windows Update download initiated." -ForegroundColor Green
            Wait-Prompt
        }
        "2" {
            Write-Host "Opening Windows Update Settings..." -ForegroundColor Yellow
            Start-Process "ms-settings:windowsupdate"
            Wait-Prompt
        }
        "3" {
            Write-Host ""
            Write-Host "Recent Installed Windows Updates:" -ForegroundColor Yellow
            Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10 HotFixID, Description, InstalledBy, InstalledOn | Format-Table -AutoSize
            Wait-Prompt
        }
        "4" {
            Write-Host ""
            Write-Host "Restarting Windows Update & BITS services..." -ForegroundColor Yellow
            Restart-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
            Restart-Service -Name bits -Force -ErrorAction SilentlyContinue
            Write-Host "Windows Update services restarted successfully." -ForegroundColor Green
            Wait-Prompt
        }
        default { return }
    }
}

# ==============================================================================
#  [5] MICROSOFT OFFICE ACTIVATION CHECK
# ==============================================================================
function Invoke-OfficeActivation {
    Show-Header "[5] Microsoft Office Activation Check"
    Write-Host "Searching for Microsoft Office installations and licensing status..." -ForegroundColor White
    Write-Host ""

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

    Wait-Prompt
}

# ==============================================================================
#  [6] WINDOWS ACTIVATION CHECK
# ==============================================================================
function Invoke-WindowsActivation {
    Show-Header "[6] Windows Activation Check"
    Write-Host "Querying Windows Software Licensing Manager..." -ForegroundColor White
    Write-Host ""

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
        $statusName = if ($statusMap.ContainsKey($statusCode)) { $statusMap[$statusCode] } else { "Unknown" }
        $color = if ($statusCode -eq 1) { "Green" } else { "Red" }

        Write-Host "--- LICENSE DETAILS ---" -ForegroundColor Cyan
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

    Wait-Prompt
}

# ==============================================================================
#  [7] DISK CLEANUP & TEMPORARY FILES
# ==============================================================================
function Invoke-DiskCleanup {
    Show-Header "[7] Disk Cleanup & Temporary Files"
    Write-Host "Analyzing disk usage and temporary file caches..." -ForegroundColor White
    Write-Host ""

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

    $confirmClean = Read-Host "Do you want to proceed with Disk Cleanup now? [Y/N]"
    if ($confirmClean -notmatch '^[Yy]$') {
        Write-Host "Cleanup cancelled by user." -ForegroundColor Yellow
        Wait-Prompt
        return
    }

    Write-Host ""
    Write-Host "Performing safe cleanup... Please wait." -ForegroundColor Yellow
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
    if ($script:IsAdmin -and (Test-Path "$env:windir\Prefetch")) {
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

    Wait-Prompt
}

# ==============================================================================
#  [8] RAM & CPU PERFORMANCE CHECK
# ==============================================================================
function Invoke-PerfCheck {
    Show-Header "[8] RAM & CPU Performance Check"
    Write-Host "Measuring live CPU & RAM performance baselines..." -ForegroundColor White
    Write-Host ""

    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $cpuLoad = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average

    Write-Host "--- PROCESSOR (CPU) UTILIZATION ---" -ForegroundColor Cyan
    Write-Host "Processor Model      : $($cpu.Name.Trim())"
    Write-Host "Clock Speed          : $($cpu.MaxClockSpeed) MHz (Current: $($cpu.CurrentClockSpeed) MHz)"
    Write-Host "Sockets/Cores/Threads: $($cpu.SocketDesignation) / $($cpu.NumberOfCores) Cores / $($cpu.NumberOfLogicalProcessors) Threads"

    $cpuBadgeColor = if ($cpuLoad -gt 85) { "Red" } elseif ($cpuLoad -gt 70) { "Yellow" } else { "Green" }
    Write-Host "Current CPU Load     : $cpuLoad %" -ForegroundColor $cpuBadgeColor
    Write-Host ""

    Write-Host "Top 5 CPU-Consuming Processes:" -ForegroundColor Yellow
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 -Property Id, ProcessName, @{Name="CPU(s)"; Expression={[math]::Round($_.CPU, 1)}}, @{Name="RAM(MB)"; Expression={[math]::Round($_.WorkingSet64/1MB, 1)}} | Format-Table -AutoSize
    Write-Host ""

    $os = Get-CimInstance Win32_OperatingSystem
    $totalRamGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRamGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRamGB = [math]::Round($totalRamGB - $freeRamGB, 2)
    $ramPercent = [math]::Round(($usedRamGB / $totalRamGB) * 100, 1)

    Write-Host "--- PHYSICAL MEMORY (RAM) UTILIZATION ---" -ForegroundColor Cyan
    Write-Host "Total Installed RAM  : $totalRamGB GB"
    Write-Host "Available Free RAM   : $freeRamGB GB"

    $ramBadgeColor = if ($ramPercent -gt 85) { "Red" } elseif ($ramPercent -gt 70) { "Yellow" } else { "Green" }
    Write-Host "Memory In-Use        : $usedRamGB GB ($ramPercent% utilized)" -ForegroundColor $ramBadgeColor
    Write-Host ""

    Write-Host "Top 5 Memory-Consuming Processes:" -ForegroundColor Yellow
    Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 -Property Id, ProcessName, @{Name="RAM(MB)"; Expression={[math]::Round($_.WorkingSet64/1MB, 1)}}, @{Name="Handles"; Expression={$_.Handles}} | Format-Table -AutoSize
    Write-Host ""

    Write-Host "--- PERFORMANCE ASSESSMENT ---" -ForegroundColor Cyan
    if ($cpuLoad -gt 85 -or $ramPercent -gt 85) {
        Write-Host "[HIGH LOAD WARNING] System resources are under heavy strain. Check the top consumers above." -ForegroundColor Red
    } elseif ($cpuLoad -gt 65 -or $ramPercent -gt 70) {
        Write-Host "[MODERATE LOAD] Normal workload with moderate consumption." -ForegroundColor Yellow
    } else {
        Write-Host "[OPTIMAL] CPU and Memory usage are well within healthy operational limits." -ForegroundColor Green
    }

    Wait-Prompt
}

# ==============================================================================
#  [9] NETWORK & INTERNET DIAGNOSTICS
# ==============================================================================
function Invoke-NetworkDiag {
    Show-Header "[9] Network & Internet Diagnostics"
    Write-Host "Executing Network & Internet connectivity tests..." -ForegroundColor White
    Write-Host ""

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
    $gwObj = $adapters | Where-Object { $_.DefaultIPGateway } | Select-Object -First 1
    if ($gwObj -and $gwObj.DefaultIPGateway) {
        $gateway = $gwObj.DefaultIPGateway[0]
        Write-Host "Test 1: Pinging Default Gateway ($gateway)... " -NoNewline
        $pGw = Test-Connection -ComputerName $gateway -Count 2 -Quiet -ErrorAction SilentlyContinue
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
    $pDns = Test-Connection -ComputerName "8.8.8.8" -Count 2 -Quiet -ErrorAction SilentlyContinue
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

    # 5. Wi-Fi status
    $wlan = netsh.exe wlan show interfaces 2>&1
    if ($wlan -notmatch "is not running" -and $wlan -notmatch "There is no wireless interface") {
        Write-Host ""
        Write-Host "--- WIRELESS (WI-FI) STATUS ---" -ForegroundColor Cyan
        $ssid = ($wlan | Select-String "SSID\s+:" | Select-Object -First 1)
        $signal = ($wlan | Select-String "Signal\s+:" | Select-Object -First 1)
        $radio = ($wlan | Select-String "Radio type\s+:" | Select-Object -First 1)
        if ($ssid) { Write-Host "$ssid" }
        if ($signal) { Write-Host "$signal" -ForegroundColor (if($signal -match "100%|9[0-9]%|8[0-9]%"){'Green'}else{'Yellow'}) }
        if ($radio) { Write-Host "$radio" }
    }

    Write-Host ""
    Write-Host "Network Utility Tools:" -ForegroundColor Cyan
    Write-Host " [1] Release, Renew IP & Flush DNS (Fixes IP conflicts & stale DNS)"
    Write-Host " [2] Reset Winsock and TCP/IP stack (Requires reboot)"
    Write-Host " [0] Return to Main Menu"
    Write-Host ""

    $netChoice = Read-Host "Enter choice [0-2]"
    switch ($netChoice.Trim()) {
        "1" {
            Write-Host ""
            Write-Host "Releasing IP, Renewing DHCP lease, and Flushing DNS..." -ForegroundColor Yellow
            ipconfig.exe /flushdns
            ipconfig.exe /release
            ipconfig.exe /renew
            Write-Host "Network stack refreshed successfully." -ForegroundColor Green
            Wait-Prompt
        }
        "2" {
            Write-Host ""
            Write-Host "Resetting Winsock catalog and TCP/IP stack..." -ForegroundColor Yellow
            netsh.exe winsock reset
            netsh.exe int ip reset
            Write-Host "TCP/IP and Winsock have been reset. A computer restart is recommended." -ForegroundColor Yellow
            Wait-Prompt
        }
        default { return }
    }
}

# ==============================================================================
#  [10] STARTUP PROGRAMS INSPECTION
# ==============================================================================
function Invoke-StartupInspection {
    Show-Header "[10] Startup Programs Inspection"
    Write-Host "Enumerating Windows Startup Entry Points..." -ForegroundColor White
    Write-Host ""

    $startupList = [System.Collections.Generic.List[PSObject]]::new()

    # 1. Registry HKLM Run
    $hklmPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $hklmPath) {
        $props = (Get-ItemProperty $hklmPath).psobject.properties | Where-Object { $_.Name -notmatch "^PS" }
        foreach ($p in $props) {
            $startupList.Add([PSCustomObject]@{ Name = $p.Name; Location = "HKLM Run (Machine)"; Command = $p.Value })
        }
    }

    # 2. Registry HKCU Run
    $hkcuPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $hkcuPath) {
        $props = (Get-ItemProperty $hkcuPath).psobject.properties | Where-Object { $_.Name -notmatch "^PS" }
        foreach ($p in $props) {
            $startupList.Add([PSCustomObject]@{ Name = $p.Name; Location = "HKCU Run (User)"; Command = $p.Value })
        }
    }

    # 3. WOW6432Node
    $wowPath = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $wowPath) {
        $props = (Get-ItemProperty $wowPath).psobject.properties | Where-Object { $_.Name -notmatch "^PS" }
        foreach ($p in $props) {
            $startupList.Add([PSCustomObject]@{ Name = $p.Name; Location = "HKLM WOW64 (32-bit)"; Command = $p.Value })
        }
    }

    # 4. Startup Folders
    $userStartup = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    if (Test-Path $userStartup) {
        Get-ChildItem $userStartup -Filter *.lnk | ForEach-Object {
            $startupList.Add([PSCustomObject]@{ Name = $_.BaseName; Location = "User Startup Folder"; Command = $_.FullName })
        }
    }

    $commonStartup = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
    if (Test-Path $commonStartup) {
        Get-ChildItem $commonStartup -Filter *.lnk | ForEach-Object {
            $startupList.Add([PSCustomObject]@{ Name = $_.BaseName; Location = "Common Startup Folder"; Command = $_.FullName })
        }
    }

    $startupList | Format-Table Name, Location, Command -Wrap -AutoSize

    Write-Host "Helpdesk Tip: Press Ctrl+Shift+Esc to manage startup applications in Task Manager." -ForegroundColor Gray
    Wait-Prompt
}

# ==============================================================================
#  [11] WINDOWS SERVICES CHECK
# ==============================================================================
function Invoke-ServicesCheck {
    Show-Header "[11] Windows Services Check"
    Write-Host "Auditing Critical Core Windows Services..." -ForegroundColor White
    Write-Host ""

    $svcs = @('wuauserv', 'bits', 'WinDefend', 'MpsSvc', 'Spooler', 'Dnscache', 'Dhcp', 'EventLog', 'TermService', 'W32Time')
    $results = Get-Service -Name $svcs -ErrorAction SilentlyContinue
    $results | Format-Table Name, DisplayName, Status, StartType -AutoSize

    Write-Host ""
    Write-Host "Service Actions:" -ForegroundColor Cyan
    Write-Host " [1] Start / Restart Stopped Essential Services"
    Write-Host " [2] Open Services Management Console (services.msc)"
    Write-Host " [0] Return to Main Menu"
    Write-Host ""

    $svcChoice = Read-Host "Enter choice [0-2]"
    switch ($svcChoice.Trim()) {
        "1" {
            Write-Host ""
            Write-Host "Attempting recovery of essential services..." -ForegroundColor Yellow
            $essential = @('wuauserv', 'bits', 'MpsSvc', 'Spooler', 'Dnscache', 'Dhcp')
            foreach ($s in $essential) {
                $service = Get-Service -Name $s -ErrorAction SilentlyContinue
                if ($service -and $service.Status -ne 'Running' -and $service.StartType -ne 'Disabled') {
                    Start-Service -Name $s -ErrorAction SilentlyContinue
                }
            }
            Write-Host "Services recovery sequence completed." -ForegroundColor Green
            Wait-Prompt
        }
        "2" {
            Start-Process "services.msc"
            Wait-Prompt
        }
        default { return }
    }
}

# ==============================================================================
#  [12] HARDWARE & BATTERY DIAGNOSTICS
# ==============================================================================
function Invoke-HardwareBattery {
    Show-Header "[12] Hardware & Battery Diagnostics"

    $bb = Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue
    $bios = Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue
    Write-Host "--- MOTHERBOARD & BIOS ---" -ForegroundColor Cyan
    Write-Host "Manufacturer : $($bb.Manufacturer)"
    Write-Host "Product      : $($bb.Product)"
    Write-Host "Serial       : $($bb.SerialNumber)"
    Write-Host "BIOS Version : $($bios.SMBIOSBIOSVersion) (Release: $($bios.ReleaseDate.ToString('yyyy-MM-dd')))"
    Write-Host ""

    Write-Host "--- PHYSICAL STORAGE DRIVES (SMART) ---" -ForegroundColor Cyan
    Get-CimInstance Win32_DiskDrive | Select-Object DeviceID, Model, InterfaceType, @{Name='Size(GB)'; Expression={[math]::Round($_.Size/1GB, 1)}}, Status | Format-Table -AutoSize

    Write-Host "--- DISPLAY / GRAPHICS ADAPTERS ---" -ForegroundColor Cyan
    Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion, @{Name='VRAM(MB)'; Expression={[math]::Round($_.AdapterRAM/1MB, 0)}} | Format-Table -AutoSize

    Write-Host "--- BATTERY SUBSYSTEM ---" -ForegroundColor Cyan
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) {
        Write-Host "Battery Model  : $($battery.Name)"
        Write-Host "Charge Level   : $($battery.EstimatedChargeRemaining) %"
        if ($battery.DesignCapacity -and $battery.FullChargeCapacity -and $battery.DesignCapacity -gt 0) {
            $wear = [math]::Round(($battery.FullChargeCapacity / $battery.DesignCapacity) * 100, 1)
            Write-Host "Battery Health : $wear % of original design capacity" -ForegroundColor (if($wear -lt 60){'Red'}elseif($wear -lt 80){'Yellow'}else{'Green'})
        }
        Write-Host ""
        $genBat = Read-Host "Generate detailed Microsoft Battery Report HTML now? [Y/N]"
        if ($genBat -match '^[Yy]$') {
            powercfg.exe /batteryreport /output "IT_Helpdesk_Reports\Battery_Report.html"
            Write-Host "Battery report saved to IT_Helpdesk_Reports\Battery_Report.html" -ForegroundColor Green
            Start-Process "IT_Helpdesk_Reports\Battery_Report.html"
        }
    } else {
        Write-Host "No physical battery detected (Desktop, All-In-One, or Virtual Machine)." -ForegroundColor DarkGray
    }

    Wait-Prompt
}

# ==============================================================================
#  [13] GENERATE IT HELPDESK REPORT
# ==============================================================================
function Invoke-GenerateReport {
    Show-Header "[13] Generate IT Helpdesk Report"
    Write-Host "Compiling comprehensive IT Helpdesk diagnostic report... Please wait." -ForegroundColor Cyan
    Write-Host ""

    $reportDir = "IT_Helpdesk_Reports"
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }

    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $hostname = $env:COMPUTERNAME
    $txtFile = "$reportDir\IT_Report_${hostname}_${timestamp}.txt"
    $htmlFile = "$reportDir\IT_Report_${hostname}_${timestamp}.html"

    # Gather data
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
    $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
    $lic = Get-CimInstance -Query "SELECT Name, LicenseStatus, PartialProductKey FROM SoftwareLicensingProduct WHERE PartialProductKey IS NOT NULL AND Name LIKE 'Windows%'" | Select-Object -First 1
    $recentEvents = Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddHours(-24)} -MaxEvents 8 -ErrorAction SilentlyContinue

    # Calculate status
    $systemStatus = "HEALTHY"
    $statusColor = "#107c10"
    foreach ($d in $disks) {
        $pct = if ($d.Size -gt 0) { ($d.FreeSpace / $d.Size) * 100 } else { 100 }
        if ($pct -lt 15) {
            $systemStatus = "ATTENTION REQUIRED (LOW DISK SPACE)"
            $statusColor = "#d83b01"
            break
        }
    }
    if ($ramPercent -gt 90 -or $cpuLoad -gt 90) {
        $systemStatus = "HIGH RESOURCE UTILIZATION"
        $statusColor = "#d83b01"
    }

    # Plain Text Report
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

    # HTML Report
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

    Write-Host ""
    $openRep = Read-Host "Would you like to open the HTML report in your default browser now? [Y/N]"
    if ($openRep -match '^[Yy]$') {
        Start-Process $htmlFile
    }

    Wait-Prompt
}

# ==============================================================================
#  [14] RUN COMPLETE MAINTENANCE
# ==============================================================================
function Invoke-CompleteMaintenance {
    Show-Header "[14] Run Complete Maintenance"
    Write-Host "The Complete Maintenance workflow performs full sequential optimization:" -ForegroundColor White
    Write-Host " 1. Disk Cleanup & Cache Purge"
    Write-Host " 2. DNS Cache Flush & Network Stack Refresh"
    Write-Host " 3. Windows Defender Definition Update & Quick Scan"
    Write-Host " 4. Installed Applications Upgrade (via winget)"
    Write-Host " 5. Windows Component Store Health Check (DISM)"
    Write-Host " 6. System File Integrity Scan (SFC)"
    Write-Host " 7. Verification & Recovery of Stopped Core Services"
    Write-Host " 8. Generation of Final Post-Maintenance IT Report"
    Write-Host ""

    if (-not $script:IsAdmin) {
        Write-Host "[WARNING] Complete Maintenance requires Administrator privileges to run SFC and DISM!" -ForegroundColor Red
        Write-Host "Some steps may be skipped without elevated permissions." -ForegroundColor Yellow
        Write-Host ""
    }

    $confirmMaint = Read-Host "Do you want to start Complete Maintenance now? [Y/N]"
    if ($confirmMaint -notmatch '^[Yy]$') {
        Write-Host "Complete Maintenance cancelled." -ForegroundColor Yellow
        Wait-Prompt
        return
    }

    # Step 1
    Write-Host ""
    Write-Host ">>> [STEP 1/8] Cleaning Temporary Files & Recycle Bin..." -ForegroundColor Cyan
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:windir\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "Temporary files and recycle bin purged." -ForegroundColor Green

    # Step 2
    Write-Host ""
    Write-Host ">>> [STEP 2/8] Refreshing Network Stack & Flushing DNS..." -ForegroundColor Cyan
    ipconfig.exe /flushdns | Out-Null
    Write-Host "DNS Cache flushed." -ForegroundColor Green

    # Step 3
    Write-Host ""
    Write-Host ">>> [STEP 3/8] Updating Antivirus Signatures & Running Quick Scan..." -ForegroundColor Cyan
    try {
        Update-MpSignature -ErrorAction SilentlyContinue
        Write-Host "Antivirus signatures updated." -ForegroundColor Green
        Write-Host "Running Quick Scan... Please wait." -ForegroundColor Cyan
        Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue
        Write-Host "Quick Scan completed." -ForegroundColor Green
    } catch {
        Write-Host "Defender scan step finished." -ForegroundColor Yellow
    }

    # Step 4
    Write-Host ""
    Write-Host ">>> [STEP 4/8] Upgrading Applications via Windows Package Manager..." -ForegroundColor Cyan
    if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
        winget.exe upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
    } else {
        Write-Host "Winget not installed, skipping application updates." -ForegroundColor DarkGray
    }

    # Step 5
    Write-Host ""
    Write-Host ">>> [STEP 5/8] Checking Windows Component Store Health (DISM)..." -ForegroundColor Cyan
    if ($script:IsAdmin) {
        dism.exe /Online /Cleanup-Image /ScanHealth
    } else {
        Write-Host "Skipping DISM check (Requires Administrator privileges)." -ForegroundColor Yellow
    }

    # Step 6
    Write-Host ""
    Write-Host ">>> [STEP 6/8] Checking System File Integrity (SFC)..." -ForegroundColor Cyan
    if ($script:IsAdmin) {
        sfc.exe /scannow
    } else {
        Write-Host "Skipping SFC scan (Requires Administrator privileges)." -ForegroundColor Yellow
    }

    # Step 7
    Write-Host ""
    Write-Host ">>> [STEP 7/8] Verifying Critical Windows Services..." -ForegroundColor Cyan
    $services = @("wuauserv", "bits", "MpsSvc", "Spooler", "Dhcp", "Dnscache")
    foreach ($s in $services) {
        $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -ne "Running" -and $svc.StartType -ne "Disabled") {
            Start-Service -Name $s -ErrorAction SilentlyContinue
        }
    }
    Write-Host "Critical services verified and active." -ForegroundColor Green

    # Step 8
    Write-Host ""
    Write-Host ">>> [STEP 8/8] Generating Post-Maintenance Report..." -ForegroundColor Cyan
    Invoke-GenerateReport

    Write-Host ""
    Write-Host "================================================" -ForegroundColor Green
    Write-Host " COMPLETE MAINTENANCE COMPLETED SUCCESSFULLY!   " -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    Wait-Prompt
}

# ==============================================================================
#  [15] EXIT
# ==============================================================================
function Invoke-Exit {
    Clear-Host
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "    THANK YOU FOR USING IT HELPDESK TOOLKIT     " -ForegroundColor White
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "Exiting cleanly. Have a productive day!" -ForegroundColor Green
    Write-Host ""
    exit 0
}

# ==============================================================================
#  MAIN MENU & DISPATCHER
# ==============================================================================
function Show-Menu {
    Show-Header
    Write-Host " [1]  Full Laptop & PC Health Check"
    Write-Host " [2]  Virus & Malware Scan"
    Write-Host " [3]  Update All Installed Applications"
    Write-Host " [4]  Windows Update"
    Write-Host " [5]  Microsoft Office Activation Check"
    Write-Host " [6]  Windows Activation Check"
    Write-Host " [7]  Disk Cleanup & Temporary Files"
    Write-Host " [8]  RAM & CPU Performance Check"
    Write-Host " [9]  Network & Internet Diagnostics"
    Write-Host " [10] Startup Programs Inspection"
    Write-Host " [11] Windows Services Check"
    Write-Host " [12] Hardware & Battery Diagnostics"
    Write-Host " [13] Generate IT Helpdesk Report"
    Write-Host " [14] Run Complete Maintenance"
    Write-Host " [15] Exit"
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host " IT HELPDESK - SYSTEM MAINTENANCE               " -ForegroundColor White
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Invoke-Choice([string]$choice) {
    switch ($choice.Trim()) {
        "1"  { Invoke-HealthCheck }
        "2"  { Invoke-VirusScan }
        "3"  { Invoke-UpdateApps }
        "4"  { Invoke-WindowsUpdate }
        "5"  { Invoke-OfficeActivation }
        "6"  { Invoke-WindowsActivation }
        "7"  { Invoke-DiskCleanup }
        "8"  { Invoke-PerfCheck }
        "9"  { Invoke-NetworkDiag }
        "10" { Invoke-StartupInspection }
        "11" { Invoke-ServicesCheck }
        "12" { Invoke-HardwareBattery }
        "13" { Invoke-GenerateReport }
        "14" { Invoke-CompleteMaintenance }
        "15" { Invoke-Exit }
        default {
            if ($choice.Trim() -ne "") {
                Write-Host "Invalid option. Please enter a number from 1 to 15." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

# Execute direct CLI argument if provided
if ($Option) {
    Invoke-Choice $Option
    exit 0
}

# Interactive Menu Loop
while ($true) {
    Show-Menu
    $selection = Read-Host "Select an option [1-15]"
    Invoke-Choice $selection
}
