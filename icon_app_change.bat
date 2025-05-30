@echo off
setlocal

:: Prompt for .ico path
set /p icoPath="Enter FULL path to the .ico file: "

:: Check if file exists
if not exist "%icoPath%" (
    echo File not found!
    pause
    exit /b
)

:: Set Desktop path
set "desktop=%USERPROFILE%\Desktop"

echo Searching for shortcuts on Desktop...

:: Loop through all .lnk files
for %%F in ("%desktop%\*.lnk") do (
    echo Changing icon for: %%~fF
    powershell -Command "try { $s = (New-Object -ComObject WScript.Shell).CreateShortcut('%%~fF'); $s.IconLocation = '%icoPath%'; $s.Save(); Write-Output 'Icon changed for %%~nxF'; } catch { Write-Output 'Error changing icon for %%~nxF' }"
)

echo Done! Press any key to exit.
pause
