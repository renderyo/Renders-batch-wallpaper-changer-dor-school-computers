@echo off
setlocal enabledelayedexpansion

:: Config file with wallpaper path
set "configFile=%APPDATA%\wallpaper_path.txt"

:: Check if config file exists
if exist "%configFile%" (
    :: Running in Startup mode
    set /p imgPath=<"%configFile%"
    echo Auto-applying wallpaper: %imgPath%
) else (
    :: Normal run: ask for wallpaper
    set /p imgPath=Enter the full path of the image to set as wallpaper:
    if not exist "%imgPath%" (
        echo File does not exist!
        pause
        exit /b
    )
    :: Save for future use
    echo %imgPath% > "%configFile%"
    echo Setting up auto-run...

    :: Copy self to Startup
    set "startupFolder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
    set "startupScript=%startupFolder%\wallpaper_enforcer.bat"
    copy /y "%~f0" "%startupScript%" >nul
)

:: === Apply wallpaper ===
reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "%imgPath%" /f >nul
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters

:: Overwrite TranscodedWallpaper
set "appdataPath=%APPDATA%\Microsoft\Windows\Themes"
if exist "%appdataPath%\TranscodedWallpaper" (
    copy /y "%imgPath%" "%appdataPath%\TranscodedWallpaper" >nul
)

:: Restart explorer to enforce change
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 >nul
start explorer.exe

echo Wallpaper enforced.
if not exist "%configFile%" pause
exit /b
