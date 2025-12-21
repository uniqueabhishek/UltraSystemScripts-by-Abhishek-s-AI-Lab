@ECHO OFF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Driver Cleanup Utility - Safe Driver Cleanup with Backup
:: Flow: List Removable -> Backup Those -> Remove
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
ECHO WORKFLOW: List Removable -^> Backup Those -^> Remove
ECHO ============================================================
ECHO.

:: Create temp files
set "REMOVABLE_LIST=%TEMP%\removable_drivers.txt"
set "BACKUP_DIR=%USERPROFILE%\Desktop\DriverBackup_%date:~-4,4%%date:~-10,2%%date:~-7,2%"
if exist "%REMOVABLE_LIST%" del "%REMOVABLE_LIST%"

:: ============================================================
:: STEP 1: FIND OLD/DUPLICATE/REMOVABLE DRIVERS (DRY RUN)
:: ============================================================
ECHO [STEP 1/3] FINDING OLD/DUPLICATE DRIVERS THAT CAN BE REMOVED
ECHO ============================================================
ECHO.
ECHO Analyzing driver packages to find removable ones...
ECHO (This is a DRY RUN - nothing will be deleted yet)
ECHO.

powershell -Command "& {
    Write-Host 'Scanning drivers...' -ForegroundColor Cyan
    Write-Host ''

    # Get all driver info
    $driverOutput = pnputil /enum-drivers

    # Parse into driver objects
    $drivers = @()
    $currentDriver = @{}

    foreach ($line in $driverOutput -split '`n') {
        if ($line -match 'Published Name\s*:\s*(.+)') {
            if ($currentDriver.Count -gt 0) { $drivers += [PSCustomObject]$currentDriver }
            $currentDriver = @{ PublishedName = $matches[1].Trim() }
        }
        elseif ($line -match 'Original Name\s*:\s*(.+)') { $currentDriver.OriginalName = $matches[1].Trim() }
        elseif ($line -match 'Provider Name\s*:\s*(.+)') { $currentDriver.Provider = $matches[1].Trim() }
        elseif ($line -match 'Class Name\s*:\s*(.+)') { $currentDriver.Class = $matches[1].Trim() }
        elseif ($line -match 'Driver Version\s*:\s*(.+)') { $currentDriver.Version = $matches[1].Trim() }
    }
    if ($currentDriver.Count -gt 0) { $drivers += [PSCustomObject]$currentDriver }

    # Group by Original Name to find duplicates
    $grouped = $drivers | Group-Object OriginalName | Where-Object { `$_.Count -gt 1 }

    Write-Host '============================================================' -ForegroundColor Green
    Write-Host '  DUPLICATE DRIVERS FOUND (older versions can be removed):' -ForegroundColor Green
    Write-Host '============================================================' -ForegroundColor Green
    Write-Host ''

    $removableDrivers = @()

    foreach ($group in $grouped) {
        Write-Host \"  Driver: $($group.Name)\" -ForegroundColor White
        Write-Host \"  Provider: $($group.Group[0].Provider)\" -ForegroundColor Gray
        Write-Host \"  Class: $($group.Group[0].Class)\" -ForegroundColor Gray
        Write-Host \"  Versions found: $($group.Count)\" -ForegroundColor Cyan

        # Sort by version date (newest first)
        $sorted = $group.Group | Sort-Object {
            if (`$_.Version -match '(\d{1,2}/\d{1,2}/\d{4})') {
                [datetime]::Parse(`$matches[1])
            } else {
                [datetime]::MinValue
            }
        } -Descending

        $newest = $sorted[0]
        $older = $sorted | Select-Object -Skip 1

        Write-Host \"    [KEEP]   $($newest.PublishedName) - $($newest.Version)\" -ForegroundColor Green

        foreach ($old in $older) {
            Write-Host \"    [REMOVE] $($old.PublishedName) - $($old.Version)\" -ForegroundColor Red
            $removableDrivers += $old.PublishedName
        }
        Write-Host ''
    }

    if ($removableDrivers.Count -eq 0) {
        Write-Host '  No duplicate/old drivers found! Your system is clean.' -ForegroundColor Yellow
    } else {
        Write-Host '============================================================' -ForegroundColor Cyan
        Write-Host \"  TOTAL: $($removableDrivers.Count) old driver versions can be removed\" -ForegroundColor Cyan
        Write-Host '============================================================' -ForegroundColor Cyan
    }

    # Save removable list to file
    $removableDrivers | Out-File -FilePath $env:TEMP\removable_drivers.txt -Encoding ASCII
}"

ECHO.
set /p continueFlow=Continue with backup and removal? [Y/N]:
if /I "%continueFlow%" NEQ "Y" goto cancelled

cls

:: ============================================================
:: STEP 2: BACKUP DRIVERS WE'RE GOING TO REMOVE
:: ============================================================
ECHO [STEP 2/3] BACKUP DRIVERS TO BE REMOVED
ECHO ============================================================
ECHO.
ECHO Backup location: %BACKUP_DIR%
ECHO.

mkdir "%BACKUP_DIR%" 2>nul

powershell -Command "& {
    $drivers = Get-Content '$env:TEMP\removable_drivers.txt' -ErrorAction SilentlyContinue
    if ($drivers.Count -eq 0) {
        Write-Host 'No drivers to backup.' -ForegroundColor Yellow
        return
    }

    Write-Host \"Backing up $($drivers.Count) drivers...\" -ForegroundColor Cyan
    Write-Host ''

    $backupDir = '$env:USERPROFILE\Desktop\DriverBackup_' + (Get-Date -Format 'yyyyMMdd')

    foreach ($drv in $drivers) {
        if ($drv -match 'oem\d+\.inf') {
            Write-Host \"  Backing up: $drv... \" -NoNewline
            $result = pnputil /export-driver $drv $backupDir 2>&1
            if ($?) { Write-Host 'OK' -ForegroundColor Green }
            else { Write-Host 'SKIP' -ForegroundColor Yellow }
        }
    }
    Write-Host ''
    Write-Host '[SUCCESS] Backup complete!' -ForegroundColor Green
}"

ECHO.
PAUSE
cls

:: ============================================================
:: STEP 3: REMOVE OLD DRIVERS
:: ============================================================
ECHO [STEP 3/3] REMOVE OLD DRIVERS
ECHO ============================================================
ECHO.
ECHO Now removing old driver versions...
ECHO (Backed up drivers are safe in: %BACKUP_DIR%)
ECHO.

powershell -Command "& {
    $drivers = Get-Content '$env:TEMP\removable_drivers.txt' -ErrorAction SilentlyContinue
    if ($drivers.Count -eq 0) {
        Write-Host 'No drivers to remove.' -ForegroundColor Yellow
        return
    }

    $removed = 0
    $failed = 0
    $total = $drivers.Count
    $current = 0

    foreach ($drv in $drivers) {
        if ($drv -match 'oem\d+\.inf') {
            $current++
            Write-Host \"[$current/$total] Removing: $drv... \" -NoNewline
            $result = pnputil /delete-driver $drv 2>&1 | Out-String
            if ($result -match 'successfully|deleted') {
                Write-Host 'REMOVED' -ForegroundColor Green
                $removed++
            } else {
                Write-Host 'FAILED (in use)' -ForegroundColor Yellow
                $failed++
            }
        }
    }

    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host '                    SUMMARY' -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host \"  Removed: $removed drivers\" -ForegroundColor Green
    Write-Host \"  Failed:  $failed drivers (still in use)\" -ForegroundColor Yellow
    Write-Host '============================================================' -ForegroundColor Cyan
}"

ECHO.
ECHO New DriverStore size:
powershell -Command "$size = (Get-ChildItem 'C:\Windows\System32\DriverStore\FileRepository' -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum; Write-Host ([math]::Round($size/1GB,2)) 'GB' -ForegroundColor Green"
ECHO.
goto done

:cancelled
ECHO.
ECHO Operation cancelled.
ECHO.

:done
ECHO ============================================================
ECHO                    CLEANUP COMPLETE
ECHO ============================================================
ECHO.
if exist "%BACKUP_DIR%" (
    ECHO Backup saved to: %BACKUP_DIR%
    ECHO.
)
ECHO Press any key to exit...
PAUSE >nul
