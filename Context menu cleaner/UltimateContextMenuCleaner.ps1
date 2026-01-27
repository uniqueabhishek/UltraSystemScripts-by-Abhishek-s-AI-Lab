#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Ultimate Context Menu Manager - Comprehensive Windows Context Menu Cleaner & Auditor

.DESCRIPTION
    A consolidated, professional-grade tool that combines all features from multiple
    context menu management scripts into one unified solution.

.FEATURES
    - Scans context menus for: Files, Folders, Directory Background, Drives
    - Health scoring (0-100) with intelligent orphan detection
    - Whitelist protection for critical Windows entries
    - Automatic .reg backup before any deletion
    - Restore from last backup or choose from backup history
    - Finds common entries across multiple registry roots
    - Direct removal of specific known entries
    - Comprehensive logging with timestamps
    - Explorer restart option to apply changes immediately
    - Progress indicator during scans

.NOTES
    Author: Consolidated from multiple scripts
    Requires: Administrator privileges
    Version: 1.0.0
#>

Clear-Host

# ===============================================================================
# CONFIGURATION
# ===============================================================================

$Config = @{
    # Critical entries that should NEVER be deleted
    Whitelist = @(
        "Open With", "Send To", "Copy As Path", "ShellNew",
        "Pin to Start", "Pin to Quick Access", "Pin to taskbar",
        "Properties", "Open", "Print", "Edit", "Find",
        "Run as administrator", "Open with Code", "Open in Terminal",
        "Scan with Microsoft Defender", "Cast to Device",
        "Share", "Give access to", "Restore previous versions",
        "Antigravity", "VSCode", "Code"
    )

    # File paths
    LogFile   = Join-Path $env:USERPROFILE "Desktop\ContextMenuManager_Log.txt"
    BackupDir = Join-Path $env:USERPROFILE "Desktop\ContextMenuBackups"

    # UI Settings
    ShowProgress = $true

    # Registry paths by category
    RegistryPaths = @{
        File = @(
            "HKCR:\*\shell",
            "HKCR:\*\ContextMenuHandlers",
            "HKCU:\Software\Classes\*\shell",
            "HKCU:\Software\Classes\*\ContextMenuHandlers"
        )
        Folder = @(
            "HKCR:\Folder\shell",
            "HKCR:\Folder\ContextMenuHandlers",
            "HKCU:\Software\Classes\Folder\shell",
            "HKCU:\Software\Classes\Folder\ContextMenuHandlers",
            "HKCR:\Directory\shell",
            "HKCR:\Directory\ContextMenuHandlers",
            "HKCU:\Software\Classes\Directory\shell",
            "HKCU:\Software\Classes\Directory\ContextMenuHandlers"
        )
        DirectoryBackground = @(
            "HKCR:\Directory\Background\shell",
            "HKCR:\Directory\Background\ContextMenuHandlers",
            "HKCU:\Software\Classes\Directory\Background\shell",
            "HKCU:\Software\Classes\Directory\Background\ContextMenuHandlers"
        )
        Drive = @(
            "HKCR:\Drive\shell",
            "HKCR:\Drive\ContextMenuHandlers",
            "HKCU:\Software\Classes\Drive\shell",
            "HKCU:\Software\Classes\Drive\ContextMenuHandlers"
        )
        AllFileSystemObjects = @(
            "HKCR:\AllFileSystemObjects\ShellEx\ContextMenuHandlers"
        )
    }
}

# Ensure backup directory exists
if (-not (Test-Path $Config.BackupDir)) {
    New-Item -Path $Config.BackupDir -ItemType Directory -Force | Out-Null
}

# Global variable for last backup
$global:LastBackup = $null

# ===============================================================================
# LOGGING
# ===============================================================================

function Write-Log {
    param(
        [ValidateSet("INFO", "BACKUP", "DELETE", "RESTORE", "ERROR", "WARNING")]
        [string]$Level,
        [string]$Message
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] $Level : $Message"
    Add-Content -Path $Config.LogFile -Value $logEntry
}

# ===============================================================================
# UI FUNCTIONS
# ===============================================================================

