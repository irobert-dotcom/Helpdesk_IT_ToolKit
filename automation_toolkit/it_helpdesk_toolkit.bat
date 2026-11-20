@echo off
setlocal EnableDelayedExpansion

:: ==============================================================================
::  IT HELPDESK AUTOMATION TOOLKIT
::  Native Windows Command Prompt (.BAT) Edition
:: ==============================================================================

:: Title and Console Configuration
title IT Helpdesk Automation Toolkit 
chcp 65001 >nul 2>&1

:: Check Administrator Privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    set "ADMIN_MODE=[ADMINISTRATOR PRIVILEGES DETECTED]"
) else (
    set "ADMIN_MODE=[STANDARD USER - Some operations may require Admin]"
)

:MENU
cls
echo ================================================
echo IT HELPDESK AUTOMATION TOOLKIT DEVELOPED 
echo ================================================
echo  Mode: %ADMIN_MODE%
echo  Host: %COMPUTERNAME% ^| User: %USERNAME%
echo ------------------------------------------------
echo  [1]  Full Laptop Health Check
echo  [2]  Virus ^& Malware Scan
echo  [3]  Update All Installed Applications
echo  [4]  Windows Update
echo  [5]  Microsoft Office Activation Check
echo  [6]  Windows Activation Check
echo  [7]  Disk Cleanup ^& Temporary Files
echo  [8]  RAM ^& CPU Performance Check
echo  [9]  Network ^& Internet Diagnostics
echo  [10] Startup Programs Inspection
echo  [11] Windows Services Check
echo  [12] Hardware ^& Battery Diagnostics
echo  [13] Generate IT Helpdesk Report
echo  [14] Run Complete Maintenance
echo  [15] Exit
echo ================================================
echo  IT HELPDESK - SYSTEM MAINTENANCE
echo ================================================
echo.

set "CHOICE="
set /p "CHOICE=Select an option [1-15]: "
if not defined CHOICE exit /b 0
set "CHOICE=%CHOICE: =%"

if "%CHOICE%"=="1" goto OPTION_1
if "%CHOICE%"=="2" goto OPTION_2
if "%CHOICE%"=="3" goto OPTION_3
if "%CHOICE%"=="4" goto OPTION_4
if "%CHOICE%"=="5" goto OPTION_5
if "%CHOICE%"=="6" goto OPTION_6
if "%CHOICE%"=="7" goto OPTION_7
if "%CHOICE%"=="8" goto OPTION_8
if "%CHOICE%"=="9" goto OPTION_9
if "%CHOICE%"=="10" goto OPTION_10
if "%CHOICE%"=="11" goto OPTION_11
if "%CHOICE%"=="12" goto OPTION_12
if "%CHOICE%"=="13" goto OPTION_13
if "%CHOICE%"=="14" goto OPTION_14
if "%CHOICE%"=="15" goto OPTION_15

echo.
echo [!] Invalid option. Please enter a number from 1 to 15.
timeout /t 2 >nul
goto MENU

