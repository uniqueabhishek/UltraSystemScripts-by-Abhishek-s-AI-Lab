::::::::::::::::::::::::::::::::::::::::::::
:: Automatically check & get admin rights ::
::::::::::::::::::::::::::::::::::::::::::::
@ECHO OFF
color f0
ECHO =============================
ECHO Running Admin shell
ECHO =============================

:checkPrivileges
	NET FILE 1>NUL 2>NUL
	if '%errorlevel%' == '0' ( goto gotPrivileges ) else ( goto getPrivileges )
:getPrivileges
	:: Not elevated, so re-run with elevation
	powershell -Command "Start-Process cmd -ArgumentList '/c %~s0 %*' -Verb RunAs"
	exit /b

:gotPrivileges
::::::::::::::::::::::::::::
:STARTINTRO
::::::::::::::::::::::::::::
::cls
	@ECHO OFF
color
	TITLE Welcome to My Sweeper script!
	ECHO    Automagic disk cleanup script!
	ECHO	Purpose of this batch file is to recover as much "safe" free space from your windows system drive
	ECHO	in order to gain back free space that Windows, other programs, and users themselves have consumed.
	ECHO Version 21-12-2025 v2.0 - Added 12 new cleanup targets
:StartofScript
	echo ********************************************
	ECHO 	Your Current free space of hard drive:
		fsutil volume diskfree c:
	echo ********************************************
	TIMEOUT 10

:OutdatedHibernateFile
	ECHO Disabling hibernation and deleting the hibernation file
	ECHO This also disables the Windows Fast Startup and forever "Up Time"
	powercfg -h off >nul 2>&1

:BadPrintJobs
	ECHO Deleting unreleased erroneous print jobs
	NET STOP /Y Spooler >nul 2>&1
	DEL /S /Q /F %systemdrive%\windows\system32\spool\printers\*.* >nul 2>&1
	net start spooler >nul 2>&1

:fontcache
	net stop fontcache >nul 2>&1
	DEL /S /Q /F %systemdrive%\Windows\ServiceProfiles\LocalService\AppData\Local\*.* /s /q >nul 2>&1
	net start fontcache >nul 2>&1

:WindowsUpdatesCleanup
	echo STOPPING WINDOWS UPDATE SERVICES
	net stop bits >nul 2>&1
	net stop wuauserv >nul 2>&1
	net stop appidsvc >nul 2>&1
	net stop cryptsvc >nul 2>&1
	DEL /S /Q /F “%ALLUSERSPROFILE%\Application Data\Microsoft\Network\Downloader\”	>nul 2>&1
	rmdir /S /Q "%systemroot%\SoftwareDistribution" >nul 2>&1
	rmdir /S /Q "%systemroot%\system32\catroot2" >nul 2>&1
::commented out the below line because rolling back updates is needed, and it's usually only 1-2Gb.  If you don't care about rolling back updates (DANGER Will Robinson), remove the :: in front of the next line.
	::rmdir /S /Q "%systemroot%\Installer\$PatchCache$"
	DEL /S /Q /F "%systemroot%\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Logs\*.*" >nul 2>&1
	echo STARTING WINDOWS UPDATE SERVICES AFTER CLEANUP
	net start bits >nul 2>&1
	net start wuauserv >nul 2>&1
	net start appidsvc >nul 2>&1
	net start cryptsvc >nul 2>&1

:WindowsTempFilesCleanup
	ECHO Deleting all System temporary files, this may take a while...
	@ECHO OFF
	DEL /S /Q /F "%TMP%\" >nul 2>&1
	DEL /S /Q /F "%TEMP%\" >nul 2>&1
	DEL /S /Q /F "%WINDIR%\Temp\" >nul 2>&1
	DEL /S /Q /F "%WINDIR%\Prefetch\" >nul 2>&1
	DEL /S /Q /F "%WINDIR%\Logs\CBS\" >nul 2>&1
	DEL /S /Q /F "%WINDIR%\Logs\DPX\*.log" >nul 2>&1
	DEL /S /Q /F "%WINDIR%\Logs\DISM\*.log" >nul 2>&1
	DEL /S /Q /F "%WINDIR%\Logs\MeasuredBoot\*.log" >nul 2>&1
	DEL /S /Q /F "%WINDIR%\SoftwareDistribution\DataStore\Logs\" >nul 2>&1
	DEL /S /Q /F "%WINDIR%\runSW.log" >nul 2>&1
	DEL /S /Q /F "%WINDIR%\system32\sru\*.log" >nul 2>&1
	DEL /S /Q /F "%WINDIR%\system32\sru\*.dat" >nul 2>&1
	DEL /S /Q /F "%WINDIR%\LiveKernelReports\*.dmp" >nul 2>&1
	DEL /S /Q /F "%WINDIR%\appcompat\backuptest\" >nul 2>&1

:UserProfileCleanup
	ECHO Cleaning up user profiles
	setlocal enableextensions
	For /d %%u in (c:\users\*) do (
		DEL /S /Q /F "%%u\Local Settings\Temp\*.*" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Local\Temp\*.*" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Local\Microsoft\Explorer\ThumbCacheToDelete\*.*" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Local\CrashDumps\*.*" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\LocalLow\Microsoft\CryptnetUrlCache\Content\*.*" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Roaming\Microsoft\Teams\Service Worker\CacheStorage\*.*" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Local\Microsoft\explorer\thumbcache*" >nul 2>&1
	)

