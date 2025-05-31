# --- Persistent Wallpaper Changer with Hidden Background Execution ---

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

# Self path for autorun
$selfPath = $MyInvocation.MyCommand.Definition

# Check if this is running as a background worker
param(
    [switch]$Worker
)

if (-not $Worker) {
    # Launcher mode
    $imagePath = Read-Host "Enter the full path to your wallpaper image"

    # Validate image path
    if (-Not (Test-Path $imagePath)) {
        Write-Host "The specified image path does not exist. Exiting..."
        exit
    }

    # Save image path to config
    $configPath = "$env:APPDATA\PersistentWallpaperConfig.txt"
    $imagePath | Out-File -FilePath $configPath -Encoding UTF8

    # Add to autorun
    Add-AutoRun -scriptPath $selfPath

    Write-Host "Starting persistent wallpaper changer in the background..."
    
    # Start hidden worker process
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$selfPath`" -Worker" -WindowStyle Hidden

    Start-Sleep -Seconds 1
    exit
} else {
    # Background worker mode
    $configPath = "$env:APPDATA\PersistentWallpaperConfig.txt"
    if (-Not (Test-Path $configPath)) {
        Write-Host "Configuration not found. Exiting..."
        exit
    }
    $imagePath = Get-Content $configPath | Select-Object -First 1

    # Initial set
    Set-WallpaperAPI -imagePath $imagePath
    Set-WallpaperRegistry -imagePath $imagePath
    Set-WallpaperCOM -imagePath $imagePath

    # Infinite loop
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
}