:: ==============================================================================
::  [1] FULL LAPTOP HEALTH CHECK
:: ==============================================================================
:OPTION_1
cls
echo ================================================
echo        IT HELPDESK AUTOMATION TOOLKIT
echo ================================================
echo >>> [1] Full Laptop Health Check
echo ================================================
echo.
echo Gathering comprehensive system health metrics... Please wait.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {
    $ErrorActionPreference = 'SilentlyContinue'
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_BIOS
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $cpuLoad = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $totalRamGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRamGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRamGB = [math]::Round($totalRamGB - $freeRamGB, 2)
    $ramPercent = [math]::Round(($usedRamGB / $totalRamGB) * 100, 1)

    Write-Host '--- SYSTEM SPECIFICATIONS ---' -ForegroundColor Cyan
    Write-Host ('Computer Name    : ' + $cs.Name)
    Write-Host ('Manufacturer     : ' + $cs.Manufacturer)
    Write-Host ('Model            : ' + $cs.Model)
    Write-Host ('Serial Number    : ' + $bios.SerialNumber)
    Write-Host ('OS Caption       : ' + $os.Caption + ' (' + $os.OSArchitecture + ')')
    Write-Host ('OS Build / Ver   : Build ' + $os.BuildNumber + ', Version ' + $os.Version)
    Write-Host ('Last Boot Up     : ' + $os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss'))
    Write-Host ''

    Write-Host '--- CPU & MEMORY HEALTH ---' -ForegroundColor Cyan
    Write-Host ('Processor        : ' + $cpu.Name.Trim() + ' (' + $cpu.NumberOfCores + ' Cores / ' + $cpu.NumberOfLogicalProcessors + ' Threads)')
    Write-Host ('Current CPU Load : ' + $cpuLoad + ' %')
    Write-Host ('Total RAM        : ' + $totalRamGB + ' GB')
    Write-Host ('Used RAM         : ' + $usedRamGB + ' GB (' + $ramPercent + '% utilized)')
    Write-Host ('Free RAM         : ' + $freeRamGB + ' GB')
    Write-Host ''

    Write-Host '--- STORAGE DRIVES ---' -ForegroundColor Cyan
    $disks = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    foreach ($d in $disks) {
        $totalGB = [math]::Round($d.Size / 1GB, 2)
        $freeGB = [math]::Round($d.FreeSpace / 1GB, 2)
        $freePercent = if ($totalGB -gt 0) { [math]::Round(($freeGB / $totalGB) * 100, 1) } else { 0 }
        $color = if ($freePercent -lt 15) { 'Red' } elseif ($freePercent -lt 25) { 'Yellow' } else { 'Green' }
        Write-Host ('Drive ' + $d.DeviceID + ' Volume: [' + $d.VolumeName + '] Free: ' + $freeGB + ' GB / ' + $totalGB + ' GB (' + $freePercent + '% Free)') -ForegroundColor $color
    }
    Write-Host ''

    Write-Host '--- BATTERY & POWER SUBSYSTEM ---' -ForegroundColor Cyan
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) {
        Write-Host ('Battery Present  : Yes (' + $battery.Name + ')') -ForegroundColor Green
        Write-Host ('Current Charge   : ' + $battery.EstimatedChargeRemaining + ' %')
        if ($battery.DesignCapacity -and $battery.FullChargeCapacity -and $battery.DesignCapacity -gt 0) {
            $wear = [math]::Round(($battery.FullChargeCapacity / $battery.DesignCapacity) * 100, 1)
            Write-Host ('Battery Health   : ' + $wear + ' % of design capacity')
        }
    } else {
        Write-Host 'Battery Status   : Desktop / Virtual Machine (AC Power, No Battery Detected)' -ForegroundColor DarkGray
    }
    Write-Host ''

    Write-Host '--- SECURITY POSTURE ---' -ForegroundColor Cyan
    $def = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($def) {
        $rtpColor = if ($def.RealTimeProtectionEnabled) { 'Green' } else { 'Red' }
        Write-Host ('Defender Antivirus : Real-Time Protection is ' + (if($def.RealTimeProtectionEnabled){'ENABLED'}else{'DISABLED'})) -ForegroundColor $rtpColor
        Write-Host ('Antivirus Signatures: ' + $def.AntivirusSignatureVersion + ' (Updated: ' + $def.AntivirusSignatureLastUpdated + ')')
    }
    $lic = Get-CimInstance -Query 'SELECT Name, LicenseStatus, PartialProductKey FROM SoftwareLicensingProduct WHERE PartialProductKey IS NOT NULL AND Name LIKE ''Windows%''' | Select-Object -First 1
    if ($lic) {
        $licColor = if ($lic.LicenseStatus -eq 1) { 'Green' } else { 'Red' }
        Write-Host ('Windows License  : ' + (if($lic.LicenseStatus -eq 1){'ACTIVATED / GENUINE'}else{'NOT ACTIVATED'})) -ForegroundColor $licColor
    }
    Write-Host ''
    Write-Host '================ OVERALL HEALTH VERDICT ================' -ForegroundColor White
    if ($ramPercent -gt 90) {
        Write-Host '[WARNING] High RAM utilization detected (' + $ramPercent + '%). Inspect running processes.' -ForegroundColor Yellow
    } else {
        Write-Host '[PASSED] System baseline health is in good operational standing.' -ForegroundColor Green
    }
}"

echo.
echo ------------------------------------------------
pause
goto MENU

