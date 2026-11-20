@echo off
setlocal EnableDelayedExpansion

:: ==============================================================================
::  IT HELPDESK AUTOMATION TOOLKIT - UNIVERSAL CMD LAUNCHER
::  Automatically detects genuine Git Bash / MSYS2 / Cygwin to launch the Bash
::  script with full color & diagnostics, or seamlessly falls back to the native
::  Windows Batch (.BAT) edition. Bypasses Windows WSL stubs and PATH issues.
:: ==============================================================================

:: Ensure working directory is always the script directory
cd /d "%~dp0"

:: Console Title and UTF-8 Character Encoding
title IT Helpdesk Automation Toolkit Launcher
chcp 65001 >nul 2>&1

:: Prevent MinGW / MSYS path conversion of Windows command arguments
set "MSYS_NO_PATHCONV=1"
set "MSYS2_ARG_CONV_EXCL=*"

set "SH_SCRIPT=%~dp0it_helpdesk_toolkit.sh"
set "BAT_SCRIPT=%~dp0it_helpdesk_toolkit.bat"

:: Check for manual override flags (--batch / --bat / --native)
if /i "%~1"=="--batch" goto LAUNCH_BATCH_DIRECT
if /i "%~1"=="-batch"  goto LAUNCH_BATCH_DIRECT
if /i "%~1"=="--bat"    goto LAUNCH_BATCH_DIRECT
if /i "%~1"=="-bat"    goto LAUNCH_BATCH_DIRECT
if /i "%~1"=="--native" goto LAUNCH_BATCH_DIRECT
if /i "%~1"=="-native"  goto LAUNCH_BATCH_DIRECT

:: ==============================================================================
::  STEP 1: LOCATE GENUINE BASH EXECUTABLE (Bypassing WSL stubs)
:: ==============================================================================
set "BASH_EXE="

:: 1A. Check standard 64-bit / 32-bit / User Git for Windows install paths
call :CHECK_BASH "%ProgramFiles%\Git\bin\bash.exe"
call :CHECK_BASH "%ProgramFiles%\Git\usr\bin\bash.exe"
call :CHECK_BASH "%ProgramFiles(x86)%\Git\bin\bash.exe"
call :CHECK_BASH "%ProgramFiles(x86)%\Git\usr\bin\bash.exe"
call :CHECK_BASH "%ProgramW6432%\Git\bin\bash.exe"
call :CHECK_BASH "%ProgramW6432%\Git\usr\bin\bash.exe"
call :CHECK_BASH "%LocalAppData%\Programs\Git\bin\bash.exe"
call :CHECK_BASH "%LocalAppData%\Programs\Git\usr\bin\bash.exe"
call :CHECK_BASH "C:\Git\bin\bash.exe"
call :CHECK_BASH "C:\Git\usr\bin\bash.exe"
call :CHECK_BASH "C:\msys64\usr\bin\bash.exe"
call :CHECK_BASH "C:\msys\usr\bin\bash.exe"
call :CHECK_BASH "C:\cygwin64\bin\bash.exe"
call :CHECK_BASH "C:\cygwin\bin\bash.exe"

:: 1B. Query Windows Registry for Git for Windows installation path
if not defined BASH_EXE (
    for %%K in (
        "HKLM\SOFTWARE\GitForWindows"
        "HKCU\SOFTWARE\GitForWindows"
        "HKLM\SOFTWARE\WOW6432Node\GitForWindows"
    ) do (
        if not defined BASH_EXE (
            for /f "tokens=1,2*" %%A in ('reg query %%K /v InstallPath 2^>nul') do (
                if /i "%%A"=="InstallPath" (
                    call :CHECK_BASH "%%C\bin\bash.exe"
                    call :CHECK_BASH "%%C\usr\bin\bash.exe"
                )
            )
        )
    )
)

:: 1C. Locate Git via git.exe in system PATH and resolve to bin\bash.exe
if not defined BASH_EXE (
    for /f "delims=" %%I in ('where git.exe 2^>nul') do (
        if not defined BASH_EXE (
            call :CHECK_BASH "%%~dpI..\bin\bash.exe"
            call :CHECK_BASH "%%~dpI..\usr\bin\bash.exe"
            call :CHECK_BASH "%%~dpIbin\bash.exe"
        )
    )
)

:: 1D. Search PATH for bash.exe, explicitly filtering out Windows WSL / WindowsApps stubs
if not defined BASH_EXE (
    for /f "delims=" %%I in ('where bash.exe 2^>nul') do (
        if not defined BASH_EXE (
            set "CANDIDATE=%%I"
            echo !CANDIDATE! | findstr /i /c:"\System32\" /c:"\SysWOW64\" /c:"\WindowsApps\" >nul 2>&1
            if errorlevel 1 (
                "%%I" -c "exit 0" >nul 2>&1
                if not errorlevel 1 (
                    set "BASH_EXE=%%I"
                )
            )
        )
    )
)

:: ==============================================================================
::  STEP 2: LAUNCH APPROPRIATE TOOLKIT SCRIPT
:: ==============================================================================

:: If genuine Bash is found and the bash script exists, launch it
if defined BASH_EXE (
    if exist "%SH_SCRIPT%" (
        "%BASH_EXE%" "%SH_SCRIPT%" %*
        exit /b %errorlevel%
    )
)

:: If genuine Bash is NOT found or .sh script is missing, fall back to native Batch
if exist "%BAT_SCRIPT%" (
    if not defined BASH_EXE (
        echo [INFO] Genuine Git Bash not detected in system.
        echo [INFO] Seamlessly falling back to Native Windows Batch edition...
        echo.
        timeout /t 2 >nul 2>&1
    )
    call "%BAT_SCRIPT%" %*
    exit /b %errorlevel%
)

:: If neither script can be found, report clear actionable error
echo ==============================================================================
echo  [ERROR] IT HELPDESK AUTOMATION TOOLKIT LAUNCH FAILURE
echo ==============================================================================
echo  Neither 'it_helpdesk_toolkit.sh' nor 'it_helpdesk_toolkit.bat' could be
echo  found or executed in the current directory:
echo    %~dp0
echo.
echo  Requirements to run:
echo    1. Ensure this file (run_in_cmd.bat) is located in the same folder as
echo       'it_helpdesk_toolkit.sh' and 'it_helpdesk_toolkit.bat'.
echo    2. For full ANSI diagnostics, install Git for Windows:
echo       https://git-scm.com/download/win
echo ==============================================================================
echo.
pause
exit /b 1

:: ==============================================================================
::  HELPER SUBROUTINE: Validate Bash Path
:: ==============================================================================
:CHECK_BASH
if defined BASH_EXE goto :eof
if "%~1"=="" goto :eof
if exist "%~1" (
    "%~1" -c "exit 0" >nul 2>&1
    if not errorlevel 1 (
        set "BASH_EXE=%~1"
    )
)
goto :eof

:: ==============================================================================
::  DIRECT BATCH OVERRIDE
:: ==============================================================================
:LAUNCH_BATCH_DIRECT
shift
if exist "%BAT_SCRIPT%" (
    call "%BAT_SCRIPT%" %*
    exit /b %errorlevel%
) else (
    echo [ERROR] Native batch script not found: %BAT_SCRIPT%
    pause
    exit /b 1
)