function Show-Banner {
    $banner = @"

+===============================================================================+
|                     ULTIMATE CONTEXT MENU MANAGER                             |
|                  Professional Registry Cleaner & Auditor                      |
+===============================================================================+
"@
    Write-Host $banner -ForegroundColor Cyan
}

function Show-MainMenu {
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor DarkGray
    Write-Host "  MAIN MENU" -ForegroundColor White
    Write-Host "===============================================================" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [1] " -ForegroundColor Yellow -NoNewline
    Write-Host "Scan File Context Menu         " -NoNewline
    Write-Host "(Right-click on files)" -ForegroundColor DarkGray

    Write-Host "  [2] " -ForegroundColor Yellow -NoNewline
    Write-Host "Scan Folder Context Menu       " -NoNewline
    Write-Host "(Right-click on folders)" -ForegroundColor DarkGray

    Write-Host "  [3] " -ForegroundColor Yellow -NoNewline
    Write-Host "Scan Directory Background      " -NoNewline
    Write-Host "(Right-click in empty space)" -ForegroundColor DarkGray

    Write-Host "  [4] " -ForegroundColor Yellow -NoNewline
    Write-Host "Scan Drive Context Menu        " -NoNewline
    Write-Host "(Right-click on drives)" -ForegroundColor DarkGray

    Write-Host ""
    Write-Host "  [5] " -ForegroundColor Green -NoNewline
    Write-Host "Scan ALL Context Menus         " -NoNewline
    Write-Host "(Comprehensive scan)" -ForegroundColor DarkGray

    Write-Host "  [6] " -ForegroundColor Green -NoNewline
    Write-Host "Find Common Entries            " -NoNewline
    Write-Host "(Entries in multiple locations)" -ForegroundColor DarkGray

    Write-Host ""
    Write-Host "  [7] " -ForegroundColor Magenta -NoNewline
    Write-Host "Restore from Backup            " -NoNewline
    Write-Host "(Choose backup file)" -ForegroundColor DarkGray

    Write-Host "  [8] " -ForegroundColor Magenta -NoNewline
    Write-Host "Undo Last Deletion             " -NoNewline
    Write-Host "(Quick restore)" -ForegroundColor DarkGray

    Write-Host ""
    Write-Host "  [9] " -ForegroundColor Cyan -NoNewline
    Write-Host "Restart Explorer               " -NoNewline
    Write-Host "(Apply changes immediately)" -ForegroundColor DarkGray

    Write-Host "  [0] " -ForegroundColor Red -NoNewline
    Write-Host "Exit"
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor DarkGray
}

function Show-EntryActionMenu {
    Write-Host ""
    Write-Host "Actions:" -ForegroundColor White
    Write-Host "  [D] Delete single entry (by number)" -ForegroundColor Yellow
    Write-Host "  [O] Bulk delete all ORPHANED entries" -ForegroundColor Red
    Write-Host "  [W] Bulk delete all WARNING entries" -ForegroundColor DarkYellow
    Write-Host "  [Enter] Return to main menu" -ForegroundColor DarkGray
}

# ===============================================================================
# INSTALLED APPS DETECTION (Cached)
# ===============================================================================

$script:InstalledAppsCache = $null

function Get-InstalledApps {
    if ($script:InstalledAppsCache) { return $script:InstalledAppsCache }

    $names = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    $regPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $regPaths) {
        try {
            Get-ItemProperty $path -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.DisplayName) {
                    [void]$names.Add($_.DisplayName.ToLower())
                }
            }
        } catch { }
    }

    $script:InstalledAppsCache = $names
    return $names
}

# ===============================================================================
# HELPER FUNCTIONS
# ===============================================================================

function Expand-EnvVars {
    param([string]$Path)
    if (-not $Path) { return $null }
    return [Environment]::ExpandEnvironmentVariables($Path)
}

function Get-ExecutableFromCommand {
    param([string]$Command)
    if (-not $Command) { return $null }

    # Match quoted path or unquoted first token
    $pattern = '^(?:"(?<exe>[^"]+)"|(?<exe>\S+))'
    $match = [regex]::Match($Command, $pattern)

    if ($match.Success) {
        $exe = $match.Groups["exe"].Value
        return Expand-EnvVars $exe
    }
    return $null
}