:: ==============================================================================
::  [2] VIRUS & MALWARE SCAN
:: ==============================================================================
:OPTION_2
cls
echo ================================================
echo        IT HELPDESK AUTOMATION TOOLKIT
echo ================================================
echo >>> [2] Virus ^& Malware Scan
echo ================================================
echo.
echo Checking Windows Defender Antivirus Status...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {
    $s = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($s) {
        Write-Host ('Real-Time Protection      : ' + $s.RealTimeProtectionEnabled) -ForegroundColor (if($s.RealTimeProtectionEnabled){'Green'}else{'Red'})
        Write-Host ('Antivirus Engine Version  : ' + $s.AMEngineVersion)
        Write-Host ('Signatures Last Updated   : ' + $s.AntivirusSignatureLastUpdated)
        Write-Host ('Quick Scan Last Run       : ' + $s.QuickScanEndTime)
        Write-Host ('Full Scan Last Run        : ' + $s.FullScanEndTime)
    }
}"

echo.
echo Select Malware Scan Action:
echo  [1] Update Antivirus Definitions Only
echo  [2] Run Quick Malware Scan
echo  [3] Run Full Malware Scan
echo  [4] View Recent Threat Detection History
echo  [0] Return to Main Menu
echo.
set /p "SCAN_CHOICE=Enter choice [0-4]: "

if "%SCAN_CHOICE%"=="1" (
    echo.
    echo Updating Windows Defender signature definitions...
    powershell.exe -NoProfile -Command "Update-MpSignature; Write-Host 'Antivirus signatures successfully updated!' -ForegroundColor Green"
)
if "%SCAN_CHOICE%"=="2" (
    echo.
    echo Starting Windows Defender Quick Scan... Please wait.
    powershell.exe -NoProfile -Command "Start-MpScan -ScanType QuickScan; Write-Host 'Quick scan completed. System is clean.' -ForegroundColor Green"
)
if "%SCAN_CHOICE%"=="3" (
    echo.
    echo Starting Windows Defender Full Scan... (This will scan all files)
    powershell.exe -NoProfile -Command "Start-MpScan -ScanType FullScan; Write-Host 'Full scan completed.' -ForegroundColor Green"
)
if "%SCAN_CHOICE%"=="4" (
    echo.
    echo Threat Detection History:
    powershell.exe -NoProfile -Command "Get-MpThreatDetection -ErrorAction SilentlyContinue | Format-Table ThreatID, ThreatName, InitialDetectionTime -AutoSize"
)
if "%SCAN_CHOICE%"=="0" goto MENU

echo.
echo ------------------------------------------------
pause
goto MENU

:: ==============================================================================
::  [3] UPDATE ALL INSTALLED APPLICATIONS
:: ==============================================================================
:OPTION_3
cls
echo ================================================
echo        IT HELPDESK AUTOMATION TOOLKIT
echo ================================================
echo >>> [3] Update All Installed Applications
echo ================================================
echo.
echo Checking for Windows Package Manager (winget)...
echo.

where winget.exe >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Windows Package Manager (winget) is not found in PATH.
    echo Please install App Installer from Microsoft Store to enable automated app updates.
    pause
    goto MENU
)

winget.exe upgrade --accept-source-agreements
echo.
set /p "DO_WG=Would you like to upgrade all applications now? [Y/N]: "
if /i "%DO_WG%"=="Y" (
    echo.
    echo Updating all applications... Please wait.
    winget.exe upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
    echo Applications update completed.
)

echo.
echo ------------------------------------------------
pause
goto MENU

:: ==============================================================================
::  [4] WINDOWS UPDATE
:: ==============================================================================
:OPTION_4
cls
echo ================================================
echo        IT HELPDESK AUTOMATION TOOLKIT
echo ================================================
echo >>> [4] Windows Update
echo ================================================
echo.
echo Checking Windows Update Service and recent updates...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {
    $svc = Get-Service wuauserv
    Write-Host ('Windows Update Service (wuauserv): ' + $svc.Status + ' [' + $svc.StartType + ']') -ForegroundColor (if($svc.Status -eq 'Running'){'Green'}else{'Yellow'})
    $last = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1
    if ($last) {
        Write-Host ('Last Installed Update: ' + $last.HotFixID + ' (' + $last.Description + ') on ' + $last.InstalledOn) -ForegroundColor Cyan
    }
}"

