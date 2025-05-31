# --- Persistent Wallpaper Changer with Hidden Background ---

# Function to set wallpaper using SystemParametersInfo
function Set-WallpaperAPI {
    param($imagePath)
    try {
        Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@ -ErrorAction Stop
    } catch {
        # Already added
    }
    [Wallpaper]::SystemParametersInfo(20, 0, $imagePath, 3) | Out-Null
}

# Function to set wallpaper using registry
function Set-WallpaperRegistry {
    param($imagePath)
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value $imagePath -ErrorAction SilentlyContinue
    rundll32.exe user32.dll,UpdatePerUserSystemParameters
}

# Function to set wallpaper using COM
function Set-WallpaperCOM {
    param($imagePath)
    try {
        $wsh = New-Object -ComObject WScript.Shell
        $wsh.RegWrite("HKCU\Control Panel\Desktop\Wallpaper", $imagePath)
        rundll32.exe user32.dll,UpdatePerUserSystemParameters
    } catch {
        # Ignore
    }
}

# Function to add autorun
function Add-AutoRun {
    param($scriptPath)
    $key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $name = "PersistentWallpaperChanger"
    $value = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
    try {
        Set-ItemProperty -Path $key -Name $name -Value $value -ErrorAction SilentlyContinue
        Write-Output "Added to autorun successfully."
    } catch {
        Write-Output "Failed to add to autorun: $_"
    }
}

# CONFIG FILE TO STORE IMAGE PATH
$configFile = "$env:APPDATA\PersistentWallpaperConfig.txt"

# Self path for autorun
$selfPath = $MyInvocation.MyCommand.Definition

# --- MAIN LOGIC ---

if (-Not (Test-Path $configFile)) {
    # First time setup
    $imagePath = Read-Host "Enter the full path to your wallpaper image"
    if (-Not (Test-Path $imagePath)) {
        Write-Host "The specified image path does not exist. Exiting..."
        exit
    }
    $imagePath | Out-File -Encoding ASCII -FilePath $configFile
    Add-AutoRun -scriptPath $selfPath
    Write-Host "Configuration saved. Please restart the script."
    exit
} else {
    # Config exists, read image path
    $imagePath = Get-Content -Path $configFile -ErrorAction SilentlyContinue
}

# Check for hidden mode
param([switch]$HiddenRun)

if (-Not $HiddenRun) {
    # Relaunch in background hidden mode
    Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$selfPath`" -HiddenRun"
    exit
}

# --- HIDDEN BACKGROUND LOOP ---
while ($true) {
    try {
        Set-WallpaperAPI -imagePath $imagePath
        Set-WallpaperRegistry -imagePath $imagePath
        Set-WallpaperCOM -imagePath $imagePath
    } catch {
        # Suppress errors
    }
    Start-Sleep -Seconds 1
}