:AggressiveWindowsCleanup
	ECHO Cleaning Windows Store, UWP Apps, and System Caches
	For /d %%u in (c:\users\*) do (
		REM Windows Store & UWP App Caches
		FOR /D %%p IN ("%%u\AppData\Local\Packages\*") DO (
			DEL /S /Q /F "%%p\AC\INetCache\" >nul 2>&1
			DEL /S /Q /F "%%p\LocalCache\" >nul 2>&1
			DEL /S /Q /F "%%p\TempState\" >nul 2>&1
		)
		REM OneDrive Logs
		DEL /S /Q /F "%%u\AppData\Local\Microsoft\OneDrive\logs\" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Local\Microsoft\OneDrive\setup\logs\" >nul 2>&1
		REM Graphics Shader Caches
		DEL /S /Q /F "%%u\AppData\Local\NVIDIA\DXCache\" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Local\AMD\DxCache\" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Local\D3DSCache\" >nul 2>&1
		REM Windows Notification Cache
		DEL /S /Q /F "%%u\AppData\Local\Microsoft\Windows\Notifications\" >nul 2>&1
		REM Cortana/Windows Search Cache
		FOR /D %%c IN ("%%u\AppData\Local\Packages\Microsoft.Windows.Cortana_*") DO (
			DEL /S /Q /F "%%c\LocalCache\" >nul 2>&1
		)
		FOR /D %%s IN ("%%u\AppData\Local\Packages\Microsoft.Windows.Search_*") DO (
			DEL /S /Q /F "%%s\LocalCache\" >nul 2>&1
		)
		REM WebCache Logs (not the database)
		DEL /S /Q /F "%%u\AppData\Local\Microsoft\Windows\WebCache\*.log" >nul 2>&1
	)
	ECHO Cleaning Windows Telemetry and Diagnostics
	DEL /S /Q /F "%PROGRAMDATA%\Microsoft\Diagnosis\" >nul 2>&1
	DEL /S /Q /F "%PROGRAMDATA%\Microsoft\Diagnosis\ETLLogs\" >nul 2>&1
	DEL /S /Q /F "%PROGRAMDATA%\Microsoft\Windows\WER\ReportQueue\" >nul 2>&1
	DEL /S /Q /F "%PROGRAMDATA%\Microsoft\Windows\WER\Temp\" >nul 2>&1
	DEL /S /Q /F "%WINDIR%\System32\LogFiles\WMI\" >nul 2>&1
	DEL /S /Q /F "%WINDIR%\System32\LogFiles\WMI\RtBackup\" >nul 2>&1
	ECHO Cleaning Windows Panther upgrade logs
	DEL /S /Q /F "%WINDIR%\Panther\" >nul 2>&1
	ECHO Cleaning Windows Update Downloads
	DEL /S /Q /F "%WINDIR%\SoftwareDistribution\Download\" >nul 2>&1

:TheRecycleBinIsNotAfolder
	ECHO Emptying the recycle bin... you weren't ACTUALLY storing stuff in there, were you? I hope not.
	rd /s /q %systemdrive%\$Recycle.bin >nul 2>&1
:UserProgramsCacheCleanup
	Echo Cleaning up cache from programs that are space hogs
:iTunes
	ECHO Clearing iTunes cached installers, iOS device firmware cache for all users
	taskkill /f /IM itunes.exe >nul 2>&1
	RD /S /Q "%systemdrive%\ProgramData\Apple Inc\Installer Cache" >nul 2>&1
	For /d %%u in (c:\users\*) do (
		RD /S /Q "%%u\AppData\roaming\Apple Computer\iTunes\iPhone Software Updates" >nul 2>&1
		RD /S /Q "%%u\AppData\roaming\Apple Computer\iTunes\iPod Software Updates" >nul 2>&1
	)
ECHO iOS device Backups cleanup
	set /p a=Do you wish to also delete any existing mobile phone iTunes device backups? [Y/N]?
	if /I "%a%" EQU "Y" goto iOSbackups
	if /I "%a%" EQU "N" goto FreakenMicrosoftTeams

:iOSbackups
	For /d %%u in (c:\users\*) do (
		RD /S /Q "%%u\AppData\roaming\Apple Computer\MobileSync\Backup" >nul 2>&1
	)
:FreakenMicrosoftTeams
	ECHO Clearing Microsoft Teams Cache for all users
	taskkill /F /IM teams.exe >nul 2>&1
	taskkill /F /IM ms-teams.exe >nul 2>&1
	For /d %%u in (c:\users\*) do (
		RD /S /Q "%%u\AppData\roaming\microsoft\teams" >nul 2>&1
		RD /S /Q "%%u\AppData\roaming\microsoft\teams\blob_storage" >nul 2>&1
		RD /S /Q "%%u\AppData\roaming\microsoft\teams\cache" >nul 2>&1
		RD /S /Q "%%u\AppData\roaming\microsoft\teams\databases" >nul 2>&1
		RD /S /Q "%%u\AppData\roaming\microsoft\teams\gpucache" >nul 2>&1
		RD /S /Q "%%u\AppData\roaming\microsoft\teams\indexeddb" >nul 2>&1
		RD /S /Q "%%u\AppData\roaming\microsoft\teams\Local Storage" >nul 2>&1
		RD /S /Q "%%u\AppData\roaming\microsoft\teams\tmp" >nul 2>&1
		RD /S /Q "%%u\AppData\Local\Packages\MSTeams_8wekyb3d8bbwe" >nul 2>&1
	)

:OutlookCache
	ECHO Clearing Outlook Cache
	taskkill /F /IM outlook.exe >nul 2>&1
	For /d %%u in (c:\users\*) do (
		RD /S /Q "%%u\AppData\Microsoft\Outlook\RoamCache\" >nul 2>&1
	)

:OfficeCache
	ECHO Clearing Microsoft Office Cache and Temporary Files
	For /d %%u in (c:\users\*) do (
		RD /S /Q "%%u\AppData\Local\Microsoft\Office\16.0\OfficeFileCache\" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Local\Temp\Word*\" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Local\Temp\Excel*\" >nul 2>&1
	)
::SCCM
::commented this out because SCCM doesn't rebuild cache if deleted manually and will fail to show/install software.
::Will update to use powershell command using date/time and will have validations.
::Reserved for SCCM cleanup powershell invoke script
::	ECHO Cleaning CCM Cache
::	DEL /S /Q /F "%systemdrive%\windows\ccmcache\"	 >nul 2>&1