function Get-StatusColor {
    param([string]$Status)
    switch ($Status) {
        "Whitelisted" { return "Cyan" }
        "Healthy"     { return "Green" }
        "Warning"     { return "Yellow" }
        "Partial"     { return "DarkYellow" }
        "Orphaned"    { return "Red" }
        default       { return "White" }
    }
}

# ===============================================================================
# CONTEXT MENU SCANNER
# ===============================================================================

function Get-ContextMenuEntries {
    param(
        [string[]]$Paths,
        [string]$Category = "Unknown"
    )

    $entries = [System.Collections.Generic.List[PSCustomObject]]::new()
    $installedApps = Get-InstalledApps
    $totalPaths = $Paths.Count
    $pathIndex = 0

    foreach ($path in $Paths) {
        $pathIndex++

        if ($Config.ShowProgress) {
            $percent = [int](($pathIndex / $totalPaths) * 100)
            Write-Progress -Activity "Scanning $Category context menu" -Status $path -PercentComplete $percent
        }

        if (-not (Test-Path -LiteralPath $path)) { continue }

        $children = Get-ChildItem -LiteralPath $path -ErrorAction SilentlyContinue

        foreach ($child in $children) {
            $score = 0
            $issues = @()
            $status = "Unknown"
            $command = $null

            # Check whitelist first
            if ($Config.Whitelist -contains $child.PSChildName) {
                $status = "Whitelisted"
                $score = 100
            }
            else {
                # Case 1: Shell verb with command subkey
                $cmdPath = Join-Path $child.PSPath "command"
                if (Test-Path $cmdPath) {
                    $command = (Get-ItemProperty -Path $cmdPath -ErrorAction SilentlyContinue)."(default)" 2>$null

                    if (-not $command) {
                        $issues += "Empty command"
                    }
                    else {
                        $score += 25
                        $exe = Get-ExecutableFromCommand $command

                        if ($exe) {
                            $expanded = Expand-EnvVars $exe
                            if (Test-Path $expanded) {
                                $score += 25
                                $exeNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($expanded)
                                if ($installedApps.Contains($exeNameNoExt.ToLower())) {
                                    $score += 25
                                } else {
                                    $issues += "Not in installed apps list"
                                }
                            } else {
                                $issues += "Missing executable: $expanded"
                            }
                        } else {
                            $issues += "Could not parse executable path"
                        }
                    }
                }
                # Case 2: CLSID-based handler (e.g., ContextMenuHandlers)
                elseif ($child.PSChildName -match '^{[0-9A-Fa-f\-]+}$') {
                    $clsidPath = "HKCR:\CLSID\$($child.PSChildName)\InprocServer32"
                    if (Test-Path $clsidPath) {
                        $dll = (Get-ItemProperty -Path $clsidPath -ErrorAction SilentlyContinue)."(default)"
                        if ($dll) {
                            $expandedDll = Expand-EnvVars $dll
                            if (Test-Path $expandedDll) {
                                $score += 75
                            } else {
                                $issues += "Missing DLL: $expandedDll"
                            }
                        } else {
                            $issues += "CLSID has empty DLL path"
                        }
                    } else {
                        $issues += "CLSID handler missing InprocServer32"
                    }
                }
                # Case 3: Named handler with CLSID in default value
                else {
                    $defaultVal = (Get-ItemProperty $child.PSPath -ErrorAction SilentlyContinue)."(default)" 2>$null
                    if ($defaultVal -and $defaultVal -match '^\{.*\}$') {
                        $clsidPath = "HKCR:\CLSID\$defaultVal\InprocServer32"
                        if (Test-Path $clsidPath) {
                            $dll = (Get-ItemProperty -Path $clsidPath -ErrorAction SilentlyContinue)."(default)"
                            if ($dll) {
                                $expandedDll = Expand-EnvVars $dll
                                if (Test-Path $expandedDll) {
                                    $score += 75
                                } else {
                                    $issues += "Missing DLL: $expandedDll"
                                }
                            } else {
                                $issues += "CLSID has empty DLL path"
                            }
                        } else {
                            $issues += "Missing CLSID registration: $defaultVal"
                        }
                    }
                    # Case 4: AppX package check
                    elseif ($child.PSChildName -like "AppX*") {
                        try {
                            $pkg = Get-AppxPackage -Name "*$($child.PSChildName)*" -ErrorAction SilentlyContinue
                            if ($pkg) {
                                $score += 75
                            } else {
                                $issues += "Missing AppX package"
                            }
                        } catch {
                            $issues += "Could not check AppX package"
                        }
                    }
                    else {
                        $issues += "No command or recognized handler"
                    }
                }

                # Assign status based on score
                if ($score -ge 75) { $status = "Healthy" }
                elseif ($score -ge 50) { $status = "Warning" }
                elseif ($score -gt 0) { $status = "Partial" }
                else { $status = "Orphaned" }
            }

            $entries.Add([PSCustomObject]@{
                Key      = $child.PSPath
                Name     = $child.PSChildName
                Score    = $score
                Status   = $status
                Issues   = ($issues -join "; ")
                Category = $Category
                Command  = $command
            })
        }
    }

    if ($Config.ShowProgress) {
        Write-Progress -Activity "Scanning $Category context menu" -Completed
    }

    return $entries
}

