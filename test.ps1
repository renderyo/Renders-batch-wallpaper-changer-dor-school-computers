# --- Improved Persistent Wallpaper Changer with Hidden Background Execution ---

param (
    [switch]$background
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
    } catch {}
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
    } catch {}
}

# Function to add script to autorun
function Add-AutoRun {
    param($scriptPath)
    $key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $name = "PersistentWallpaperChanger"
    $value = "powershell.exe -ExecutionPolicy Bypass -File `"$scriptPath`""
    try {
        Set-ItemProperty -Path $key -Name $name -Value $value -ErrorAction SilentlyContinue
        Write-Output "Added to autorun successfully."
    } catch {
        Write-Output "Failed to add to autorun: $_"
    }
}

# Path to this script
$selfPath = $MyInvocation.MyCommand.Definition

if (-not $background) {
    # First run or startup without background flag

    # Ask user for image path
    $imagePath = Read-Host "Enter the full path to your wallpaper image"

    # Validate image path
    if (-Not (Test-Path $imagePath)) {
        Write-Host "The specified image path does not exist. Exiting..."
        exit
    }

    # Save image path to a config file in AppData
    $configPath = "$env:APPDATA\PersistentWallpaperConfig.txt"
    Set-Content -Path $configPath -Value $imagePath

    # Add to autorun
    Add-AutoRun -scriptPath $selfPath

    Write-Host "Wallpaper changer set up successfully."

    # Launch background instance hidden
    Start-Process powershell.exe "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$selfPath`" -background"

    Write-Host "Started in background. Exiting foreground instance..."
    exit
}

# --- Background persistent wallpaper loop ---

# Read image path from config
$configPath = "$env:APPDATA\PersistentWallpaperConfig.txt"
if (-Not (Test-Path $configPath)) {
    Write-Host "No config found. Exiting..."
    exit
}

$imagePath = Get-Content -Path $configPath

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
    } catch {}
    Start-Sleep -Seconds 1
}