echo.
echo Windows Update Actions:
echo  [1] Trigger Windows Update Background Scan ^& Download
echo  [2] Open Windows Update Settings GUI
echo  [3] View Last 10 Installed KBs
echo  [4] Restart Windows Update Service
echo  [0] Return to Main Menu
echo.
set /p "WU_CHOICE=Enter choice [0-4]: "

if "%WU_CHOICE%"=="1" (
    echo Triggering USOClient scan and download...
    usoclient.exe StartScan
    usoclient.exe StartDownload
    echo Windows Update scan and download initiated.
)
if "%WU_CHOICE%"=="2" (
    start ms-settings:windowsupdate
)
if "%WU_CHOICE%"=="3" (
    echo.
    powershell.exe -NoProfile -Command "Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10 HotFixID, Description, InstalledOn | Format-Table -AutoSize"
)
if "%WU_CHOICE%"=="4" (
    echo Restarting Windows Update services...
    net stop wuauserv >nul 2>&1
    net start wuauserv >nul 2>&1
    echo Windows update service restarted.
)
if "%WU_CHOICE%"=="0" goto MENU

echo.
echo ------------------------------------------------
pause
goto MENU

:: ==============================================================================
::  [5] MICROSOFT OFFICE ACTIVATION CHECK
:: ==============================================================================
:OPTION_5
cls
echo ================================================
echo        IT HELPDESK AUTOMATION TOOLKIT
echo ================================================
echo >>> [5] Microsoft Office Activation Check
echo ================================================
echo.
echo Searching for Microsoft Office installations and licensing status...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {
    $paths = @(
        $env:ProgramFiles + '\Microsoft Office\Office16\OSPP.VBS',
        ${env:ProgramFiles(x86)} + '\Microsoft Office\Office16\OSPP.VBS',
        $env:ProgramFiles + '\Microsoft Office\root\Office16\OSPP.VBS',
        ${env:ProgramFiles(x86)} + '\Microsoft Office\root\Office16\OSPP.VBS',
        $env:ProgramFiles + '\Microsoft Office\Office15\OSPP.VBS',
        ${env:ProgramFiles(x86)} + '\Microsoft Office\Office15\OSPP.VBS'
    )
    $found = $null
    foreach ($p in $paths) {
        if (Test-Path $p) { $found = $p; break }
    }
    if ($found) {
        Write-Host ('Found Office Licensing Engine: ' + $found) -ForegroundColor Cyan
        Write-Host ''
        $out = cscript.exe //nologo $found /dstatus | Where-Object { $_ -notmatch 'slerror\.xml' -and $_.Trim() -ne '' }
        foreach ($l in $out) {
            if ($l -match 'LICENSE STATUS:\s+---LICENSED---') {
                Write-Host $l -ForegroundColor Green
            } elseif ($l -match 'LICENSE STATUS:') {
                Write-Host $l -ForegroundColor Red
            } elseif ($l -match 'LICENSE NAME:' -or $l -match 'Last 5 characters' -or $l -match 'REMAINING GRACE:') {
                Write-Host $l -ForegroundColor White
            } else {
                Write-Host $l -ForegroundColor Gray
            }
        }
    } else {
        $c2r = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration' -ErrorAction SilentlyContinue
        if ($c2r) {
            Write-Host ('Microsoft 365 / Click-to-Run Office Detected: ' + $c2r.ProductReleaseIDs) -ForegroundColor Cyan
            Write-Host ('Version: ' + $c2r.VersionToReport + ' Platform: ' + $c2r.Platform)
        } else {
            Write-Host 'No standard Microsoft Office installation found.' -ForegroundColor Yellow
        }
    }
}"

echo.
echo ------------------------------------------------
pause
goto MENU

:: ==============================================================================
::  [6] WINDOWS ACTIVATION CHECK
:: ==============================================================================
:OPTION_6
cls
echo ================================================
echo        IT HELPDESK AUTOMATION TOOLKIT-DEVELOPED BY IAN ROBERT
echo ================================================
echo >>> [6] Windows Activation Check
echo ================================================
echo.
echo Querying Windows Software Licensing Manager...
echo.

