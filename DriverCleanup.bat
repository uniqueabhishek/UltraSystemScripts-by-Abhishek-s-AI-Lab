@ECHO OFF
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Driver Cleanup & Restore Utility v2.0
:: Features: Cleanup, Backup, and Professional Restore
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
TITLE Driver Cleanup ^& Restore Utility
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
ECHO      DRIVER CLEANUP ^& RESTORE UTILITY v2.0
ECHO ============================================================
ECHO.
ECHO Current DriverStore size:
powershell -NoProfile -Command "$size = (Get-ChildItem 'C:\Windows\System32\DriverStore\FileRepository' -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum; Write-Host ([math]::Round($size/1GB,2)) 'GB' -ForegroundColor Yellow"
ECHO.
ECHO ============================================================
ECHO                    MAIN MENU
ECHO ============================================================
ECHO.
ECHO   [1] CLEANUP - Remove old/unused drivers
ECHO   [2] BACKUP  - Export all current drivers
ECHO   [3] RESTORE - Reinstall drivers from backup
ECHO   [4] EXIT
ECHO.
ECHO ============================================================
set /p choice=Select option (1-4):

if "%choice%"=="1" goto cleanup
if "%choice%"=="2" goto backupOnly
if "%choice%"=="3" goto restore
if "%choice%"=="4" exit /b
goto main

:: ============================================================
:: CLEANUP FLOW
:: ============================================================
:cleanup
cls
ECHO ============================================================
ECHO              DRIVER CLEANUP
ECHO ============================================================
ECHO.
ECHO [STEP 1/3] LISTING ALL THIRD-PARTY DRIVERS
ECHO ------------------------------------------------------------
pnputil /enum-drivers
ECHO ------------------------------------------------------------
ECHO.
set /p continueCleanup=Continue with backup and cleanup? [Y/N]:
if /I "%continueCleanup%" NEQ "Y" goto main

cls
ECHO [STEP 2/3] BACKUP DRIVERS
ECHO ============================================================
set "BACKUP_DIR=%USERPROFILE%\Desktop\DriverBackup_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%"
set "BACKUP_DIR=%BACKUP_DIR: =0%"
ECHO Backup location: %BACKUP_DIR%
ECHO.
set /p doBackup=Backup all drivers first? (Recommended) [Y/N]:
if /I "%doBackup%" NEQ "Y" goto skipCleanupBackup

mkdir "%BACKUP_DIR%" 2>nul
ECHO Backing up drivers...
pnputil /export-driver * "%BACKUP_DIR%"
ECHO.
ECHO [SUCCESS] Backup complete!
ECHO.
:: Save backup location for restore feature
echo %BACKUP_DIR%>> "%USERPROFILE%\DriverBackups.txt"
PAUSE

:skipCleanupBackup
cls
ECHO [STEP 3/3] REMOVE OLD DRIVERS
ECHO ============================================================
ECHO.
set /p doRemove=Proceed with driver removal? [Y/N]:
if /I "%doRemove%" NEQ "Y" goto main

ECHO.
ECHO Removing old drivers...
ECHO.

for /f "tokens=3" %%a in ('pnputil /enum-drivers ^| findstr /i "oem"') do (
    ECHO Trying: %%a
    pnputil /delete-driver %%a 2>nul
)

ECHO.
ECHO ============================================================
ECHO New DriverStore size:
powershell -NoProfile -Command "$size = (Get-ChildItem 'C:\Windows\System32\DriverStore\FileRepository' -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum; Write-Host ([math]::Round($size/1GB,2)) 'GB' -ForegroundColor Green"
ECHO ============================================================
PAUSE
goto main

:: ============================================================
:: BACKUP ONLY
:: ============================================================
:backupOnly
cls
ECHO ============================================================
ECHO              BACKUP ALL DRIVERS
ECHO ============================================================
ECHO.
set "BACKUP_DIR=%USERPROFILE%\Desktop\DriverBackup_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%"
set "BACKUP_DIR=%BACKUP_DIR: =0%"
ECHO Backup will be saved to:
ECHO %BACKUP_DIR%
ECHO.
set /p confirmBackup=Proceed with backup? [Y/N]:
if /I "%confirmBackup%" NEQ "Y" goto main

