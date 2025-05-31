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

:: === Your existing methods (1-13) here ===
:: For brevity, skipping to the registry and refresh parts

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

:: === Save path to file for persistence ===
set saveFile=%APPDATA%\savedWallpaperPath.txt
echo %imgPath% > "%saveFile%"

:: === Create startup script to set wallpaper on boot ===
set startupScript=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\setWallpaperStartup.bat

(
    echo @echo off
    echo setlocal
    echo for /f "delims=" %%%%A in ('type "%saveFile%"') do set imgPath=%%%%A
    echo reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "%%imgPath%%" /f ^>nul
    echo powershell -command "Add-Type ^@'using System;using System.Runtime.InteropServices;public class Wallpaper { [DllImport(^\"user32.dll^\",SetLastError=true)] public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni); }^@'; [Wallpaper]::SystemParametersInfo(20, 0, '%%imgPath%%', 3)"
    echo taskkill /f /im explorer.exe ^>nul 2^>^&1
    echo timeout /t 2 ^>nul
    echo start explorer.exe
    echo endlocal
) > "%startupScript%"

echo Wallpaper path saved and startup script created.
echo The wallpaper will be automatically set on next boot.
pause
exit