:WEbBrowsers
	ECHO IExplore, Edge, Chrome, and Edgewebview Web browsers will be closed in order to clean all cache, remember CTRL+SHIFT+T to restore your browsing sessions.
	PAUSE
	ECHO Terminating Browsers and Removing temporary Internet Browser cache, no user data will be deleted
	taskkill /f /IM "iexplore.exe" >nul 2>&1
	taskkill /f /IM "msedge.exe" >nul 2>&1
	taskkill /f /IM "msedgewebview2.exe" >nul 2>&1
	taskkill /f /IM "chrome.exe" >nul 2>&1

:InternetExploder
	ECHO Cleaning Internet Explorer cache
	%systemdrive%\Windows\System32\rundll32.exe InetCpl.cpl, ClearMyTracksByProcess 255 >nul 2>&1
	%systemdrive%\Windows\System32\rundll32.exe InetCpl.cpl, ClearMyTracksByProcess 4351 >nul 2>&1

:GoogleChrome
 ECHO Cleaning Google Chrome Cache

	SETLOCAL EnableDelayedExpansion
	For /d %%u in ("%systemdrive%\users\*") do (
	SET "chromeDataDir=%%u\AppData\Local\Google\Chrome\User Data"
	SET "folderListFile=!TEMP!\chrome_profiles.txt"

	REM Find the matching folders and store them in the temporary file
	FOR /D %%A IN ("!chromeDataDir!\Default" "!chromeDataDir!\Profile *") DO (
	ECHO %%~nA>> "!folderListFile!"
	)

	IF EXIST "!folderListFile!" (
	FOR /F "usebackq tokens=*" %%B IN ("!folderListFile!") DO (
		del /q /s /f "!chromeDataDir!\%%B\Cache\cache_data\"	>nul 2>&1
		del /q /s /f "!chromeDataDir!\%%B\Code Cache\js\"	>nul 2>&1
		del /q /s /f "!chromeDataDir!\%%B\Code Cache\wasm\"	>nul 2>&1
		del /q /s /f "!chromeDataDir!\%%B\Service Worker\CacheStorage\"	>nul 2>&1
		del /q /s /f "!chromeDataDir!\%%B\Service Worker\ScriptCache\"	>nul 2>&1
		del /q /s /f "!chromeDataDir!\%%B\gpucache\"	>nul 2>&1
			)
		)
		del /q /s /f "!chromeDataDir!\component_crx_cache\"	>nul 2>&1
		del /q /s /f "!chromeDataDir!\GrShaderCache\"	>nul 2>&1
		del /q /s /f "!chromeDataDir!\ShaderCache\"	>nul 2>&1

		REM Clean up the temporary file after each profile is processed
    	IF EXIST "!folderListFile!" DEL /Q /F "!folderListFile!"
	)
	ENDLOCAL

:EdgeChromiumCache
ECHO Cleaning Edge -Chromium- Cache
	SETLOCAL EnableDelayedExpansion
	For /d %%u in ("%systemdrive%\users\*") do (
	SET "edgeDataDir=%%u\AppData\Local\Microsoft\Edge\User Data"
	SET "folderListFile=!TEMP!\edge_profiles.txt"

	REM Find the matching folders and store them in the temporary file
	FOR /D %%A IN ("!edgeDataDir!\Default" "!edgeDataDir!\Profile *") DO (
	ECHO %%~nA>> "!folderListFile!"
	)

	IF EXIST "!folderListFile!" (
	FOR /F "usebackq tokens=*" %%B IN ("!folderListFile!") DO (
		del /q /s /f "!edgeDataDir!\%%B\Cache\cache_data\"	>nul 2>&1
		del /q /s /f "!edgeDataDir!\%%B\Code Cache\js\"	>nul 2>&1
		del /q /s /f "!edgeDataDir!\%%B\Code Cache\wasm\"	>nul 2>&1
		del /q /s /f "!edgeDataDir!\%%B\Service Worker\CacheStorage\"	>nul 2>&1
		del /q /s /f "!edgeDataDir!\%%B\Service Worker\ScriptCache\"	>nul 2>&1
		del /q /s /f "!edgeDataDir!\%%B\gpucache\"	>nul 2>&1
			)
		)
		del /q /s /f "!edgeDataDir!\component_crx_cache\"	>nul 2>&1
		del /q /s /f "!edgeDataDir!\GrShaderCache\"	>nul 2>&1
		del /q /s /f "!edgeDataDir!\ShaderCache\"	>nul 2>&1

		REM Clean up the temporary file after each profile is processed
    	IF EXIST "!folderListFile!" DEL /Q /F "!folderListFile!"
	)
	ENDLOCAL

:EdgeWebView2Cache
	ECHO Cleaning Microsoft Edge WebView2 Runtime Cache
	For /d %%u in (c:\users\*) do (
		FOR /D %%v IN ("%%u\AppData\Local\Microsoft\EdgeWebView\Application\*") DO (
			DEL /S /Q /F "%%v\EBWebView\Default\Cache\" >nul 2>&1
			DEL /S /Q /F "%%v\EBWebView\Default\Code Cache\" >nul 2>&1
			DEL /S /Q /F "%%v\EBWebView\Default\GPUCache\" >nul 2>&1
		)
	)

:FireFoxCache
	ECHO Cleaning Firefox Cache
	taskkill /f /IM "firefox.exe" >nul 2>&1

	For /d %%u in (%systemdrive%\users\*) do (
		pushd "%%u\AppData\Local\Mozilla\Firefox\Profiles" 2>nul
		if not errorlevel 1 (
			for /d %%a in (*.default) do (
				if exist "%%a" (
					rd /S /Q "%%a\cache2" >nul 2>&1
					rd /S /Q "%%a\startupCache" >nul 2>&1
					rd /S /Q "%%a\jumpListCache" >nul 2>&1
					rd /S /Q "%%a\OfflineCache" >nul 2>&1
				)
			)
			for /d %%a in (*.default-release) do (
				if exist "%%a" (
					rd /S /Q "%%a\cache2" >nul 2>&1
					rd /S /Q "%%a\startupCache" >nul 2>&1
					rd /S /Q "%%a\jumpListCache" >nul 2>&1
					rd /S /Q "%%a\OfflineCache" >nul 2>&1
				)
			)
			popd
		)
	)

