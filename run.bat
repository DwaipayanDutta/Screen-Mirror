@echo off
setlocal EnableExtensions
mode con: cols=92 lines=32
color 0B
title WiFi Screen Mirror

set "ROOT=%~dp0"
set "PS1=%ROOT%screen_mirror_beautified.ps1"

if not exist "%PS1%" (
    color 0C
    echo.
    echo  ============================================================================
    echo    ERROR: screen_mirror.ps1 was not found.
    echo  ============================================================================
    echo.
    echo    Expected:
    echo      %PS1%
    echo.
    pause
    exit /b 1
)

:: Request Administrator privileges for the firewall rule.
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    color 0E
    cls
    echo.
    echo  ============================================================================
    echo                 WIFI SCREEN MIRROR
    echo                 PC  ^>  MOBILE  ^>  WIFI
    echo  ============================================================================
    echo.
    echo    Administrator permission is required for the Windows Firewall rule.
    echo.
    echo    Requesting elevation...
    echo.
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cls
call :banner

echo.
echo  [*] Checking mirror configuration...
echo  [*] Loading Windows screen capture engine...
echo  [*] Preparing local WiFi endpoint...
echo.
echo  -----------------------------------------------------------------------------
echo  DEVICE FLOW
echo.
echo      WINDOWS PC
echo          ^|
echo          +---- Screen Capture
echo          ^|
echo          +---- Local WiFi
echo          ^|
echo          v
echo      ANDROID / MOBILE BROWSER
echo.
echo  -----------------------------------------------------------------------------
echo.
echo  [i] The phone URL will appear below.
echo  [i] Both devices must be connected to the SAME WiFi.
echo  [i] Press CTRL+C to stop the mirror.
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "EXITCODE=%errorlevel%"

echo.
if "%EXITCODE%"=="0" (
    color 0A
    echo  ============================================================================
    echo    MIRROR SESSION CLOSED
    echo  ============================================================================
) else (
    color 0C
    echo  ============================================================================
    echo    MIRROR STOPPED
    echo  ============================================================================
    echo    Exit code: %EXITCODE%
    echo  ============================================================================
)
echo.
pause
endlocal
exit /b %EXITCODE%

:banner
color 0B
echo.
echo  ============================================================================
echo        W I F I   S C R E E N   M I R R O R
echo        PC  ^>  ANDROID / MOBILE  ^>  LOCAL WIFI
echo  ============================================================================
echo.
echo        +-------------------+       +-------------------------+
echo        ^|   WINDOWS PC      ^|       ^|     MOBILE DEVICE      ^|
echo        ^|                   ^|       ^|                         ^|
echo        ^|   SCREEN CAPTURE  ^| ===== ^|  BROWSER STREAM         ^|
echo        ^|                   ^|  WiFi ^|                         ^|
echo        +-------------------+       +-------------------------+
echo.
echo        STATUS:  READY FOR LOCAL CONNECTION
exit /b
