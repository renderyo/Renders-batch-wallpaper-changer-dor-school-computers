@echo off
setlocal enabledelayedexpansion

:: Prompt for image path
set /p "cursorPath=Enter the full path to the .cur or .ani cursor image: "

:: Save the path in AppData
set "savePath=%APPDATA%\dametucositasave.txt"
echo !cursorPath! > "!savePath!"

:: Change the cursor by editing registry
reg add "HKCU\Control Panel\Cursors" /v Arrow /t REG_SZ /d "!cursorPath!" /f

:: Apply changes
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters

:: Add to autorun (registry)
set "scriptPath=%~f0"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v Dametucosita /t REG_SZ /d "\"%scriptPath%\"" /f

:: Minimize window (only hides future launches if converted to .vbs)
:: This session ends, future sessions will run minimized via .vbs

exit