:DevelopmentToolsCleanup
	ECHO ////////////////////////////////////////////////////////////////////////////
	ECHO /////  Development Tool and Application Cache Cleanup                 /////
	ECHO /////  The following caches are safe to delete and will be rebuilt    /////
	ECHO /////  npm, pip, Gradle, Docker, NuGet, PowerShell, WSL, VS Code,     /////
	ECHO /////  Brave, Chocolatey, Android SDK, Conda, GitHub Desktop, Messenger /////
	ECHO ////////////////////////////////////////////////////////////////////////////

:npmCleanupPrompt
	set /p npm=Do you wish to delete npm cache? (Safe, rebuilds automatically) [Y/N]?
	if /I "%npm%" EQU "Y" goto npmCleanup
	if /I "%npm%" EQU "N" goto pipCleanupPrompt

:npmCleanup
	ECHO Cleaning npm cache for all users
	For /d %%u in (c:\users\*) do (
		RD /S /Q "%%u\AppData\Roaming\npm-cache" >nul 2>&1
		RD /S /Q "%%u\AppData\Local\npm-cache" >nul 2>&1
	)

:pipCleanupPrompt
	set /p pip=Do you wish to delete pip cache? (Safe, rebuilds automatically) [Y/N]?
	if /I "%pip%" EQU "Y" goto pipCleanup
	if /I "%pip%" EQU "N" goto gradleCleanupPrompt

:pipCleanup
	ECHO Cleaning pip cache for all users
	For /d %%u in (c:\users\*) do (
		RD /S /Q "%%u\AppData\Local\pip\cache" >nul 2>&1
		FOR /D %%p IN ("%%u\AppData\Roaming\Python\*") DO (
			RD /S /Q "%%p\pip\cache" >nul 2>&1
		)
	)

:gradleCleanupPrompt
	set /p gradle=Do you wish to delete Gradle cache? (Safe, rebuilds automatically) [Y/N]?
	if /I "%gradle%" EQU "Y" goto gradleCleanup
	if /I "%gradle%" EQU "N" goto dockerCleanupPrompt

:gradleCleanup
	ECHO Cleaning Gradle cache for all users
	For /d %%u in (c:\users\*) do (
		RD /S /Q "%%u\.gradle\caches" >nul 2>&1
		RD /S /Q "%%u\.gradle\wrapper\dists" >nul 2>&1
	)

:dockerCleanupPrompt
	set /p docker=Do you wish to clean Docker system cache? (Removes unused containers/images) [Y/N]?
	if /I "%docker%" EQU "Y" goto dockerCleanup
	if /I "%docker%" EQU "N" goto nugetCleanupPrompt

:dockerCleanup
	ECHO Running Docker system prune...
	ECHO This will remove all unused containers, networks, images and build cache
	docker system prune -a -f >nul 2>&1
	if %errorlevel% EQU 0 (
		ECHO Docker cleanup completed successfully
	) else (
		ECHO Docker cleanup skipped - Docker not installed or not running
	)

:nugetCleanupPrompt
	set /p nuget=Do you wish to delete NuGet cache? (Safe, rebuilds automatically) [Y/N]?
	if /I "%nuget%" EQU "Y" goto nugetCleanup
	if /I "%nuget%" EQU "N" goto powershellCleanupPrompt

:nugetCleanup
	ECHO Cleaning NuGet cache for all users
	For /d %%u in (c:\users\*) do (
		RD /S /Q "%%u\.nuget\packages" >nul 2>&1
		RD /S /Q "%%u\AppData\Local\NuGet\Cache" >nul 2>&1
		RD /S /Q "%%u\AppData\Local\NuGet\v3-cache" >nul 2>&1
	)

:powershellCleanupPrompt
	set /p ps=Do you wish to delete PowerShell user module cache? (Safe for user modules only) [Y/N]?
	if /I "%ps%" EQU "Y" goto powershellCleanup
	if /I "%ps%" EQU "N" goto wslCleanupPrompt

:powershellCleanup
	ECHO Cleaning PowerShell user module cache
	For /d %%u in (c:\users\*) do (
		REM Only clean user-installed modules, not system modules
		FOR /D %%m IN ("%%u\Documents\PowerShell\Modules\*") DO (
			RD /S /Q "%%m" >nul 2>&1
		)
	)

:wslCleanupPrompt
	set /p wsl=Do you wish to clean WSL distribution caches? (Requires WSL running) [Y/N]?
	if /I "%wsl%" EQU "Y" goto wslCleanup
	if /I "%wsl%" EQU "N" goto vscodeCleanupPrompt

:wslCleanup
	ECHO Cleaning WSL distribution caches...
	wsl bash -c "sudo rm -rf /tmp/* /var/tmp/* 2>/dev/null" >nul 2>&1
	wsl bash -c "sudo apt-get clean 2>/dev/null" >nul 2>&1
	wsl bash -c "sudo rm -rf /var/log/*.log 2>/dev/null" >nul 2>&1
	if %errorlevel% EQU 0 (
		ECHO WSL cleanup completed successfully
	) else (
		ECHO WSL cleanup skipped - WSL not running or not configured
	)

:vscodeCleanupPrompt
	set /p vscode=Do you wish to delete VS Code cache? (Safe, rebuilds automatically) [Y/N]?
	if /I "%vscode%" EQU "Y" goto vscodeCleanup
	if /I "%vscode%" EQU "N" goto braveCleanupPrompt

