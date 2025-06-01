@echo off
setlocal

:: Define the path to the saved wallpaper file
set "WallpaperFile=%APPDATA%\savedWallpaperPath.txt"

:: Check if the wallpaper file exists
if not exist "%WallpaperFile%" exit

:: Define path to startup folder
set "StartupFolder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

:: Get full path to this batch script
set "ScriptPath=%~f0"

:: Define shortcut name
set "ShortcutName=WallpaperLoop.lnk"

:: Check if the shortcut already exists
if not exist "%StartupFolder%\%ShortcutName%" (
    :: Create a shortcut in the startup folder using PowerShell
    powershell -command ^
    "$s=(New-Object -COM WScript.Shell).CreateShortcut('%StartupFolder%\%ShortcutName%');" ^
    "$s.TargetPath='%ScriptPath%';" ^
    "$s.Save()"
)

:: Start the background PowerShell process
start "" powershell -windowstyle hidden -command ^
"while ($true) { ^
    $wallpaperPath = Get-Content -Path '%WallpaperFile%' -Raw; ^
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WallPaper -Value $wallpaperPath; ^
    RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters ,1 ,True; ^
    Start-Sleep -Seconds 1 ^
}"

:: Exit the batch script
exit
