@echo off
setlocal enabledelayedexpansion

:: Ask for image path
set /p imgPath=Enter the full path of the image to set as wallpaper:

:: Check if file exists
if not exist "%imgPath%" (
    echo File does not exist!
    pause
    exit /b
)

:: Save path to file for persistence
set saveFile=%APPDATA%\savedWallpaperPath.txt
echo %imgPath% > "%saveFile%"

:: Set wallpaper via registry
reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "%imgPath%" /f >nul
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters

:: Force refresh
powershell -command "& {
    Add-Type @'
using System;
using System.Runtime.InteropServices;
public class Refresh {
    [DllImport(\"user32.dll\", SetLastError = true)]
    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
}
'@
    [UIntPtr]$result = 0
    [Refresh]::SendMessageTimeout([IntPtr]0xFFFF, 0x1A, [UIntPtr]0, 'Environment', 2, 5000, [ref]$result)
}"

:: Overwrite TranscodedWallpaper file
set appdataPath=%APPDATA%\Microsoft\Windows\Themes
if exist "%appdataPath%\TranscodedWallpaper" (
    copy /y "%imgPath%" "%appdataPath%\TranscodedWallpaper" >nul
)

:: Restart explorer to apply changes
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 >nul
start explorer.exe

:: === Create PowerShell Script to monitor wallpaper changes ===
set psScriptPath=%APPDATA%\monitorWallpaper.ps1
echo $savedPath = Get-Content "%saveFile%" > "%psScriptPath%"
echo $checkInterval = 5 >> "%psScriptPath%"
echo while ($true) { >> "%psScriptPath%"
echo     $currentWallpaper = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper).Wallpaper >> "%psScriptPath%"
echo     if ($currentWallpaper -ne $savedPath) { >> "%psScriptPath%"
echo         Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper -Value $savedPath >> "%psScriptPath%"
echo         rundll32 user32.dll,UpdatePerUserSystemParameters >> "%psScriptPath%"
echo         Write-Host 'Wallpaper reset to saved image' >> "%psScriptPath%"
echo     } >> "%psScriptPath%"
echo     Start-Sleep -Seconds $checkInterval >> "%psScriptPath%"
echo } >> "%psScriptPath%"

:: === Create Batch Script to Run PowerShell Script on Startup ===
set runStartupScript=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\runMonitor.bat
(
    echo @echo off
    echo powershell -ExecutionPolicy Bypass -File "%psScriptPath%" > "%runStartupScript%"
)

:: Restart Explorer to apply changes
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 >nul
start explorer.exe

echo Wallpaper path saved and monitoring script created.
echo The wallpaper will be automatically set on next boot and monitored in the background.
pause
exit
