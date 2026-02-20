# Windows C Drive Cleanup Script
# Run as Administrator in PowerShell
# Based on cleanup session 2026-02-20

param(
    [switch]$DryRun   # Pass -DryRun to see what would happen without doing it
)

function Get-DriveFreeGB {
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    return [math]::Round($disk.FreeSpace / 1GB, 2)
}

function Get-FolderSizeGB($path) {
    if (-not (Test-Path $path)) { return 0 }
    $size = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    return [math]::Round($size / 1GB, 2)
}

Write-Host "=== Windows C Drive Cleanup ===" -ForegroundColor Cyan
if ($DryRun) { Write-Host "[DRY RUN MODE - no changes will be made]" -ForegroundColor Yellow }
Write-Host ""

# --- Before ---
$freeBefore = Get-DriveFreeGB
Write-Host "C: free space BEFORE: $freeBefore GB" -ForegroundColor White
Write-Host ""

# --- 1. User Temp ---
$tempSize = Get-FolderSizeGB $env:TEMP
Write-Host "1. User Temp ($env:TEMP): $tempSize GB"
if (-not $DryRun -and $tempSize -gt 0) {
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "   Cleared." -ForegroundColor Green
}

# --- 2. Windows Temp ---
$wTempSize = Get-FolderSizeGB "C:\Windows\Temp"
Write-Host "2. Windows Temp (C:\Windows\Temp): $wTempSize GB"
if (-not $DryRun -and $wTempSize -gt 0) {
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "   Cleared." -ForegroundColor Green
}

# --- 3. Windows Update Cache ---
$wuSize = Get-FolderSizeGB "C:\Windows\SoftwareDistribution\Download"
Write-Host "3. Windows Update cache (SoftwareDistribution\Download): $wuSize GB"
if (-not $DryRun -and $wuSize -gt 0) {
    net stop wuauserv 2>&1 | Out-Null
    Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    net start wuauserv 2>&1 | Out-Null
    Write-Host "   Cleared." -ForegroundColor Green
}

# --- 4. DISM Component Store Cleanup ---
Write-Host "4. Running DISM component store cleanup..."
if (-not $DryRun) {
    Dism /Online /Cleanup-Image /StartComponentCleanup | Out-Null
    Write-Host "   Done." -ForegroundColor Green
} else {
    Write-Host "   [DRY RUN] Would run: Dism /Online /Cleanup-Image /StartComponentCleanup"
}

# --- 5. Shadow Copies (System Restore) ---
Write-Host "5. Checking shadow copies (system restore points)..."
$shadows = vssadmin list shadows 2>&1
$shadowCount = ($shadows | Select-String "Shadow Copy ID").Count
Write-Host "   Found $shadowCount shadow copy/copies."
if ($shadowCount -gt 0 -and -not $DryRun) {
    $confirm = Read-Host "   Delete all shadow copies? (y/N)"
    if ($confirm -eq 'y') {
        vssadmin delete shadows /all /quiet
        Write-Host "   Deleted." -ForegroundColor Green
    } else {
        Write-Host "   Skipped." -ForegroundColor Yellow
    }
} elseif ($shadowCount -gt 0 -and $DryRun) {
    Write-Host "   [DRY RUN] Would prompt to delete $shadowCount shadow copy/copies"
}

# --- After ---
Write-Host ""
$freeAfter = Get-DriveFreeGB
$freed = [math]::Round($freeAfter - $freeBefore, 2)
Write-Host "C: free space AFTER: $freeAfter GB" -ForegroundColor White
Write-Host "Total freed: $freed GB" -ForegroundColor Cyan

# --- Folder Size Report ---
Write-Host ""
Write-Host "=== Folder Size Report ===" -ForegroundColor Cyan
$folders = @('Windows', 'Users', 'Program Files', 'Program Files (x86)', 'ProgramData')
foreach ($d in $folders) {
    $gb = Get-FolderSizeGB "C:\$d"
    Write-Host "  $gb GB  -->  $d"
}