:vscodeCleanup
	ECHO Cleaning VS Code cache for all users
	For /d %%u in (c:\users\*) do (
		REM Code Cache
		DEL /S /Q /F "%%u\AppData\Roaming\Code\Cache\" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Roaming\Code\Code Cache\" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Roaming\Code\GPUCache\" >nul 2>&1
		REM CachedData
		RD /S /Q "%%u\AppData\Roaming\Code\CachedData" >nul 2>&1
		REM Logs
		DEL /S /Q /F "%%u\AppData\Roaming\Code\logs\" >nul 2>&1
		REM Service Worker Cache
		DEL /S /Q /F "%%u\AppData\Roaming\Code\Service Worker\CacheStorage\" >nul 2>&1
	)

:braveCleanupPrompt
	set /p brave=Do you wish to delete Brave Browser cache? (Safe, rebuilds automatically) [Y/N]?
	if /I "%brave%" EQU "Y" goto braveCleanup
	if /I "%brave%" EQU "N" goto chocoCleanupPrompt

:braveCleanup
	ECHO Cleaning Brave Browser cache for all users
	taskkill /f /IM brave.exe >nul 2>&1
	SETLOCAL EnableDelayedExpansion
	For /d %%u in ("%systemdrive%\users\*") do (
		SET "braveDataDir=%%u\AppData\Local\BraveSoftware\Brave-Browser\User Data"
		SET "folderListFile=!TEMP!\brave_profiles.txt"
		REM Find the matching folders and store them in the temporary file
		IF EXIST "!braveDataDir!" (
			dir "!braveDataDir!" /b /ad 2>nul | findstr /r "^Default$ ^Profile" > "!folderListFile!" 2>nul
			REM Loop through each folder listed in the temporary file
			FOR /F "delims=" %%p IN ('type "!folderListFile!" 2^>nul') DO (
				del /q /s /f "!braveDataDir!\%%p\Cache\*.*" >nul 2>&1
				del /q /s /f "!braveDataDir!\%%p\Code Cache\*.*" >nul 2>&1
				del /q /s /f "!braveDataDir!\%%p\GPUCache\*.*" >nul 2>&1
			)
		)
		del /q /s /f "!braveDataDir!\GrShaderCache\" >nul 2>&1
		del /q /s /f "!braveDataDir!\ShaderCache\" >nul 2>&1
		IF EXIST "!folderListFile!" DEL /Q /F "!folderListFile!"
	)
	ENDLOCAL

:chocoCleanupPrompt
	set /p choco=Do you wish to delete Chocolatey package cache? (Safe, reinstalls if needed) [Y/N]?
	if /I "%choco%" EQU "Y" goto chocoCleanup
	if /I "%choco%" EQU "N" goto androidCleanupPrompt

:chocoCleanup
	ECHO Cleaning Chocolatey package cache
	DEL /S /Q /F "C:\ProgramData\chocolatey\cache\" >nul 2>&1
	DEL /S /Q /F "C:\ProgramData\chocolatey\logs\" >nul 2>&1
	if %errorlevel% EQU 0 (
		ECHO Chocolatey cache cleaned successfully
	) else (
		ECHO Chocolatey cleanup skipped - Chocolatey not installed
	)

:androidCleanupPrompt
	set /p android=Do you wish to delete Android SDK build cache? (Safe for build caches only) [Y/N]?
	if /I "%android%" EQU "Y" goto androidCleanup
	if /I "%android%" EQU "N" goto condaCleanupPrompt

:androidCleanup
	ECHO Cleaning Android SDK build caches for all users
	For /d %%u in (c:\users\*) do (
		REM Gradle build cache for Android
		RD /S /Q "%%u\AppData\Local\Android\.gradle\caches" >nul 2>&1
		REM Android build cache
		RD /S /Q "%%u\AppData\Local\Android\build-cache" >nul 2>&1
		REM AVD temp files
		DEL /S /Q /F "%%u\.android\avd\*.tmp" >nul 2>&1
		DEL /S /Q /F "%%u\.android\cache\" >nul 2>&1
	)

:condaCleanupPrompt
	set /p conda=Do you wish to delete Anaconda/Conda package cache? (Safe, rebuilds automatically) [Y/N]?
	if /I "%conda%" EQU "Y" goto condaCleanup
	if /I "%conda%" EQU "N" goto githubCleanupPrompt

:condaCleanup
	ECHO Cleaning Anaconda/Conda package cache for all users
	For /d %%u in (c:\users\*) do (
		RD /S /Q "%%u\AppData\Local\conda\pkgs" >nul 2>&1
		RD /S /Q "%%u\.conda\pkgs" >nul 2>&1
		REM Conda cache
		DEL /S /Q /F "%%u\AppData\Local\conda\cache\" >nul 2>&1
	)

:githubCleanupPrompt
	set /p github=Do you wish to delete GitHub Desktop logs and cache? (Safe, rebuilds automatically) [Y/N]?
	if /I "%github%" EQU "Y" goto githubCleanup
	if /I "%github%" EQU "N" goto messengerCleanupPrompt

:githubCleanup
	ECHO Cleaning GitHub Desktop cache for all users
	taskkill /F /IM GitHubDesktop.exe >nul 2>&1
	For /d %%u in (c:\users\*) do (
		DEL /S /Q /F "%%u\AppData\Roaming\GitHub Desktop\logs\" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Local\GitHubDesktop\Cache\" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Local\GitHubDesktop\Code Cache\" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Local\GitHubDesktop\GPUCache\" >nul 2>&1
	)

:messengerCleanupPrompt
	set /p messenger=Do you wish to delete Messenger cache? (Safe, rebuilds automatically) [Y/N]?
	if /I "%messenger%" EQU "Y" goto messengerCleanup
	if /I "%messenger%" EQU "N" goto ollamaCleanupPrompt