mkdir "%BACKUP_DIR%" 2>nul
ECHO.
ECHO Backing up all drivers... This may take a few minutes.
ECHO.
pnputil /export-driver * "%BACKUP_DIR%"
ECHO.
:: Save backup location for restore feature
echo %BACKUP_DIR%>> "%USERPROFILE%\DriverBackups.txt"
ECHO ============================================================
ECHO [SUCCESS] Drivers backed up to:
ECHO %BACKUP_DIR%
ECHO ============================================================
PAUSE
goto main

:: ============================================================
:: RESTORE FEATURE
:: ============================================================
:restore
cls
ECHO ============================================================
ECHO              DRIVER RESTORE CENTER
ECHO ============================================================
ECHO.
ECHO This will reinstall drivers from a backup folder.
ECHO.
ECHO ============================================================
ECHO   RESTORE OPTIONS:
ECHO ============================================================
ECHO.
ECHO   [1] Browse for backup folder (manual)
ECHO   [2] Select from recent backups
ECHO   [3] Restore ALL drivers from folder
ECHO   [4] Restore SPECIFIC driver (by name)
ECHO   [5] Back to main menu
ECHO.
set /p restoreChoice=Select option (1-5):

if "%restoreChoice%"=="1" goto restoreBrowse
if "%restoreChoice%"=="2" goto restoreRecent
if "%restoreChoice%"=="3" goto restoreAll
if "%restoreChoice%"=="4" goto restoreSpecific
if "%restoreChoice%"=="5" goto main
goto restore

:restoreBrowse
cls
ECHO ============================================================
ECHO   BROWSE FOR BACKUP FOLDER
ECHO ============================================================
ECHO.
ECHO Enter the full path to your driver backup folder:
ECHO (e.g., C:\Users\YourName\Desktop\DriverBackup_20251221)
ECHO.
set /p RESTORE_PATH=Path:

if not exist "%RESTORE_PATH%" (
    ECHO.
    ECHO [ERROR] Path does not exist: %RESTORE_PATH%
    PAUSE
    goto restore
)

goto restoreFromPath

:restoreRecent
cls
ECHO ============================================================
ECHO   RECENT BACKUPS
ECHO ============================================================
ECHO.
ECHO Searching for backup folders on Desktop...
ECHO.

set count=0
for /d %%d in ("%USERPROFILE%\Desktop\DriverBackup_*") do (
    set /a count+=1
    ECHO   [!count!] %%~nxd
    set "backup!count!=%%d"
)

if %count%==0 (
    ECHO No backup folders found on Desktop.
    ECHO.
    ECHO TIP: Backup folders should be named DriverBackup_YYYYMMDD
    PAUSE
    goto restore
)

ECHO.
set /p backupNum=Select backup number (or 0 to cancel):

if "%backupNum%"=="0" goto restore

:: Use delayed expansion to get the selected backup
setlocal enabledelayedexpansion
set "RESTORE_PATH=!backup%backupNum%!"
endlocal & set "RESTORE_PATH=%RESTORE_PATH%"

if not defined RESTORE_PATH (
    ECHO Invalid selection.
    PAUSE
    goto restore
)

goto restoreFromPath

:restoreAll
cls
ECHO ============================================================
ECHO   RESTORE ALL DRIVERS FROM FOLDER
ECHO ============================================================
ECHO.
ECHO Enter the full path to your driver backup folder:
set /p RESTORE_PATH=Path:

if not exist "%RESTORE_PATH%" (
    ECHO [ERROR] Path does not exist.
    PAUSE
    goto restore
)

:restoreFromPath
cls
ECHO ============================================================
ECHO   RESTORE DRIVERS
ECHO ============================================================
ECHO.
ECHO Source: %RESTORE_PATH%
ECHO.
ECHO Scanning for drivers in backup...
ECHO.

:: Count .inf files
set infCount=0
for /r "%RESTORE_PATH%" %%f in (*.inf) do set /a infCount+=1

ECHO Found %infCount% driver packages (.inf files)
ECHO.
ECHO ============================================================
ECHO   RESTORE OPTIONS:
ECHO ============================================================
ECHO.
ECHO   [1] Restore ALL drivers (add to driver store)
ECHO   [2] Restore and INSTALL all drivers (force install)
ECHO   [3] List drivers first, then choose
ECHO   [4] Cancel
ECHO.
set /p restoreMode=Select option (1-4):