# ===============================================================================
# BACKUP & RESTORE FUNCTIONS
# ===============================================================================

function Backup-RegistryKey {
    param(
        [string]$KeyPath,
        [string]$Name
    )

    $safeName = ($Name -replace '[^\w\-\._]', '_')
    $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
    $backupFile = Join-Path $Config.BackupDir "Backup_${safeName}_${timestamp}.reg"

    # Convert PowerShell path to reg.exe format
    $regPath = $KeyPath -replace '^Microsoft\.PowerShell\.Core\\Registry::', ''
    $regPath = $regPath -replace '^HKCR:', 'HKEY_CLASSES_ROOT'
    $regPath = $regPath -replace '^HKCU:', 'HKEY_CURRENT_USER'
    $regPath = $regPath -replace '^HKLM:', 'HKEY_LOCAL_MACHINE'

    try {
        $null = & reg export $regPath $backupFile /y 2>&1
        if ($LASTEXITCODE -eq 0 -and (Test-Path $backupFile)) {
            Write-Host "  [OK] Backup created: " -ForegroundColor Green -NoNewline
            Write-Host $backupFile -ForegroundColor DarkGray
            $global:LastBackup = $backupFile
            Write-Log -Level "BACKUP" -Message "$regPath -> $backupFile"
            return $true
        } else {
            throw "reg export failed with exit code $LASTEXITCODE"
        }
    } catch {
        Write-Host "  [FAIL] Backup failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Log -Level "ERROR" -Message "Backup failed for $regPath - $($_.Exception.Message)"
        return $false
    }
}

function Remove-ContextMenuEntry {
    param(
        [string]$KeyPath,
        [string]$Name
    )

    # Check whitelist
    if ($Config.Whitelist -contains $Name) {
        Write-Host "  [SKIP] Whitelisted: $Name" -ForegroundColor Cyan
        return $false
    }

    if (-not (Test-Path $KeyPath)) {
        Write-Host "  [FAIL] Key not found: $KeyPath" -ForegroundColor Red
        return $false
    }

    # Create backup first
    $backupSuccess = Backup-RegistryKey -KeyPath $KeyPath -Name $Name

    if (-not $backupSuccess) {
        $confirm = Read-Host "  Backup failed. Delete anyway? (Y/N)"
        if ($confirm -notmatch '^[Yy]$') {
            Write-Host "  Cancelled." -ForegroundColor DarkGray
            return $false
        }
    }

    try {
        Remove-Item $KeyPath -Recurse -Force -ErrorAction Stop
        Write-Host "  [OK] Deleted: $Name" -ForegroundColor Green
        Write-Log -Level "DELETE" -Message $KeyPath
        return $true
    } catch {
        Write-Host "  [FAIL] Delete failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Level "ERROR" -Message "Delete failed for $KeyPath - $($_.Exception.Message)"
        return $false
    }
}

