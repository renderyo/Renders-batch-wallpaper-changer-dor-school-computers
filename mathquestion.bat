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

echo Attempting various wallpaper change methods...

:: === Previous methods 1-8 omitted for brevity ===

:: === Method 9: Force Group Policy refresh ===
echo [9] Forcing Group Policy update...
gpupdate /force >nul 2>&1

:: Reapply registry in case policy reset it
reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "%imgPath%" /f >nul
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters

:: === Method 10: Send WM_SETTINGCHANGE via PowerShell to force desktop refresh ===
echo [10] Forcing desktop refresh with SendMessage...
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

:: === Method 11: Create scheduled task to set wallpaper at highest privilege ===
echo [11] Creating scheduled task to set wallpaper at highest privileges...
set taskScript=%TEMP%\setWallpaper.ps1
echo Add-Type -TypeDefinition '^
using System.Runtime.InteropServices;
public class Wallpaper {^
[DllImport("user32.dll",SetLastError=true)]^
public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);^
}^
'; [Wallpaper]::SystemParametersInfo(20, 0, '%imgPath%', 3) > "%taskScript%"

schtasks /create /tn "ForceWallpaperChange" /tr "powershell -ExecutionPolicy Bypass -File \"%taskScript%\"" /sc once /st 00:00 /rl HIGHEST /f >nul
schtasks /run /tn "ForceWallpaperChange" >nul
timeout /t 2 >nul
schtasks /delete /tn "ForceWallpaperChange" /f >nul
del "%taskScript%"

:: === Method 12: Overwrite TranscodedWallpaper file ===
echo [12] Overwriting TranscodedWallpaper cached file...
setlocal
set appdataPath=%APPDATA%\Microsoft\Windows\Themes
if exist "%appdataPath%\TranscodedWallpaper" (
    copy /y "%imgPath%" "%appdataPath%\TranscodedWallpaper" >nul
)
endlocal

:: === Method 13: Open Desktop Background settings to force manual/auto refresh ===
echo [13] Opening Desktop Background settings...
start control /name Microsoft.Personalization /page pageWallpaper

:: === Force another registry push and explorer restart ===
reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "%imgPath%" /f >nul
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 >nul
start explorer.exe

echo All advanced methods attempted.
pause
exit /b
