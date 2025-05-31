# File: Set-WallpaperLoop.ps1

# Configuration
$configFile = "$env:APPDATA\wallpaper_config.txt"
$scriptPath = $MyInvocation.MyCommand.Path

# Function to set wallpaper using SystemParametersInfo
function Set-Wallpaper-SPI($path) {
    Add-Type @"
    using System.Runtime.InteropServices;
    public class Wallpaper {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    }
"@
    $SPI_SETDESKWALLPAPER = 20
    $SPIF_UPDATEINIFILE = 1
    $SPIF_SENDCHANGE = 2
    [Wallpaper]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $path, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE) | Out-Null
}

# Function to set wallpaper via Registry + RUNDLL32
function Set-Wallpaper-Registry($path) {
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\' -Name Wallpaper -Value $path
    rundll32.exe user32.dll, UpdatePerUserSystemParameters
}

# Function to set wallpaper using multiple methods
function Set-Wallpaper($path) {
    Set-Wallpaper-SPI $path
    Start-Sleep -Milliseconds 200
    Set-Wallpaper-Registry $path
}

# Function to add this script to autorun
function Add-To-Autorun {
    $autorunKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    $name = 'WallpaperChanger'
    $command = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
    Set-ItemProperty -Path $autorunKey -Name $name -Value $command
}

# Ask for path if no config exists
if (!(Test-Path $configFile)) {
    $imagePath = Read-Host "Enter full image file path for wallpaper"
    if (!(Test-Path $imagePath)) {
        Write-Host "File does not exist. Exiting..."
        exit
    }
    $imagePath | Out-File -Encoding ASCII $configFile
    Add-To-Autorun
} else {
    $imagePath = Get-Content $configFile
}

# Background loop
Start-Job {
    param($img)

    function Set-Wallpaper-SPI($path) {
        Add-Type @"
        using System.Runtime.InteropServices;
        public class Wallpaper {
            [DllImport("user32.dll", SetLastError = true)]
            public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
        }
"@
        $SPI_SETDESKWALLPAPER = 20
        $SPIF_UPDATEINIFILE = 1
        $SPIF_SENDCHANGE = 2
        [Wallpaper]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $path, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE) | Out-Null
    }

    function Set-Wallpaper-Registry($path) {
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\' -Name Wallpaper -Value $path
        rundll32.exe user32.dll, UpdatePerUserSystemParameters
    }

    function Set-Wallpaper($path) {
        Set-Wallpaper-SPI $path
        Start-Sleep -Milliseconds 200
        Set-Wallpaper-Registry $path
    }

    while ($true) {
        if (Test-Path $img) {
            Set-Wallpaper $img
        }
        Start-Sleep -Seconds 1
    }
} -ArgumentList $imagePath | Out-Null

# Exit foreground script
exit