function Restore-FromLastBackup {
    if ($global:LastBackup -and (Test-Path $global:LastBackup)) {
        try {
            $null = & reg import $global:LastBackup 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] Restored from: $global:LastBackup" -ForegroundColor Green
                Write-Log -Level "RESTORE" -Message "Restored from $global:LastBackup"
            } else {
                throw "reg import failed with exit code $LASTEXITCODE"
            }
        } catch {
            Write-Host "  [FAIL] Restore failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-Log -Level "ERROR" -Message "Restore failed - $($_.Exception.Message)"
        }
    } else {
        Write-Host "  No recent backup available to restore." -ForegroundColor Yellow
    }
}

function Restore-FromChosenBackup {
    $files = Get-ChildItem -Path $Config.BackupDir -Filter "*.reg" -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending

    if (-not $files -or $files.Count -eq 0) {
        Write-Host "  No backup files found in: $($Config.BackupDir)" -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "  Available backups:" -ForegroundColor White
    Write-Host "  ---------------------------------------------------------------" -ForegroundColor DarkGray

    $idx = 1
    foreach ($file in $files) {
        $age = (Get-Date) - $file.LastWriteTime
        $ageStr = if ($age.TotalDays -ge 1) { "{0:N0} days ago" -f $age.TotalDays }
                  elseif ($age.TotalHours -ge 1) { "{0:N0} hours ago" -f $age.TotalHours }
                  else { "{0:N0} minutes ago" -f $age.TotalMinutes }

        Write-Host "  [$idx] " -ForegroundColor Yellow -NoNewline
        Write-Host "$($file.Name) " -NoNewline
        Write-Host "($ageStr)" -ForegroundColor DarkGray
        $idx++
    }

    Write-Host ""
    $choice = Read-Host "  Enter number to restore (or Enter to cancel)"

    if ([string]::IsNullOrWhiteSpace($choice)) {
        Write-Host "  Cancelled." -ForegroundColor DarkGray
        return
    }

    if (-not [int]::TryParse($choice, [ref]$null)) {
        Write-Host "  Invalid selection." -ForegroundColor Red
        return
    }

    $n = [int]$choice
    if ($n -lt 1 -or $n -gt $files.Count) {
        Write-Host "  Selection out of range." -ForegroundColor Red
        return
    }

    $fileToRestore = $files[$n - 1].FullName

    try {
        $null = & reg import $fileToRestore 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Restored: $fileToRestore" -ForegroundColor Green
            $global:LastBackup = $fileToRestore
            Write-Log -Level "RESTORE" -Message "Restored from $fileToRestore"
        } else {
            throw "reg import failed with exit code $LASTEXITCODE"
        }
    } catch {
        Write-Host "  [FAIL] Restore failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Level "ERROR" -Message "Restore failed for $fileToRestore - $($_.Exception.Message)"
    }
}

# ===============================================================================
# DISPLAY FUNCTIONS
# ===============================================================================

