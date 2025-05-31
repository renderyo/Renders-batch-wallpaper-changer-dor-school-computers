# -- Variables --
$ImagePath = Read-Host "Enter the full path to the image file"
$WallpaperKey = "HKCU:\Control Panel\Desktop"
$AutoRunKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$WallpaperStyle = 2 # This is for centered wallpaper (you can change it to 0 for stretched or 6 for fit)
$WallpaperTranscodedPath = "$env:APPDATA\Microsoft\Windows\Themes\TranscodedWallpaper"

# -- Check if file exists --
if (-not (Test-Path $ImagePath)) {
    Write-Host "Image path does not exist. Exiting..."
    exit
}

# -- Function to set wallpaper through registry --
Function Set-Wallpaper {
    param ($ImageFilePath)
    Set-ItemProperty -Path $WallpaperKey -Name "Wallpaper" -Value $ImageFilePath
    Set-ItemProperty -Path $WallpaperKey -Name "WallpaperStyle" -Value $WallpaperStyle
    Set-ItemProperty -Path $WallpaperKey -Name "TileWallpaper" -Value 0
}

# -- Function to change the transcoded wallpaper --
Function Set-TranscodedWallpaper {
    param ($ImageFilePath)
    Copy-Item -Path $ImageFilePath -Destination $WallpaperTranscodedPath -Force
}

# -- Function to reset Explorer --
Function Reset-Explorer {
    Stop-Process -Name explorer -Force
    Start-Process explorer.exe
}

# -- Set wallpaper using the registry method --
Set-Wallpaper -ImageFilePath $ImagePath

# -- Set transcoded wallpaper --
Set-TranscodedWallpaper -ImageFilePath $ImagePath

# -- Continuous loop to keep changing wallpaper --
Write-Host "Running in background, changing wallpaper every 1 second to prevent any changes..."
While ($true) {
    # Reset explorer to re-apply the wallpaper changes
    Reset-Explorer

    # Re-apply regular wallpaper method
    Set-Wallpaper -ImageFilePath $ImagePath

    # Re-apply transcoded wallpaper method
    Set-TranscodedWallpaper -ImageFilePath $ImagePath

    # Wait for 1 second before repeating the process
    Start-Sleep -Seconds 1
}

# -- Add script to AutoRun so it runs at startup --
Function Add-ToAutoRun {
    $ScriptPath = $MyInvocation.MyCommand.Path
    Set-ItemProperty -Path $AutoRunKey -Name "PersistentWallpaperChanger" -Value $ScriptPath
}

# Call the function to add to AutoRun
Add-ToAutoRun
Write-Host "Script added to AutoRun. Will run automatically on system startup."

# -- End of Script --
