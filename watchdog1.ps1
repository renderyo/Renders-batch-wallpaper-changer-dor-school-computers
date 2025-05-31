# -- Variables --
$ImagePath = Read-Host "Enter the full path to the image file"
$WallpaperKey = "HKCU:\Control Panel\Desktop"
$AutoRunKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$WallpaperStyle = 2 # 0 = Stretched, 2 = Centered, 6 = Fit
$WallpaperTranscodedPath = "$env:APPDATA\Microsoft\Windows\Themes\TranscodedWallpaper"

# -- Check if file exists --
if (-not (Test-Path $ImagePath)) {
    Write-Host "Image path does not exist. Exiting..."
    exit 1
}

# -- Function to set wallpaper via registry --
function Set-Wallpaper {
    param ($ImageFilePath)

    Set-ItemProperty -Path $WallpaperKey -Name "Wallpaper" -Value $ImageFilePath
    Set-ItemProperty -Path $WallpaperKey -Name "WallpaperStyle" -Value $WallpaperStyle
    Set-ItemProperty -Path $WallpaperKey -Name "TileWallpaper" -Value 0

    # Notify system about wallpaper change
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class NativeMethods {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
}
"@

    [UIntPtr]$result = 0
    [NativeMethods]::SendMessageTimeout([IntPtr]0xFFFF, 0x1A, [UIntPtr]0, "Environment", 2, 5000, [ref]$result)
}

# -- Function to set TranscodedWallpaper file --
function Set-TranscodedWallpaper {
    param ($ImageFilePath)
    Copy-Item -Path $ImageFilePath -Destination $WallpaperTranscodedPath -Force -ErrorAction SilentlyContinue
}

# -- Function to add this script to AutoRun --
function Add-ToAutoRun {
    $ScriptPath = $MyInvocation.MyCommand.Definition
    $existing = Get-ItemProperty -Path $AutoRunKey -Name "PersistentWallpaperChanger" -ErrorAction SilentlyContinue
    if (-not $existing) {
        Set-ItemProperty -Path $AutoRunKey -Name "PersistentWallpaperChanger" -Value "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""
        Write-Host "Script added to AutoRun."
    }
}

# -- Initial Setup --
Set-Wallpaper -ImageFilePath $ImagePath
Set-TranscodedWallpaper -ImageFilePath $ImagePath
Add-ToAutoRun

# -- Background monitoring loop --
Write-Host "Running in background. Monitoring wallpaper changes..."

# Store current state
$currentWallpaper = (Get-ItemProperty -Path $WallpaperKey -Name Wallpaper).Wallpaper

while ($true) {
    if (-not (Test-Path $ImagePath)) {
        Write-Host "Image file no longer exists. Exiting..."
        exit 1
    }

    $systemWallpaper = (Get-ItemProperty -Path $WallpaperKey -Name Wallpaper).Wallpaper
    if ($systemWallpaper -ne $ImagePath) {
        Write-Host "Detected wallpaper change. Resetting..."
        Set-Wallpaper -ImageFilePath $ImagePath
        Set-TranscodedWallpaper -ImageFilePath $ImagePath
        $currentWallpaper = $ImagePath
    }
    Start-Sleep -Seconds 5
}
