@echo off
setlocal

:: Ask for image path
set /p imgPath=Enter the full path of the image to set as wallpaper: 

:: Check if file exists
if not exist "%imgPath%" (
    echo File does not exist!
    pause
    exit /b
)

:: Set the registry value for the wallpaper
reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "%imgPath%" /f

:: Apply the wallpaper change
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters

echo Wallpaper has been changed.
pause
exit /b
