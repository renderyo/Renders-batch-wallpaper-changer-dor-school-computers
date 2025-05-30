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

:: Convert image to .ico using ImageMagick
echo Converting image to .ico...
magick convert "%imgPath%" -resize 256x256 "%~dpn1.ico"

:: Set variables
set icoPath=%~dpn1.ico
set desktop=%USERPROFILE%\Desktop

echo Searching for shortcuts on Desktop...

:: Loop through all .lnk files on Desktop
for %%F in ("%desktop%\*.lnk") do (
    echo Changing icon for: %%F
    powershell -command "$s = (New-Object -COM WScript.Shell).CreateShortcut('%%F'); $s.IconLocation = '%icoPath%'; $s.Save()"
)

echo Done! All desktop shortcuts now use the new icon.
pause
