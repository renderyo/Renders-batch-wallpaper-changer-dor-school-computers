# --- Ultimate Stable Persistent Wallpaper Changer ---

# Ensure we load the API type only once globally
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

# Function to set wallpaper using SystemParametersInfo
function Set-WallpaperAPI {
    param($imagePath)
    try {
        [Wallpaper]::SystemParametersInfo(20, 0, $imagePath, 3) | Out-Null
    } catch {
        Write-Host "SystemParametersInfo failed: $_"
    }
}

# Function to set wallpaper using registry
function Set-WallpaperRegistry {
    param($imagePath)
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value $imagePath -ErrorAction SilentlyContinue
        rundll32.exe user32.dll,UpdatePerUserSystemParameters
    } catch {
        Write-Host "Registry method failed: $_"
    }
}

# Function to set wallpaper using COM
function Set-WallpaperCOM {
    param($imagePath)
    try {
        $wsh = New-Object -ComObject WScript.Shell
        $wsh.RegWrite("HKCU\Control Panel\Desktop\Wallpaper", $imagePath)
        rundll32.exe user32.dll,UpdatePerUserSystemParameters
    } catch {
        Write-Host "COM method failed: $_"
    }
}

# Function to add script to autorun
function Add-AutoRun {
    param($scriptPath)
    try {
        $key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        $name = "PersistentWallpaperChanger"
        $value = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
        Set-ItemProperty -Path $key -Name $name -Value $value -ErrorAction SilentlyContinue
        Write-Host "Added to autorun successfully."
    } catch {
        Write-Host "Failed to add to autorun: $_"
    }
}

# Main execution
try {
    $imagePath = Read-Host "Enter the full path to your wallpaper image"

    if (-Not (Test-Path $imagePath)) {
        Write-Host "ERROR: The specified image path does not exist. Exiting..."
        exit 1
    }

    $selfPath = $MyInvocation.MyCommand.Definition

    Add-AutoRun -scriptPath $selfPath

    Write-Host "Starting persistent wallpaper enforcement loop. Press CTRL+C to stop."

    while ($true) {
        Set-WallpaperAPI -imagePath $imagePath
        Set-WallpaperRegistry -imagePath $imagePath
        Set-WallpaperCOM -imagePath $imagePath
        Start-Sleep -Seconds 1
    }
} catch {
    Write-Host "Fatal Error: $_"
    pause
}
