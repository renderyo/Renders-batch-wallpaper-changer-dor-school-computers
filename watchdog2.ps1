# watchdog2.ps1 - Monitor and kill chrome.exe after 20 seconds

$scriptPath = $MyInvocation.MyCommand.Path
$startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\watchdog2.bat"

# Ensure persistence in Startup
if (!(Test-Path $startupPath)) {
    "@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"
" | Out-File -Encoding ASCII $startupPath
}

# Infinite loop to monitor Chrome
while ($true) {
    $chrome = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
    if ($chrome) {
        Write-Host "Chrome detected. Waiting 20 seconds before terminating..."
        Start-Sleep -Seconds 20
        try {
            Get-Process -Name "chrome" -ErrorAction SilentlyContinue | Stop-Process -Force
            Write-Host "Chrome terminated."
        } catch {
            Write-Host "Failed to terminate Chrome: $_"
        }
    }
    Start-Sleep -Seconds 5
}