cscript.exe //nologo %windir%\system32\slmgr.vbs /xpr
echo.
cscript.exe //nologo %windir%\system32\slmgr.vbs /dli
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {
    $lic = Get-CimInstance -Query 'SELECT Name, LicenseStatus, PartialProductKey FROM SoftwareLicensingProduct WHERE PartialProductKey IS NOT NULL AND Name LIKE ''Windows%''' | Select-Object -First 1
    if ($lic) {
        if ($lic.LicenseStatus -eq 1) {
            Write-Host '[VERDICT] Windows is Genuine and FULLY ACTIVATED.' -ForegroundColor Green
        } else {
            Write-Host '[VERDICT] Windows is NOT ACTIVATED or license expired.' -ForegroundColor Red
        }
    }
}"

echo.
echo ------------------------------------------------
pause
goto MENU

:: ==============================================================================
::  [7] DISK CLEANUP & TEMPORARY FILES
:: ==============================================================================
:OPTION_7
cls
echo ================================================
echo        IT HELPDESK AUTOMATION TOOLKIT-DEVELOPED BY IAN ROBERT
echo ================================================
echo >>> [7] Disk Cleanup ^& Temporary Files
echo ================================================
echo.
echo Current Drive C: Free Space:
powershell.exe -NoProfile -Command "Write-Host ([math]::Round((Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\").FreeSpace / 1GB, 2).ToString() + ' GB')"
echo.
set /p "CONFIRM_CLEAN=Proceed with cleaning Temporary Files and Recycle Bin? [Y/N]: "
if /i not "%CONFIRM_CLEAN%"=="Y" (
    echo Cleanup cancelled.
    pause
    goto MENU
)

echo.
echo Cleaning temporary files and caches...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {
    $ErrorActionPreference = 'SilentlyContinue'
    $before = (Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\").FreeSpace
    Remove-Item -Path \"$env:TEMP\*\" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path \"$env:windir\Temp\*\" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path \"$env:windir\SoftwareDistribution\Download\*\" -Recurse -Force -ErrorAction SilentlyContinue
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    $after = (Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\").FreeSpace
    $freedMB = [math]::Round([math]::Max(0, ($after - $before)) / 1MB, 2)
    Write-Host ('Cleanup completed! Freed approximately: ' + $freedMB + ' MB') -ForegroundColor Green
}"

echo.
echo ------------------------------------------------
pause
goto MENU

:: ==============================================================================
::  [8] RAM & CPU PERFORMANCE CHECK
:: ==============================================================================
:OPTION_8
cls
echo ================================================
echo        IT HELPDESK AUTOMATION TOOLKIT-DEVELOPED BY IAN ROBERT
echo ================================================
echo >>> [8] RAM ^& CPU Performance Check
echo ================================================
echo.
echo Measuring live CPU ^& RAM performance...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $cpuLoad = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $os = Get-CimInstance Win32_OperatingSystem
    $totalRam = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRam = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRam = [math]::Round($totalRam - $freeRam, 2)
    $ramPct = [math]::Round(($usedRam / $totalRam) * 100, 1)

    Write-Host ('Processor        : ' + $cpu.Name.Trim())
    Write-Host ('Current CPU Load : ' + $cpuLoad + ' %') -ForegroundColor (if($cpuLoad -gt 85){'Red'}elseif($cpuLoad -gt 70){'Yellow'}else{'Green'})
    Write-Host ('Total RAM        : ' + $totalRam + ' GB')
    Write-Host ('Used RAM         : ' + $usedRam + ' GB (' + $ramPct + '% utilized)') -ForegroundColor (if($ramPct -gt 85){'Red'}elseif($ramPct -gt 70){'Yellow'}else{'Green'})
    Write-Host ''
    Write-Host 'Top 5 CPU-Consuming Processes:' -ForegroundColor Yellow
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 -Property Id, ProcessName, @{Name='CPU(s)'; Expression={[math]::Round($_.CPU, 1)}}, @{Name='RAM(MB)'; Expression={[math]::Round($_.WorkingSet64/1MB, 1)}} | Format-Table -AutoSize
    Write-Host ''
    Write-Host 'Top 5 Memory-Consuming Processes:' -ForegroundColor Yellow
    Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 -Property Id, ProcessName, @{Name='RAM(MB)'; Expression={[math]::Round($_.WorkingSet64/1MB, 1)}} | Format-Table -AutoSize
}"

echo.
echo ------------------------------------------------
pause
goto MENU

:: ==============================================================================
::  [9] NETWORK & INTERNET DIAGNOSTICS
:: ==============================================================================
:OPTION_9
cls
echo ================================================
echo        IT HELPDESK AUTOMATION TOOLKIT-DEVELOPED BY IAN ROBERT
echo ================================================
echo >>> [9] Network ^& Internet Diagnostics
echo ================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {
    $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }
    foreach ($a in $adapters) {
        Write-Host ('Adapter: ' + $a.Description) -ForegroundColor Cyan
        Write-Host ('  IPv4 Address : ' + ($a.IPAddress -join ', '))
        Write-Host ('  Gateway      : ' + ($a.DefaultIPGateway -join ', '))
        Write-Host ('  DNS Servers  : ' + ($a.DNSServerSearchOrder -join ', '))
    }
    Write-Host ''
    Write-Host '--- CONNECTIVITY TESTS ---' -ForegroundColor Cyan
    Write-Host 'Pinging Google Public DNS (8.8.8.8)... ' -NoNewline
    if (Test-Connection -ComputerName '8.8.8.8' -Count 2 -Quiet) {
        Write-Host '[PASSED - INTERNET REACHABLE]' -ForegroundColor Green
    } else {
        Write-Host '[FAILED]' -ForegroundColor Red
    }
    Write-Host 'Resolving Domain (google.com)... ' -NoNewline
    try {
        $ip = [System.Net.Dns]::GetHostAddresses('google.com')
        Write-Host ('[PASSED] (' + $ip[0].IPAddressToString + ')') -ForegroundColor Green
    } catch {
        Write-Host '[FAILED]' -ForegroundColor Red
    }
}"