:messengerCleanup
	ECHO Cleaning Messenger cache for all users
	taskkill /F /IM Messenger.exe >nul 2>&1
	For /d %%u in (c:\users\*) do (
		DEL /S /Q /F "%%u\AppData\Local\Messenger\Cache\" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Local\Messenger\Code Cache\" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Local\Messenger\GPUCache\" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Roaming\Messenger\Cache\" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Roaming\Messenger\logs\" >nul 2>&1
	)

:ollamaCleanupPrompt
	set /p ollama=Do you wish to delete Ollama cache? (Logs and temp only, NOT models) [Y/N]?
	if /I "%ollama%" EQU "Y" goto ollamaCleanup
	if /I "%ollama%" EQU "N" goto playwrightCleanupPrompt

:ollamaCleanup
	ECHO Cleaning Ollama cache (preserving models)
	For /d %%u in (c:\users\*) do (
		DEL /S /Q /F "%%u\AppData\Local\Ollama\*.log" >nul 2>&1
		RD /S /Q "%%u\AppData\Local\Ollama\tmp" >nul 2>&1
	)

:playwrightCleanupPrompt
	set /p playwright=Do you wish to delete Playwright browser cache? (500MB-2GB, reinstalls on next use) [Y/N]?
	if /I "%playwright%" EQU "Y" goto playwrightCleanup
	if /I "%playwright%" EQU "N" goto uvCleanupPrompt

:playwrightCleanup
	ECHO Cleaning Playwright browser cache
	For /d %%u in (c:\users\*) do (
		RD /S /Q "%%u\AppData\Local\ms-playwright" >nul 2>&1
		RD /S /Q "%%u\AppData\Local\ms-playwright-go" >nul 2>&1
	)

:uvCleanupPrompt
	set /p uv=Do you wish to delete uv/Poetry Python cache? (Safe, rebuilds automatically) [Y/N]?
	if /I "%uv%" EQU "Y" goto uvCleanup
	if /I "%uv%" EQU "N" goto zoomCleanupPrompt

:uvCleanup
	ECHO Cleaning uv and Poetry cache
	For /d %%u in (c:\users\*) do (
		RD /S /Q "%%u\AppData\Local\uv\cache" >nul 2>&1
		RD /S /Q "%%u\AppData\Local\pypoetry\Cache" >nul 2>&1
		RD /S /Q "%%u\AppData\Roaming\pypoetry\Cache" >nul 2>&1
		RD /S /Q "%%u\AppData\Local\prisma-nodejs" >nul 2>&1
	)

:zoomCleanupPrompt
	set /p zoom=Do you wish to delete Zoom cache? (Safe, rebuilds automatically) [Y/N]?
	if /I "%zoom%" EQU "Y" goto zoomCleanup
	if /I "%zoom%" EQU "N" goto claudeCleanupPrompt

:zoomCleanup
	ECHO Cleaning Zoom cache
	taskkill /F /IM Zoom.exe >nul 2>&1
	For /d %%u in (c:\users\*) do (
		RD /S /Q "%%u\AppData\Roaming\Zoom\data" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Roaming\Zoom\logs\*.*" >nul 2>&1
	)

:claudeCleanupPrompt
	set /p claude=Do you wish to delete Claude Desktop cache? (Safe, rebuilds automatically) [Y/N]?
	if /I "%claude%" EQU "Y" goto claudeCleanup
	if /I "%claude%" EQU "N" goto audacityCleanupPrompt

:claudeCleanup
	ECHO Cleaning Claude Desktop cache
	taskkill /F /IM Claude.exe >nul 2>&1
	For /d %%u in (c:\users\*) do (
		RD /S /Q "%%u\AppData\Local\AnthropicClaude\Cache" >nul 2>&1
		RD /S /Q "%%u\AppData\Local\AnthropicClaude\Code Cache" >nul 2>&1
		RD /S /Q "%%u\AppData\Local\AnthropicClaude\GPUCache" >nul 2>&1
		RD /S /Q "%%u\AppData\Roaming\Claude\Cache" >nul 2>&1
	)

:audacityCleanupPrompt
	set /p audacity=Do you wish to delete Audacity temp files? (Safe, rebuilds automatically) [Y/N]?
	if /I "%audacity%" EQU "Y" goto audacityCleanup
	if /I "%audacity%" EQU "N" goto handbrakeCleanupPrompt

:audacityCleanup
	ECHO Cleaning Audacity temp files
	taskkill /F /IM audacity.exe >nul 2>&1
	For /d %%u in (c:\users\*) do (
		DEL /S /Q /F "%%u\AppData\Local\audacity\SessionData\*.*" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Roaming\audacity\AutoSave\*.*" >nul 2>&1
	)

:handbrakeCleanupPrompt
	set /p handbrake=Do you wish to delete HandBrake logs? (Safe) [Y/N]?
	if /I "%handbrake%" EQU "Y" goto handbrakeCleanup
	if /I "%handbrake%" EQU "N" goto pgadminCleanupPrompt

:handbrakeCleanup
	ECHO Cleaning HandBrake logs
	For /d %%u in (c:\users\*) do (
		DEL /S /Q /F "%%u\AppData\Roaming\HandBrake\logs\*.*" >nul 2>&1
	)

:pgadminCleanupPrompt
	set /p pgadmin=Do you wish to delete pgAdmin session cache? (Safe) [Y/N]?
	if /I "%pgadmin%" EQU "Y" goto pgadminCleanup
	if /I "%pgadmin%" EQU "N" goto winrarCleanupPrompt

:pgadminCleanup
	ECHO Cleaning pgAdmin cache
	For /d %%u in (c:\users\*) do (
		RD /S /Q "%%u\AppData\Roaming\pgAdmin\sessions" >nul 2>&1
		RD /S /Q "%%u\AppData\Roaming\pgadmin4\sessions" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Roaming\pgAdmin\*.log" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Roaming\pgadmin4\*.log" >nul 2>&1
	)

