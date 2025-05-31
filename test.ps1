# --- Fancy PowerShell Persistent Wallpaper Script ---

# Function to set wallpaper using SystemParametersInfo
function Set-WallpaperAPI {
    param($imagePath)
    Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
    [Wallpaper]::SystemParametersInfo(20, 0, $imagePath, 3) | Out-Null
}

# Function to set wallpaper using registry
function Set-WallpaperRegistry {
    param($imagePath)
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value $imagePath
    rundll32.exe user32.dll,UpdatePerUserSystemParameters
}

# Function to set wallpaper using COM
function Set-WallpaperCOM {
    param($imagePath)
    $wsh = New-Object -ComObject WScript.Shell
    $wsh.RegWrite("HKCU\Control Panel\Desktop\Wallpaper", $imagePath)
    rundll32.exe user32.dll,UpdatePerUserSystemParameters
}

# Function to add script to autorun
function Add-AutoRun {
    param($scriptPath)
    $key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $name = "PersistentWallpaperChanger"
    $value = "powershell.exe -ExecutionPolicy Bypass -File `"$scriptPath`""
    Set-ItemProperty -Path $key -Name $name -Value $value
    Write-Output "Added to autorun successfully."
}

# Ask user for image path
$imagePath = Read-Host "Enter the full path to your wallpaper image"

# Validate image path
if (-Not (Test-Path $imagePath)) {
    Write-Host "The specified image path does not exist. Exiting..."
    exit
}

# Self path for autorun
$selfPath = $MyInvocation.MyCommand.Definition

# Add to autorun
Add-AutoRun -scriptPath $selfPath

# First immediate wallpaper set
Set-WallpaperAPI -imagePath $imagePath
Set-WallpaperRegistry -imagePath $imagePath
Set-WallpaperCOM -imagePath $imagePath

Write-Host "Wallpaper set successfully. Starting persistent background enforcement..."

# Start background job to enforce wallpaper every second
Start-Job -ScriptBlock {
    param($imagePath)

    function Set-WallpaperAPI {
        param($imagePath)
        Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
        [Wallpaper]::SystemParametersInfo(20, 0, $imagePath, 3) | Out-Null
    }

    function Set-WallpaperRegistry {
        param($imagePath)
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value $imagePath
        rundll32.exe user32.dll,UpdatePerUserSystemParameters
    }

    function Set-WallpaperCOM {
        param($imagePath)
        $wsh = New-Object -ComObject WScript.Shell
        $wsh.RegWrite("HKCU\Control Panel\Desktop\Wallpaper", $imagePath)
        rundll32.exe user32.dll,UpdatePerUserSystemParameters
    }

    while ($true) {
        try {
            Set-WallpaperAPI -imagePath $imagePath
            Set-WallpaperRegistry -imagePath $imagePath
            Set-WallpaperCOM -imagePath $imagePath
        } catch {
            Write-Output "Failed to set wallpaper: $_"
        }
        Start-Sleep -Seconds 1
    }
} -ArgumentList $imagePath | Out-Null

Write-Host "Persistent wallpaper changer is now running in the background!"
Write-Host "To stop it, close PowerShell or manually kill the job."