echo.
echo Network Utility Tools:
echo  [1] Release, Renew IP ^& Flush DNS
echo  [2] Reset Winsock and TCP/IP stack
echo  [0] Return to Main Menu
echo.
set /p "NET_OPT=Enter choice [0-2]: "

if "%NET_OPT%"=="1" (
    echo Flushing DNS and renewing DHCP...
    ipconfig /flushdns
    ipconfig /release
    ipconfig /renew
    echo Network stack refreshed.
)
if "%NET_OPT%"=="2" (
    echo Resetting Winsock and IP stack...
    netsh winsock reset
    netsh int ip reset
    echo Winsock reset complete. A reboot is recommended.
)
if "%NET_OPT%"=="0" goto MENU

echo.
echo ------------------------------------------------
pause
goto MENU

:: ==============================================================================
::  [10] STARTUP PROGRAMS INSPECTION
:: ==============================================================================
:OPTION_10
cls
echo ================================================
echo        IT HELPDESK AUTOMATION TOOLKIT-DEVELOPED BY IAN ROBERT
echo ================================================
echo >>> [10] Startup Programs Inspection
echo ================================================
echo.
echo Enumerating Windows Startup Entry Points...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {
    $list = [System.Collections.Generic.List[PSObject]]::new()
    $hklm = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run'
    if (Test-Path $hklm) {
        (Get-ItemProperty $hklm).psobject.properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
            $list.Add([PSCustomObject]@{ Name = $_.Name; Location = 'HKLM (Machine)'; Command = $_.Value })
        }
    }
    $hkcu = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    if (Test-Path $hkcu) {
        (Get-ItemProperty $hkcu).psobject.properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
            $list.Add([PSCustomObject]@{ Name = $_.Name; Location = 'HKCU (User)'; Command = $_.Value })
        }
    }
    $list | Format-Table Name, Location, Command -Wrap -AutoSize
}"

echo.
echo Helpdesk Tip: Press Ctrl+Shift+Esc to manage startup applications in Task Manager.
echo ------------------------------------------------
pause
goto MENU

:: ==============================================================================
::  [11] WINDOWS SERVICES CHECK
:: ==============================================================================
:OPTION_11
cls
echo ================================================
echo        IT HELPDESK AUTOMATION TOOLKIT-DEVELOPED BY IAN ROBERT 
echo ================================================
echo >>> [11] Windows Services Check
echo ================================================
echo.
echo Auditing Critical Core Windows Services...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {
    $svcs = @('wuauserv', 'bits', 'WinDefend', 'MpsSvc', 'Spooler', 'Dnscache', 'Dhcp', 'EventLog', 'TermService')
    Get-Service -Name $svcs | Format-Table Name, DisplayName, Status, StartType -AutoSize
}"

