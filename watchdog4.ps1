# Infinite loop to monitor for chrome.exe
while ($true) {
    $chrome = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
    if ($chrome) {
        Start-Sleep -Seconds 20
        # Check again if chrome is still running
        $chrome = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
        if ($chrome) {
            Stop-Process -Name "chrome" -Force
        }
    }
    Start-Sleep -Seconds 5
}