:winrarCleanupPrompt
	set /p winrar=Do you wish to delete WinRAR temp extract cache? (Safe) [Y/N]?
	if /I "%winrar%" EQU "Y" goto winrarCleanup
	if /I "%winrar%" EQU "N" goto rufusCleanupPrompt

:winrarCleanup
	ECHO Cleaning WinRAR cache
	For /d %%u in (c:\users\*) do (
		RD /S /Q "%%u\AppData\Roaming\WinRAR\Arc" >nul 2>&1
	)

:rufusCleanupPrompt
	set /p rufus=Do you wish to delete Rufus ISO cache? (Safe) [Y/N]?
	if /I "%rufus%" EQU "Y" goto rufusCleanup
	if /I "%rufus%" EQU "N" goto everythingCleanupPrompt

:rufusCleanup
	ECHO Cleaning Rufus cache
	For /d %%u in (c:\users\*) do (
		DEL /S /Q /F "%%u\AppData\Local\Rufus\*.iso" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Local\Rufus\*.img" >nul 2>&1
	)

:everythingCleanupPrompt
	set /p everything=Do you wish to delete Everything search index? (Will rebuild on next launch) [Y/N]?
	if /I "%everything%" EQU "Y" goto everythingCleanup
	if /I "%everything%" EQU "N" goto avidemuxCleanupPrompt

:everythingCleanup
	ECHO Cleaning Everything search index
	taskkill /F /IM Everything.exe >nul 2>&1
	For /d %%u in (c:\users\*) do (
		DEL /S /Q /F "%%u\AppData\Local\Everything\*.db" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Roaming\Everything\*.db" >nul 2>&1
	)

:avidemuxCleanupPrompt
	set /p avidemux=Do you wish to delete avidemux temp files? (Safe) [Y/N]?
	if /I "%avidemux%" EQU "Y" goto avidemuxCleanup
	if /I "%avidemux%" EQU "N" goto antigravityCleanupPrompt

:avidemuxCleanup
	ECHO Cleaning avidemux temp files
	For /d %%u in (c:\users\*) do (
		RD /S /Q "%%u\AppData\Local\avidemux" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Roaming\avidemux\*.*" >nul 2>&1
	)

:antigravityCleanupPrompt
	set /p antigravity=Do you wish to delete Antigravity cache? (Safe, rebuilds automatically) [Y/N]?
	if /I "%antigravity%" EQU "Y" goto antigravityCleanup
	if /I "%antigravity%" EQU "N" goto CLEANMGR

:antigravityCleanup
	ECHO Cleaning Antigravity cache
	For /d %%u in (c:\users\*) do (
		RD /S /Q "%%u\AppData\Roaming\Antigravity\Cache" >nul 2>&1
		RD /S /Q "%%u\AppData\Roaming\Antigravity\Code Cache" >nul 2>&1
		RD /S /Q "%%u\AppData\Roaming\Antigravity\GPUCache" >nul 2>&1
		DEL /S /Q /F "%%u\AppData\Roaming\Antigravity\logs\*.*" >nul 2>&1
		RD /S /Q "%%u\.gemini\antigravity\browser_recordings" >nul 2>&1
	)

:CLEANMGR
	ECHO Configuring Disk Cleanup registry settings for all safe to delete content

:: Set all the CLEANMGR registry entries for Group #69 -have a sense of humor!
	SET _Group_No=StateFlags0069
	SET _RootKey=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches /f

:: Temporary Setup Files
	REG ADD "%_RootKey%\Active Setup Temp Folders" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: Branch Cache (WAN bandwidth optimization)
	REG ADD "%_RootKey%\BranchCache" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: Catalog Files for the Content Indexer (deletes all files in the folder c:\catalog.wci)
	REG ADD "%_RootKey%\Content Indexer Cleaner" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: Delivery Optimization Files (service to share bandwidth for uploading Windows updates)
	REG ADD "%_RootKey%\Delivery Optimization Files" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: Diagnostic data viewer database files (Windows app that sends data to Microsoft)
	REG ADD "%_RootKey%\Diagnostic Data Viewer database Files" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: Direct X Shader cache (graphics cache, clearing this can can speed up application load time.)
	REG ADD "%_RootKey%\D3D Shader Cache" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: Downloaded Program Files (ActiveX controls and Java applets downloaded from the Internet)
	REG ADD "%_RootKey%\Downloaded Program Files" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: Temporary Internet Files
	REG ADD "%_RootKey%\Internet Cache Files" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: Language resources Files (unused languages and keyboard layouts)
	REG ADD "%_RootKey%\Language Pack" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: Offline Files (Web pages)
	REG ADD "%_RootKey%\Offline Pages Files" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: Old ChkDsk Files
	REG ADD "%_RootKey%\Old ChkDsk Files" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: Recycle Bin -If you store stuff in recycle bin... shame on you!
	REG ADD "%_RootKey%\Recycle Bin" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: Retail Demo
	REG ADD "%_RootKey%\RetailDemo Offline Content" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: Update package Backup Files (old versions)
	REG ADD "%_RootKey%\ServicePack Cleanup" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: Setup Log files (software install logs)
	REG ADD "%_RootKey%\Setup Log Files" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: System Error memory dump files (These can be very large if the system has crashed)
	REG ADD "%_RootKey%\System error memory dump files" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: System Error minidump files (smaller memory crash dumps)
	REG ADD "%_RootKey%\System error minidump files" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: Temporary Files (%Windir%\Temp and %Windir%\Logs)
	REG ADD "%_RootKey%\Temporary Files" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: Windows Update Cleanup (old system files not migrated during a Windows Upgrade)
	REG ADD "%_RootKey%\Update Cleanup" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: Thumbnails (Explorer will recreate thumbnails as each folder is viewed.)
	REG ADD "%_RootKey%\Thumbnail Cache" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: Windows Defender Antivirus
	REG ADD "%_RootKey%\Windows Defender" /v %_Group_No% /d 2 /t REG_DWORD /f >nul 2>&1