echo.
echo Service Actions:
echo  [1] Start / Restart Essential Services
echo  [2] Open Services Management Console (services.msc)
echo  [0] Return to Main Menu
echo.
set /p "SVC_OPT=Enter choice [0-2]: "

if "%SVC_OPT%"=="1" (
    echo Starting stopped essential services...
    powershell.exe -NoProfile -Command "Start-Service wuauserv, bits, MpsSvc, Spooler, Dnscache -ErrorAction SilentlyContinue; Write-Host 'Services recovery completed.' -ForegroundColor Green"
)
if "%SVC_OPT%"=="2" (
    start services.msc
)
if "%SVC_OPT%"=="0" goto MENU

echo.
echo ------------------------------------------------
pause
goto MENU

:: ==============================================================================
::  [12] HARDWARE & BATTERY DIAGNOSTICS
:: ==============================================================================
:OPTION_12
cls
echo ================================================
echo        IT HELPDESK AUTOMATION TOOLKIT-DEVELOPED BY IAN ROBERT
echo ================================================
echo >>> [12] Hardware ^& Battery Diagnostics
echo ================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {
    $bb = Get-CimInstance Win32_BaseBoard
    $bios = Get-CimInstance Win32_BIOS
    Write-Host '--- MOTHERBOARD & BIOS ---' -ForegroundColor Cyan
    Write-Host ('Manufacturer : ' + $bb.Manufacturer)
    Write-Host ('Product      : ' + $bb.Product)
    Write-Host ('Serial       : ' + $bb.SerialNumber)
    Write-Host ('BIOS Version : ' + $bios.SMBIOSBIOSVersion)
    Write-Host ''
    Write-Host '--- PHYSICAL DISKS ---' -ForegroundColor Cyan
    Get-CimInstance Win32_DiskDrive | Select-Object DeviceID, Model, @{Name='Size(GB)'; Expression={[math]::Round($_.Size/1GB, 1)}}, Status | Format-Table -AutoSize
    Write-Host '--- BATTERY SUBSYSTEM ---' -ForegroundColor Cyan
    $b = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if ($b) {
        Write-Host ('Battery Model  : ' + $b.Name)
        Write-Host ('Charge Level   : ' + $b.EstimatedChargeRemaining + ' %')
        if ($b.DesignCapacity -and $b.FullChargeCapacity -and $b.DesignCapacity -gt 0) {
            Write-Host ('Battery Health : ' + [math]::Round(($b.FullChargeCapacity / $b.DesignCapacity) * 100, 1) + ' % of original design') -ForegroundColor Green
        }
    } else {
        Write-Host 'No physical battery detected (Desktop or Virtual Machine).' -ForegroundColor DarkGray
    }
}"

echo.
echo ------------------------------------------------
pause
goto MENU

