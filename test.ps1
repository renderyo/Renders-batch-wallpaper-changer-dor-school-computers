# --- Persistent Wallpaper Changer with Correct Hidden Relaunch ---

param(
    [string]$imagePath
)

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
        # COM might fail; ignore
    }
}

# Function to add script to autorun
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

# If no image path provided, assume foreground mode
if (-not $imagePath) {
    $imagePath = Read-Host "Enter the full path to your wallpaper image"

    if (-Not (Test-Path $imagePath)) {
        Write-Host "The specified image path does not exist. Exiting..."
        exit
    }

    $selfPath = $MyInvocation.MyCommand.Definition

    # Add to autorun
    Add-AutoRun -scriptPath $selfPath

    # Relaunch hidden with image path
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$selfPath`" -imagePath `"$imagePath`"" -WindowStyle Hidden
    Write-Host "Launched in background. Exiting foreground process..."
    exit
}

# Background mode: validate image exists
if (-Not (Test-Path $imagePath)) {
    Write-Host "Image path not found. Exiting..."
    exit
}

# Initial set
Set-WallpaperAPI -imagePath $imagePath
Set-WallpaperRegistry -imagePath $imagePath
Set-WallpaperCOM -imagePath $imagePath

# Infinite loop to enforce wallpaper
while ($true) {
    try {
        Set-WallpaperAPI -imagePath $imagePath
        Set-WallpaperRegistry -imagePath $imagePath
        Set-WallpaperCOM -imagePath $imagePath
    } catch {
        # Ignore errors
    }
    Start-Sleep -Seconds 1
}