function Show-Entries {
    param([System.Collections.Generic.List[PSCustomObject]]$Entries)

    if (-not $Entries -or $Entries.Count -eq 0) {
        Write-Host "  No entries found." -ForegroundColor Yellow
        return
    }

    # Sort by status priority, then by name
    $statusOrder = @{ "Orphaned" = 1; "Partial" = 2; "Warning" = 3; "Healthy" = 4; "Whitelisted" = 5 }
    $sorted = $Entries | Sort-Object { $statusOrder[$_.Status] }, Name

    Write-Host ""
    Write-Host "  +============================================================================+" -ForegroundColor DarkGray
    Write-Host "  |  #   | Score | Status      | Name                                         |" -ForegroundColor DarkGray
    Write-Host "  +============================================================================+" -ForegroundColor DarkGray

    $idx = 1
    foreach ($entry in $sorted) {
        $color = Get-StatusColor $entry.Status
        $statusPad = $entry.Status.PadRight(11)
        $namePad = $entry.Name
        if ($namePad.Length -gt 42) { $namePad = $namePad.Substring(0, 39) + "..." }
        $namePad = $namePad.PadRight(42)

        Write-Host "  | " -ForegroundColor DarkGray -NoNewline
        Write-Host ("{0,3}" -f $idx) -ForegroundColor White -NoNewline
        Write-Host " | " -ForegroundColor DarkGray -NoNewline
        Write-Host ("{0,5}" -f $entry.Score) -ForegroundColor $color -NoNewline
        Write-Host " | " -ForegroundColor DarkGray -NoNewline
        Write-Host $statusPad -ForegroundColor $color -NoNewline
        Write-Host " | " -ForegroundColor DarkGray -NoNewline
        Write-Host $namePad -NoNewline
        Write-Host " |" -ForegroundColor DarkGray

        # Show issues on next line if any
        if ($entry.Issues) {
            $issuesPad = ("     -> " + $entry.Issues)
            if ($issuesPad.Length -gt 74) { $issuesPad = $issuesPad.Substring(0, 71) + "..." }
            Write-Host "  | " -ForegroundColor DarkGray -NoNewline
            Write-Host $issuesPad.PadRight(74) -ForegroundColor DarkRed -NoNewline
            Write-Host " |" -ForegroundColor DarkGray
        }

        $idx++
    }

    Write-Host "  +============================================================================+" -ForegroundColor DarkGray

    # Summary
    $orphans = ($sorted | Where-Object { $_.Status -eq "Orphaned" }).Count
    $warnings = ($sorted | Where-Object { $_.Status -eq "Warning" }).Count
    $healthy = ($sorted | Where-Object { $_.Status -in @("Healthy", "Whitelisted") }).Count

    Write-Host ""
    Write-Host "  Summary: " -ForegroundColor White -NoNewline
    Write-Host "$healthy Healthy " -ForegroundColor Green -NoNewline
    Write-Host "| " -ForegroundColor DarkGray -NoNewline
    Write-Host "$warnings Warnings " -ForegroundColor Yellow -NoNewline
    Write-Host "| " -ForegroundColor DarkGray -NoNewline
    Write-Host "$orphans Orphaned" -ForegroundColor Red

    return $sorted
}

function Invoke-EntryActions {
    param([System.Collections.Generic.List[PSCustomObject]]$Entries)

    if (-not $Entries -or $Entries.Count -eq 0) { return }

    Show-EntryActionMenu
    $action = Read-Host "  Choose action"

    switch ($action.ToUpper()) {
        "D" {
            $num = Read-Host "  Enter entry number to delete"
            if ([int]::TryParse($num, [ref]$null)) {
                $n = [int]$num
                if ($n -ge 1 -and $n -le $Entries.Count) {
                    $selected = $Entries[$n - 1]
                    Write-Host ""
                    Write-Host "  Selected: $($selected.Name)" -ForegroundColor White
                    Write-Host "  Key: $($selected.Key)" -ForegroundColor DarkGray
                    $confirm = Read-Host "  Confirm delete? (Y/N)"
                    if ($confirm -match '^[Yy]$') {
                        Remove-ContextMenuEntry -KeyPath $selected.Key -Name $selected.Name
                    } else {
                        Write-Host "  Cancelled." -ForegroundColor DarkGray
                    }
                } else {
                    Write-Host "  Invalid number." -ForegroundColor Red
                }
            }
        }
        "O" {
            $orphans = $Entries | Where-Object { $_.Status -eq "Orphaned" }
            if ($orphans.Count -gt 0) {
                Write-Host ""
                Write-Host "  Found $($orphans.Count) orphaned entries to delete:" -ForegroundColor Yellow
                foreach ($o in $orphans) {
                    Write-Host "    - $($o.Name)" -ForegroundColor DarkGray
                }
                $confirm = Read-Host "  Delete ALL orphaned entries? (Y/N)"
                if ($confirm -match '^[Yy]$') {
                    foreach ($o in $orphans) {
                        Remove-ContextMenuEntry -KeyPath $o.Key -Name $o.Name
                    }
                } else {
                    Write-Host "  Cancelled." -ForegroundColor DarkGray
                }
            } else {
                Write-Host "  No orphaned entries to delete." -ForegroundColor Green
            }
        }
        "W" {
            $warnings = $Entries | Where-Object { $_.Status -eq "Warning" }
            if ($warnings.Count -gt 0) {
                Write-Host ""
                Write-Host "  Found $($warnings.Count) warning entries:" -ForegroundColor Yellow
                foreach ($w in $warnings) {
                    Write-Host "    - $($w.Name)" -ForegroundColor DarkGray
                }
                Write-Host ""
                Write-Host "  WARNING: These entries may still be partially functional!" -ForegroundColor Yellow
                $confirm = Read-Host "  Delete ALL warning entries? (Y/N)"
                if ($confirm -match '^[Yy]$') {
                    foreach ($w in $warnings) {
                        Remove-ContextMenuEntry -KeyPath $w.Key -Name $w.Name
                    }
                } else {
                    Write-Host "  Cancelled." -ForegroundColor DarkGray
                }
            } else {
                Write-Host "  No warning entries to delete." -ForegroundColor Green
            }
        }
        default {
            # Return to menu
        }
    }
}

