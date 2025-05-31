# --- Minimalist Persistent Wallpaper Changer ---

# Function to set wallpaper using registry
function Set-Wallpaper {
    param($imagePath)

    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value $imagePath -ErrorAction SilentlyContinue
        rundll32.exe user32.dll,UpdatePerUserSystemParameters
    } catch {
        Write-Host "Failed to set wallpaper: $_"
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

    Write-Host "Starting persistent wallpaper changer. Press CTRL+C to stop."

    # Initial set
    Set-Wallpaper -imagePath $imagePath

    # Infinite loop to keep enforcing wallpaper
    while ($true) {
        Set-Wallpaper -imagePath $imagePath
        Start-Sleep -Seconds 1
    }
} catch {
    Write-Host "Fatal Error: $_"
    pause
}