if "%restoreMode%"=="1" goto doRestoreAdd
if "%restoreMode%"=="2" goto doRestoreInstall
if "%restoreMode%"=="3" goto listThenRestore
if "%restoreMode%"=="4" goto restore
goto restoreFromPath

:doRestoreAdd
cls
ECHO ============================================================
ECHO   ADDING DRIVERS TO STORE
ECHO ============================================================
ECHO.
ECHO This adds drivers to the Windows Driver Store.
ECHO Windows will use them when matching devices are connected.
ECHO.

pnputil /add-driver "%RESTORE_PATH%\*.inf" /subdirs

ECHO.
ECHO ============================================================
ECHO [SUCCESS] Drivers added to Windows Driver Store!
ECHO ============================================================
PAUSE
goto restore

:doRestoreInstall
cls
ECHO ============================================================
ECHO   INSTALLING DRIVERS (FORCE)
ECHO ============================================================
ECHO.
ECHO WARNING: This will force-install ALL drivers from the backup.
ECHO Only use this if you're restoring after a system issue.
ECHO.
set /p confirmForce=Are you sure? [Y/N]:
if /I "%confirmForce%" NEQ "Y" goto restore

ECHO.
ECHO Installing drivers...
ECHO.

pnputil /add-driver "%RESTORE_PATH%\*.inf" /subdirs /install

ECHO.
ECHO ============================================================
ECHO [SUCCESS] Drivers installed!
ECHO ============================================================
ECHO.
ECHO NOTE: A reboot may be required for some drivers.
set /p rebootNow=Reboot now? [Y/N]:
if /I "%rebootNow%"=="Y" shutdown /r /t 10 /c "Rebooting to complete driver installation..."
PAUSE
goto restore

:listThenRestore
cls
ECHO ============================================================
ECHO   DRIVERS IN BACKUP
ECHO ============================================================
ECHO.

set drvCount=0
for /r "%RESTORE_PATH%" %%f in (*.inf) do (
    set /a drvCount+=1
    ECHO   [!drvCount!] %%~nxf
)

ECHO.
ECHO ============================================================
ECHO Total: %drvCount% driver packages
ECHO ============================================================
ECHO.
ECHO   [A] Add ALL to driver store
ECHO   [I] Install ALL (force)
ECHO   [S] Select specific driver by name
ECHO   [C] Cancel
ECHO.
set /p listChoice=Choice:

if /I "%listChoice%"=="A" goto doRestoreAdd
if /I "%listChoice%"=="I" goto doRestoreInstall
if /I "%listChoice%"=="S" goto restoreSpecific
if /I "%listChoice%"=="C" goto restore
goto listThenRestore

:restoreSpecific
cls
ECHO ============================================================
ECHO   RESTORE SPECIFIC DRIVER
ECHO ============================================================
ECHO.
if not defined RESTORE_PATH (
    ECHO Enter the backup folder path:
    set /p RESTORE_PATH=Path:
)
ECHO.
ECHO Enter the driver filename (e.g., nvhda.inf):
ECHO Or enter part of the name to search:
ECHO.
set /p driverName=Driver name:

ECHO.
ECHO Searching for matching drivers...
ECHO.

set found=0
for /r "%RESTORE_PATH%" %%f in (*%driverName%*) do (
    if "%%~xf"==".inf" (
        set /a found+=1
        ECHO   Found: %%~nxf
        ECHO   Path:  %%f
        ECHO.
        set "lastFound=%%f"
    )
)

if %found%==0 (
    ECHO No matching drivers found.
    PAUSE
    goto restore
)

if %found%==1 (
    ECHO.
    set /p installThis=Install this driver? [Y/N]:
    if /I "!installThis!"=="Y" (
        pnputil /add-driver "%lastFound%" /install
        ECHO.
        ECHO [SUCCESS] Driver installed!
    )
) else (
    ECHO.
    ECHO Multiple matches found. Enter exact filename:
    set /p exactName=Filename:
    for /r "%RESTORE_PATH%" %%f in (%exactName%) do (
        pnputil /add-driver "%%f" /install
        ECHO [SUCCESS] Driver installed!
    )
)

PAUSE
goto restore