# ===============================================================================
# COMMON ENTRIES FINDER
# ===============================================================================

function Find-CommonEntries {
    Write-Host ""
    Write-Host "  Scanning for entries common across multiple registry locations..." -ForegroundColor Cyan

    $roots = @(
        "HKCR:\*\shell",
        "HKCR:\*\ContextMenuHandlers",
        "HKCR:\AllFileSystemObjects\ShellEx\ContextMenuHandlers",
        "HKCR:\Directory\Background\shell"
    )

    $rootEntries = @{}
    foreach ($root in $roots) {
        if (Test-Path $root) {
            $rootEntries[$root] = @(Get-ChildItem $root -ErrorAction SilentlyContinue |
                                   Select-Object -ExpandProperty PSChildName)
        } else {
            $rootEntries[$root] = @()
        }
    }

    # Find names present in all roots
    $common = $rootEntries[$roots[0]]
    foreach ($r in $roots[1..($roots.Count-1)]) {
        $common = $common | Where-Object { $rootEntries[$r] -contains $_ }
    }
    $common = $common | Sort-Object -Unique

    if (-not $common -or $common.Count -eq 0) {
        Write-Host "  No common entries found across all registry paths." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "  Common entries found in all 4 registry locations:" -ForegroundColor Green
    Write-Host "  ---------------------------------------------------------------" -ForegroundColor DarkGray

    $idx = 1
    foreach ($name in $common) {
        $isWhitelisted = $Config.Whitelist -contains $name
        if ($isWhitelisted) {
            Write-Host "  [$idx] $name " -NoNewline
            Write-Host "(Protected)" -ForegroundColor Cyan
        } else {
            Write-Host "  [$idx] $name" -ForegroundColor Yellow
        }
        $idx++
    }

    Write-Host ""
    $choice = Read-Host "  Enter numbers to delete (comma-separated), 'A' for all non-protected, or Enter to cancel"

    if ([string]::IsNullOrWhiteSpace($choice)) {
        Write-Host "  Cancelled." -ForegroundColor DarkGray
        return
    }

    $toDelete = @()
    if ($choice -eq "A") {
        $toDelete = $common | Where-Object { $Config.Whitelist -notcontains $_ }
    } else {
        $indices = $choice -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
        foreach ($i in $indices) {
            $n = [int]$i
            if ($n -ge 1 -and $n -le $common.Count) {
                $toDelete += $common[$n - 1]
            }
        }
    }

    if ($toDelete.Count -eq 0) {
        Write-Host "  No valid selections or all selections are protected." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "  Will delete these entries from ALL locations:" -ForegroundColor Yellow
    foreach ($name in $toDelete) { Write-Host "    - $name" -ForegroundColor DarkGray }

    $confirm = Read-Host "  Proceed? (Y/N)"
    if ($confirm -notmatch '^[Yy]$') {
        Write-Host "  Cancelled." -ForegroundColor DarkGray
        return
    }

    foreach ($name in $toDelete) {
        foreach ($root in $roots) {
            $keyPath = Join-Path $root $name
            if (Test-Path $keyPath) {
                Remove-ContextMenuEntry -KeyPath $keyPath -Name $name
            }
        }
    }

    Write-Host ""
    Write-Host "  Completed. Backups saved in: $($Config.BackupDir)" -ForegroundColor Green
}

# ===============================================================================
# EXPLORER RESTART
# ===============================================================================

function Restart-Explorer {
    Write-Host ""
    Write-Host "  Restarting Windows Explorer to apply changes..." -ForegroundColor Cyan

    try {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Start-Process explorer.exe
        Write-Host "  [OK] Explorer restarted successfully." -ForegroundColor Green
        Write-Log -Level "INFO" -Message "Explorer restarted"
    } catch {
        Write-Host "  [FAIL] Failed to restart Explorer: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Level "ERROR" -Message "Explorer restart failed - $($_.Exception.Message)"
    }
}

# ===============================================================================
# MAIN LOOP
# ===============================================================================

Show-Banner

Write-Host "  Log file: " -ForegroundColor DarkGray -NoNewline
Write-Host $Config.LogFile
Write-Host "  Backup dir: " -ForegroundColor DarkGray -NoNewline
Write-Host $Config.BackupDir

do {
    Show-MainMenu
    $choice = Read-Host "  Select option"

    switch ($choice) {
        "1" {
            Write-Host ""
            Write-Host "  Scanning FILE context menu entries..." -ForegroundColor Cyan
            $entries = Get-ContextMenuEntries -Paths $Config.RegistryPaths.File -Category "File"
            $sorted = Show-Entries $entries
            Invoke-EntryActions $sorted
        }
        "2" {
            Write-Host ""
            Write-Host "  Scanning FOLDER context menu entries..." -ForegroundColor Cyan
            $entries = Get-ContextMenuEntries -Paths $Config.RegistryPaths.Folder -Category "Folder"
            $sorted = Show-Entries $entries
            Invoke-EntryActions $sorted
        }
        "3" {
            Write-Host ""
            Write-Host "  Scanning DIRECTORY BACKGROUND context menu entries..." -ForegroundColor Cyan
            $entries = Get-ContextMenuEntries -Paths $Config.RegistryPaths.DirectoryBackground -Category "Directory Background"
            $sorted = Show-Entries $entries
            Invoke-EntryActions $sorted
        }
        "4" {
            Write-Host ""
            Write-Host "  Scanning DRIVE context menu entries..." -ForegroundColor Cyan
            $entries = Get-ContextMenuEntries -Paths $Config.RegistryPaths.Drive -Category "Drive"
            $sorted = Show-Entries $entries
            Invoke-EntryActions $sorted
        }
        "5" {
            Write-Host ""
            Write-Host "  Scanning ALL context menu entries..." -ForegroundColor Cyan

            $allPaths = @()
            $allPaths += $Config.RegistryPaths.File
            $allPaths += $Config.RegistryPaths.Folder
            $allPaths += $Config.RegistryPaths.DirectoryBackground
            $allPaths += $Config.RegistryPaths.Drive
            $allPaths += $Config.RegistryPaths.AllFileSystemObjects

            $entries = Get-ContextMenuEntries -Paths $allPaths -Category "All"
            $sorted = Show-Entries $entries
            Invoke-EntryActions $sorted
        }
        "6" {
            Find-CommonEntries
        }
        "7" {
            Restore-FromChosenBackup
        }
        "8" {
            Restore-FromLastBackup
        }
        "9" {
            Restart-Explorer
        }
        "0" {
            Write-Host ""
            Write-Host "  Exiting..." -ForegroundColor DarkGray
            break
        }
        default {
            Write-Host "  Invalid choice." -ForegroundColor Red
        }
    }

    if ($choice -ne "0") {
        Write-Host ""
        Read-Host "  Press Enter to continue"
    }

} while ($choice -ne "0")

Write-Host ""
Write-Host "  Thank you for using Ultimate Context Menu Manager!" -ForegroundColor Cyan
Write-Host ""
