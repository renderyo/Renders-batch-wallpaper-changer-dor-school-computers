@echo off
setlocal

:: Ask for image path
set /p "imgPath=Enter full path of image: "

:: Check if exists
if not exist "%imgPath%" (
    echo File does not exist.
    pause
    exit /b
)

:: Save path
set "saveFile=%APPDATA%\savedWallpaperPath.txt"
echo %imgPath% > "%saveFile%"

:: Set wallpaper using PowerShell
powershell -NoProfile -Command ^
"Add-Type @'
using System;
using System.Runtime.InteropServices;
public class NativeMethods {
    [DllImport(\"user32.dll\", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
'@; [NativeMethods]::SystemParametersInfo(20, 0, '%imgPath%', 3)"

echo Wallpaper set successfully!

:: Create MonitorWallpaper.ps1
set "monitorScript=%APPDATA%\MonitorWallpaper.ps1"
(
    echo $savedPath = Get-Content "%saveFile%"
    echo function Set-Wallpaper($path) {
    echo     Add-Type @"
    echo     using System;
    echo     using System.Runtime.InteropServices;
    echo     public class NativeMethods {
    echo         [DllImport("user32.dll", SetLastError = true)]
    echo         public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    echo     }
    echo "@
    echo     [NativeMethods]::SystemParametersInfo(20, 0, $path, 3) ^| Out-Null
    echo }
    echo while ($true) {
    echo     $current = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper).Wallpaper
    echo     if ($current -ne $savedPath) {
    echo         Set-Wallpaper $savedPath
    echo         Write-Host "Wallpaper restored."
    echo     }
    echo     Start-Sleep -Seconds 5
    echo }
) > "%monitorScript%"

:: Create Watchdog2.ps1
set "watchdogScript=%APPDATA%\Watchdog2.ps1"
(
    echo function Add-Startup {
    echo     $script = $MyInvocation.MyCommand.Definition
    echo     $WshShell = New-Object -ComObject WScript.Shell
    echo     $shortcut = $WshShell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Watchdog2.lnk")
    echo     $shortcut.TargetPath = "powershell.exe"
    echo     $shortcut.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`""
    echo     $shortcut.Save()
    echo }
    echo Add-Startup
    echo Write-Host "Watchdog2 running..."
    echo while ($true) {
    echo     $proc = Get-Process chrome -ErrorAction SilentlyContinue
    echo     if ($proc) {
    echo         Write-Host "Chrome detected. Waiting 20 seconds..."
    echo         Start-Sleep -Seconds 20
    echo         Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
    echo         Write-Host "Chrome closed by Watchdog2."
    echo     }
    echo     Start-Sleep -Seconds 5
    echo }
) > "%watchdogScript%"

:: Create Startup launchers
set "startupFolder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

:: For MonitorWallpaper
(
    echo @echo off
    echo powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%monitorScript%"
) > "%startupFolder%\RunMonitorWallpaper.bat"

:: For Watchdog2 (it also adds itself but we can do it for safety)
(
    echo @echo off
    echo powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%watchdogScript%"
) > "%startupFolder%\RunWatchdog2.bat"

echo.
echo All scripts created successfully!
echo MonitorWallpaper and Watchdog2 will auto-run at startup.
echo.
pause
exit /b
