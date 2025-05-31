# -- Variables --
$WallpaperKey = "HKCU\Control Panel\Desktop"
$AutoRunKey = "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
$WallpaperStyle = "2"  # 0 = Stretched, 2 = Centered, 6 = Fit
$TileWallpaper = "0"
$WallpaperTranscodedPath = "$env:APPDATA\Microsoft\Windows\Themes\TranscodedWallpaper"
$SavedPathFile = "$env:APPDATA\savedWallpaperPath.txt"

# -- Read image path from saved file --
if (-not (Test-Path $SavedPathFile)) {
    Write-Host "Saved wallpaper path file not found: $SavedPathFile"
    exit 1
}

$ImagePath = Get-Content $SavedPathFile | Select-Object -First 1

# -- Check if file exists --
if (-not (Test-Path $ImagePath)) {
    Write-Host "Image path does not exist: $ImagePath"
    exit 1
}

# -- Function to set wallpaper via reg add --
function Set-Wallpaper {
    param ($ImageFilePath)

    reg add "$WallpaperKey" /v Wallpaper /t REG_SZ /d "$ImageFilePath" /f | Out-Null
    reg add "$WallpaperKey" /v WallpaperStyle /t REG_SZ /d "$WallpaperStyle" /f | Out-Null
    reg add "$WallpaperKey" /v TileWallpaper /t REG_SZ /d "$TileWallpaper" /f | Out-Null

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

# -- Function to add script to AutoRun --
function Add-ToAutoRun {
    $ScriptPath = $MyInvocation.MyCommand.Definition
    $AutoRunValue = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""
    $existing = (Get-ItemProperty -Path $AutoRunKey -Name "PersistentWallpaperChanger" -ErrorAction SilentlyContinue).PersistentWallpaperChanger

    if ($existing -ne $AutoRunValue) {
        reg add "$AutoRunKey" /v "PersistentWallpaperChanger" /t REG_SZ /d "$AutoRunValue" /f | Out-Null
        Write-Host "Script added to AutoRun."
    }
}

# -- Initial Setup --
Set-Wallpaper -ImageFilePath $ImagePath
Set-TranscodedWallpaper -ImageFilePath $ImagePath
Add-ToAutoRun

# -- Background monitoring loop --
Write-Host "Running in background. Monitoring wallpaper changes..."

while ($true) {
    if (-not (Test-Path $ImagePath)) {
        Write-Host "Image file no longer exists: $ImagePath"
        exit 1
    }

    $systemWallpaper = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper).Wallpaper

    if ($systemWallpaper -ne $ImagePath) {
        Write-Host "Detected wallpaper change. Resetting..."
        Set-Wallpaper -ImageFilePath $ImagePath
        Set-TranscodedWallpaper -ImageFilePath $ImagePath
    }

    Start-Sleep -Seconds 5
}