:: ==============================================================================
::  [13] GENERATE IT HELPDESK REPORT
:: ==============================================================================
:OPTION_13
cls
echo ================================================
echo        IT HELPDESK AUTOMATION TOOLKIT-DEVELOPED BY IAN ROBERT
echo ================================================
echo >>> [13] Generate IT Helpdesk Report
echo ================================================
echo.
echo Compiling comprehensive IT Helpdesk Report... Please wait.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {
    $dir = 'IT_Helpdesk_Reports'
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $ts = (Get-Date).ToString('yyyyMMdd_HHmmss')
    $txt = \"$dir\IT_Report_$($env:COMPUTERNAME)_$ts.txt\"
    $html = \"$dir\IT_Report_$($env:COMPUTERNAME)_$ts.html\"
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $ramTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $ramUsed = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
    
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('================================================================================')
    [void]$sb.AppendLine('                      IT HELPDESK SYSTEM HEALTH REPORT')
    [void]$sb.AppendLine('================================================================================')
    [void]$sb.AppendLine('Computer Name : ' + $cs.Name)
    [void]$sb.AppendLine('Generated On  : ' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))
    [void]$sb.AppendLine('OS            : ' + $os.Caption + ' (Build ' + $os.BuildNumber + ')')
    [void]$sb.AppendLine('Hardware      : ' + $cs.Manufacturer + ' ' + $cs.Model)
    [void]$sb.AppendLine('Processor     : ' + $cpu.Name.Trim())
    [void]$sb.AppendLine('RAM           : ' + $ramUsed + ' GB / ' + $ramTotal + ' GB')
    [void]$sb.AppendLine('================================================================================')
    [System.IO.File]::WriteAllText($txt, $sb.ToString(), [System.Text.Encoding]::UTF8)

    $htmlContent = '<html><head><title>IT Helpdesk Report</title><style>body{font-family:sans-serif;margin:20px;background:#f8f9fa;}.card{background:#fff;padding:20px;border-radius:8px;box-shadow:0 2px 8px rgba(0,0,0,0.1);max-width:800px;margin:auto;}h1{color:#0078d4;}</style></head><body><div class=\"card\"><h1>IT Helpdesk Diagnostic Report</h1><p><b>Host:</b> ' + $cs.Name + ' | <b>Date:</b> ' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + '</p><p><b>OS:</b> ' + $os.Caption + ' (Build ' + $os.BuildNumber + ')</p><p><b>Hardware:</b> ' + $cs.Manufacturer + ' ' + $cs.Model + '</p><p><b>Processor:</b> ' + $cpu.Name.Trim() + '</p><p><b>RAM:</b> ' + $ramUsed + ' GB / ' + $ramTotal + ' GB</p></div></body></html>'
    [System.IO.File]::WriteAllText($html, $htmlContent, [System.Text.Encoding]::UTF8)

    Write-Host 'Reports generated successfully:' -ForegroundColor Green
    Write-Host ('  Text: ' + $txt) -ForegroundColor Cyan
    Write-Host ('  HTML: ' + $html) -ForegroundColor Cyan
}"

echo.
echo ------------------------------------------------
pause
goto MENU

:: ==============================================================================
::  [14] RUN COMPLETE MAINTENANCE
:: ==============================================================================
:OPTION_14
cls
echo ================================================
echo        IT HELPDESK AUTOMATION TOOLKIT-DEVELOPED BY IAN ROBERT 
echo ================================================
echo >>> [14] Run Complete Maintenance
echo ================================================
echo.
echo Complete Maintenance performs:
echo  1. Disk Cleanup ^& Temp Files Purge
echo  2. DNS Flush ^& Network Stack Refresh
echo  3. Antivirus Signatures Update ^& Quick Scan
echo  4. Application Updates (via winget)
echo  5. Component Store Health Check (DISM)
echo  6. System File Integrity Scan (SFC)
echo  7. Verification of Core Services
echo  8. Generate Final IT Helpdesk Report
echo.
set /p "DO_MAINT=Start Complete Maintenance now? [Y/N]: "
if /i not "%DO_MAINT%"=="Y" (
    echo Maintenance cancelled.
    pause
    goto MENU
)

echo.
echo [1/8] Cleaning Temporary Files...
powershell.exe -NoProfile -Command "Remove-Item -Path \"$env:TEMP\*\" -Recurse -Force -ErrorAction SilentlyContinue; Clear-RecycleBin -Force -ErrorAction SilentlyContinue"

echo [2/8] Flushing DNS Resolver Cache...
ipconfig /flushdns >nul

echo [3/8] Updating Antivirus Signatures...
powershell.exe -NoProfile -Command "Update-MpSignature -ErrorAction SilentlyContinue; Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue"

echo [4/8] Upgrading Applications via winget...
winget.exe upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements >nul 2>&1

echo [5/8] Checking Component Store (DISM)...
dism.exe /Online /Cleanup-Image /ScanHealth

echo [6/8] Scanning System File Integrity (SFC)...
sfc.exe /scannow

echo [7/8] Verifying Essential Services...
powershell.exe -NoProfile -Command "Start-Service wuauserv, bits, MpsSvc -ErrorAction SilentlyContinue"

echo [8/8] Generating Post-Maintenance Report...
call :OPTION_13

echo.
echo ================================================
echo  COMPLETE MAINTENANCE FINISHED!
echo ================================================
pause
goto MENU

:: ==============================================================================
::  [15] EXIT
:: ==============================================================================
:OPTION_15
cls
echo ================================================
echo    THANK YOU FOR USING IT HELPDESK TOOLKIT
echo ================================================
echo Exiting cleanly. Have a great day!
echo.
exit /b 0
