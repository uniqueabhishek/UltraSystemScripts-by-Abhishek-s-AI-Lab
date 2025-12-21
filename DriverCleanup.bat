@ECHO OFF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Driver Cleanup Utility - Safe Driver Cleanup with Backup
:: Flow: List Old Drivers -> Backup -> Remove
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
TITLE Driver Cleanup Utility
color 0E

:: Check for admin privileges
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto :main ) else ( goto :getAdmin )

:getAdmin
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb RunAs"
    exit /b

:main
cls
ECHO ============================================================
ECHO           DRIVER STORE CLEANUP UTILITY
ECHO ============================================================
ECHO.
ECHO Target: C:\Windows\System32\DriverStore\FileRepository
ECHO.
ECHO Current DriverStore size:
powershell -Command "$size = (Get-ChildItem 'C:\Windows\System32\DriverStore\FileRepository' -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum; Write-Host ([math]::Round($size/1GB,2)) 'GB' -ForegroundColor Yellow"
ECHO.
ECHO ============================================================
ECHO WORKFLOW: List Old Drivers -^> Backup -^> Remove
ECHO ============================================================
ECHO.

:: ============================================================
:: STEP 1: LIST OLD/REMOVABLE DRIVERS
:: ============================================================
ECHO [STEP 1/3] LIST OLD/REMOVABLE DRIVERS
ECHO ============================================================
ECHO.
ECHO Scanning for third-party driver packages...
ECHO (Drivers in use by active devices will be SKIPPED during removal)
ECHO.
ECHO ------------------------------------------------------------
pnputil /enum-drivers
ECHO ------------------------------------------------------------
ECHO.
ECHO TIP: Look for drivers with OLD dates or MULTIPLE versions
ECHO      of the same device (e.g., multiple NVIDIA entries)
ECHO.
set /p continueFlow=Do you want to continue with backup and cleanup? [Y/N]:
if /I "%continueFlow%" NEQ "Y" goto cancelled

cls

:: ============================================================
:: STEP 2: BACKUP ALL DRIVERS
:: ============================================================
ECHO [STEP 2/3] BACKUP ALL DRIVERS
ECHO ============================================================
set "BACKUP_DIR=%USERPROFILE%\Desktop\DriverBackup_%date:~-4,4%%date:~-10,2%%date:~-7,2%"
ECHO.
ECHO Backup will be saved to:
ECHO %BACKUP_DIR%
ECHO.
set /p doBackup=Do you want to backup all drivers first? (Recommended) [Y/N]:
if /I "%doBackup%" NEQ "Y" goto skipBackup

ECHO.
ECHO Backing up all drivers... This may take a few minutes.
ECHO.
mkdir "%BACKUP_DIR%" 2>nul
pnputil /export-driver * "%BACKUP_DIR%"
ECHO.
ECHO [SUCCESS] Drivers backed up to: %BACKUP_DIR%
ECHO.
PAUSE

:skipBackup
cls

:: ============================================================
:: STEP 3: REMOVE OLD DRIVERS
:: ============================================================
ECHO [STEP 3/3] REMOVE OLD DRIVERS
ECHO ============================================================
ECHO.
ECHO This will attempt to remove all old/unused drivers.
ECHO.
ECHO SAFETY FEATURES:
ECHO   - Drivers CURRENTLY IN USE will NOT be removed
ECHO   - Windows built-in drivers will NOT be removed
ECHO   - Only third-party staged drivers are affected
ECHO.
set /p doRemove=Do you want to remove old drivers? [Y/N]:
if /I "%doRemove%" NEQ "Y" goto cancelled

ECHO.
ECHO Removing old drivers... Please wait.
ECHO.

:: Use PowerShell to find and remove old drivers
powershell -Command "& {
    $drivers = pnputil /enum-drivers
    $oemPattern = 'Published Name\s*:\s*(oem\d+\.inf)'
    $matches = [regex]::Matches($drivers, $oemPattern)

    $removed = 0
    $skipped = 0
    $total = $matches.Count
    $current = 0

    foreach ($match in $matches) {
        $current++
        $oem = $match.Groups[1].Value
        Write-Host \"[$current/$total] Trying: $oem... \" -NoNewline

        $result = pnputil /delete-driver $oem 2>&1 | Out-String

        if ($result -match 'successfully') {
            Write-Host 'REMOVED' -ForegroundColor Green
            $removed++
        } else {
            Write-Host 'SKIPPED (in use)' -ForegroundColor Yellow
            $skipped++
        }
    }

    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host '                    SUMMARY' -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host \"  Total drivers scanned: $total\"
    Write-Host \"  Removed: $removed\" -ForegroundColor Green
    Write-Host \"  Skipped (in use): $skipped\" -ForegroundColor Yellow
    Write-Host '============================================================' -ForegroundColor Cyan
}"

ECHO.
ECHO New DriverStore size:
powershell -Command "$size = (Get-ChildItem 'C:\Windows\System32\DriverStore\FileRepository' -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum; Write-Host ([math]::Round($size/1GB,2)) 'GB' -ForegroundColor Green"
ECHO.
goto done

:cancelled
ECHO.
ECHO Operation cancelled by user.
ECHO.

:done
ECHO ============================================================
ECHO                    CLEANUP COMPLETE
ECHO ============================================================
ECHO.
if defined BACKUP_DIR (
    if exist "%BACKUP_DIR%" (
        ECHO Your driver backup is at: %BACKUP_DIR%
        ECHO.
    )
)
ECHO Press any key to exit...
PAUSE >nul
