@echo off
setlocal

:: Prompt for image path
set /p imgPath="Enter path to the .jpeg or .png image: "

:: Check if file exists
if not exist "%imgPath%" (
    echo File not found!
    pause
    exit /b
)

:: Convert image to .ico
echo Converting image to .ico...
magick convert "%imgPath%" -resize 256x256 "%~dpn1.ico"

set icoPath=%~dpn1.ico

:: Define locations to search for shortcuts
set searchDirs=%USERPROFILE%\Desktop %APPDATA%\Microsoft\Windows\Start Menu\Programs

for %%D in (%searchDirs%) do (
    echo Searching in: %%D

    for /r "%%D" %%F in (*.lnk) do (
        echo Changing icon for: %%F
        powershell -command "$s = (New-Object -COM WScript.Shell).CreateShortcut('%%F'); $s.IconLocation = '%icoPath%'; $s.Save()"
    )
)

echo Done! All shortcut icons updated.
pause
