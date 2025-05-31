@echo off
setlocal enabledelayedexpansion

:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo This script requires administrative privileges. Please run as administrator.
    pause
    exit /b
)

:: Ask for image path
set /p "imgPath=Enter the full path of the image to set as wallpaper: "

:: Check if file exists
if not exist "%imgPath%" (
    echo File does not exist!
    pause
    exit /b
)

:: Save path to file for persistence
set "saveFile=%APPDATA%\savedWallpaperPath.txt"
echo %imgPath%>"%saveFile%"

:: Set wallpaper via registry
reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "%imgPath%" /f >nul

:: Notify system of environment change
powershell.exe -NoProfile -Command ^
"Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class NativeMethods {
    [DllImport(\"user32.dll\", SetLastError = true)]
    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
}
'@;
[UIntPtr]$result = 0;
[NativeMethods]::SendMessageTimeout([IntPtr]0xFFFF, 0x1A, [UIntPtr]0, 'Environment', 2, 5000, [ref]$result)
"

:: Overwrite TranscodedWallpaper file
set "appdataPath=%APPDATA%\Microsoft\Windows\Themes"
if exist "%appdataPath%\TranscodedWallpaper" (
    copy /y "%imgPath%" "%appdataPath%\TranscodedWallpaper" >nul
)

:: Restart explorer to apply changes
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 >nul
start explorer.exe

:: Create PowerShell script to monitor wallpaper changes
set "psScriptPath=%APPDATA%\monitorWallpaper.ps1"
(
    echo $savedPath = Get-Content "%saveFile%"
    echo $checkInterval = 5
    echo while ($true) {
    echo     $currentWallpaper = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper).Wallpaper
    echo     if ($currentWallpaper -ne $savedPath) {
    echo         Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper -Value $savedPath
    echo         rundll32 user32.dll,UpdatePerUserSystemParameters
    echo         Write-Host 'Wallpaper reset to saved image'
    echo     }
    echo     Start-Sleep -Seconds $checkInterval
    echo }
) > "%psScriptPath%"

:: Create batch script to run the PowerShell monitor at startup
set "startupScript=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\runMonitor.bat"
(
    echo @echo off
    echo powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%psScriptPath%"
) > "%startupScript%"

echo.
echo Wallpaper path saved and monitoring script created.
echo The wallpaper will be automatically reset if changed.
echo.
choice /m "Press Y to exit"
exit /b