:: Windows error reports and feedback diagnostics
	REG ADD "%_RootKey%\Windows Error Reporting Files" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1

:: Windows Upgrade log files
	REG ADD "%_RootKey%\Windows Upgrade Log Files" /v %_Group_No% /t REG_DWORD /d 00000002 /f >nul 2>&1
	ECHO DiskCleanup registry settings completed
	ECHO Running CleanMgr and Waiting for Disk Cleanup to complete, this takes a while - do not close this window!
	START /wait CLEANMGR /sagerun:69 >nul 2>&1
	ECHO Be patient, this process can take a while depending on how much temporary Crap has accummulated in your system...
	START /wait CLEANMGR /verylowdisk /autoclean >nul 2>&1


:RestorePointsCleaup
	ECHO	//////////////////////////////////////////////////////////////////////////////////////
	ECHO	/////  Warning! To Maximize Free Space, Windows Restore Points and old Windows   /////
	ECHO	/////  installs Cleanup process is about to begin.  You will NOT be able to      /////
	ECHO	/////  restore your pc to a previous date / installation if you type Y.          /////
	ECHO	//////////////////////////////////////////////////////////////////////////////////////
	set /p c=Are you sure you wish to continue? [Y/N]?
	if /I "%c%" EQU "Y" goto removeRestorePoints
	if /I "%c%" EQU "N" goto hibernation
:removeRestorePoints
	vssadmin delete shadows /all >nul 2>&1
	::The next line can be enabled by removing the "::" if you want the system to create a new restore point.
	::wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "AfterDiskCleanup", 100, 7 >nul 2>&1

:PreviousWindowsInstalls
	ECHO Removing any previous Windows Installations found.

:Windows.old
	::The obvious Windows.old folder that is visible
	IF exist "%systemDrive%\$Windows.old" (
		takeown /F "%systemDrive%\$Windows.old" /A /R /D Y >nul 2>&1
		icacls "%systemdrive%\$Windows.old" /grant *S-1-5-32-544:F /T /C /Q >nul 2>&1
		RD /s /q %systemdrive%\$Windows.old >nul 2>&1
	) else goto windowsbt

:Windowsbt
	::$Windows.~BT hidden folder
	IF exist "%systemDrive%\$Windows.~BT" (
		takeown /F "%systemDrive%\$Windows.~BT" /A /R /D Y >nul 2>&1
		icacls %systemdrive%\$Windows.~BT\*.* /T /grant administrators:F >nul 2>&1
		RD /s /q %systemDrive%\$Windows.~BT >nul 2>&1
	) else goto Windowsws

:Windowsws
	::$Windows.~WS hidden folder
	IF exist "%systemdrive%\$Windows.~WS" (
		takeown /F "%systemDrive%\$Windows.~WS" /A /R /D Y >nul 2>&1
		icacls %systemdrive%\$Windows.~WS\*.* /T /grant administrators:F >nul 2>&1
		RD /s /q %systemDrive%\$Windows.~WS >nul 2>&1
	) else (
		ECHO No previous windows version folders found
	)

:hibernation
::	Reasons to leave Hibernation/Fast Startup/Hybrid Shutdown disabled on desktops...
::	1. Most modern PC's come with an SSD or m.2 drive and fast startup is not required.
::	2. Hybrid shutdown/hibernation/fast startup often causes Windows Updates to NOT install properly.
::	3. "system up time" timer in task manager keeps running with this enabled.
::	.
::	1 Reason to enable on a laptop:
::	Only good thing from Hibernate/Fast Startup is if your Laptop/Tablet battery dies while in sleep/standby mode...
::	your open files are saved because the laptop will wake, save data in ram to hibernation file, then shutdown.
	SetLocal EnableExtensions
:detectchassis
	Set "Type=" & For /F EOL^=- %%G In ('powershell.exe -NoProfile -Command "(Get-CimInstance -Query 'Select * From CIM_Chassis').ChassisTypes | Select-Object -Property @{ Label = '-'; Expression = { Switch ($_) { { '3', '4', '5', '6', '7', '13', '15', '16', '24' -Eq $_ } { 'Desktop' }; { '8', '9', '10', '11', '12', '14', '18', '21', '30', '31', '32' -Eq $_ } { 'Laptop' }; default { '' } } } }" 2^>NUL') Do Set Type=%%G
	If Not Defined Type GoTo END
	Set Type
	if /i "%Type%"=="Laptop" goto laptop
	if /i "%Type%"=="Desktop" goto desktop
:laptop
	ECHO Laptop detected - enabling hibernation mode
	powercfg -h on
	goto END
:desktop
	ECHO Desktop detected - disabling hibernation mode
	powercfg -h off
	goto END
:END
	ECHO Waiting 30 seconds for Windows to settle and rebuild system files...
	TIMEOUT /T 30 /NOBREAK
	echo ********************************************
	ECHO Checking for large system files that may have been recreated:
	powershell -Command "Get-ChildItem C:\pagefile.sys -Force -ErrorAction SilentlyContinue | Select-Object Name, @{Name='SizeGB';Expression={[math]::Round($_.Length/1GB,2)}}"
	powershell -Command "Get-ChildItem C:\hiberfil.sys -Force -ErrorAction SilentlyContinue | Select-Object Name, @{Name='SizeGB';Expression={[math]::Round($_.Length/1GB,2)}}"
	echo ********************************************
	ECHO New free space of hard drive after Windows settled:
	fsutil volume diskfree c:
	echo ********************************************
	ECHO.
	ECHO NOTE: Windows 11 reserves 6-7GB for system updates and recovery.
	ECHO       If Explorer shows different free space, wait 1-2 minutes for
	ECHO       Windows to reclaim its reserved storage. This is normal behavior.
	echo ********************************************
	color 0A
	ECHO All cleaned up, have a nice day!
	PAUSE
