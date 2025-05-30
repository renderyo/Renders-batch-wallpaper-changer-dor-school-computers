@echo off
setlocal

:: Ask for image path
set /p imgPath=Enter the full path to the image file: 

:: Check if the file exists
if not exist "%imgPath%" (
    echo File does not exist. Exiting...
    exit /b
)

:: Set wallpaper in registry
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "%imgPath%" /f

:: Update the wallpaper
RUNDLL32.EXE user32.dll, UpdatePerUserSystemParameters

:: Get full path of this script
set "scriptPath=%~f0"

:: Add this script to autorun (Run key in registry)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v SetWallpaper /t REG_SZ /d "\"%scriptPath%\"" /f

echo Wallpaper set successfully and script added to autorun.
pause
