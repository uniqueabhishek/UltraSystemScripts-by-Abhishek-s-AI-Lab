# Windows C Drive Cleanup — Session Notes
**Date:** 2026-02-20
**System:** Windows 11, 16GB RAM, C: drive (~100GB total)

---

## Summary of What Was Done

| Action | Space Freed |
|--------|-------------|
| Disabled hibernation (`hiberfil.sys`) | ~6 GB |
| Cleaned WinSxS component store (DISM) | ~0.93 GB |
| Cleared User Temp folder | ~2.42 GB |
| Deleted Windows Update download cache | ~varies |
| Deleted system restore point | ~2-4 GB |
| **Total estimated freed** | **~12+ GB** |

---

## Actions Taken & Commands Used

### 1. Disable Hibernation
```powershell
# Run as Administrator
powercfg /h off
```
- Freed: ~6 GB (hiberfil.sys was 6GB on this 16GB RAM machine)
- Verification: `powercfg /a` (hibernation no longer listed)
- Note: Sleep/suspend still works. Only "Hibernate" option is removed.

**Re-enable later (optional):**
```powershell
powercfg /h on
powercfg /h /size 25   # 25% of RAM — Windows may override with a minimum floor
```
> On 16GB RAM, Windows enforces a minimum ~6GB floor regardless of percentage set.
> Practical minimum is ~50% (`/size 50`). If you re-enable, expect ~6-8GB used.

---

### 2. Page File (pagefile.sys)
- Current size: **3,651 MB (~3.6 GB)** on C:
- Current usage: **0 MB** (RAM is sufficient)
- Decision: Left as-is (already small, not worth the risk)

**To move page file to D: drive (optional, frees ~3.6GB from C:):**
> Win → "Adjust the appearance and performance of Windows" → Advanced → Virtual Memory → Change
> - C: → Set to "No paging file"
> - D: → Set to "System managed size"
> - Requires restart

---

### 3. System Restore Points
**Check existing restore points (Admin terminal):**
```powershell
vssadmin list shadows
```
Result: 1 restore point found (created 2026-02-19).

**Delete all restore points:**
```powershell
vssadmin delete shadows /all /quiet
```

**Disable System Restore entirely:**
```powershell
# Run as Administrator
powershell -command "Disable-ComputerRestore -Drive 'C:\'"
vssadmin delete shadows /all /quiet
```

> Note: System Restore points cannot be moved to D:. They must stay on C:.

---

### 4. WinSxS Component Store Cleanup (DISM)
**Analyze (check reclaimable space):**
```powershell
# Run as Administrator
Dism /Online /Cleanup-Image /AnalyzeComponentStore
```
Result: 3.36 GB reclaimable → reduced to 2.43 GB after first pass.

**Clean it:**
```powershell
Dism /Online /Cleanup-Image /StartComponentCleanup
```
Run this 2-3 times until reclaimable packages = 0.

**Deeper clean (removes ability to uninstall recent Windows Updates):**
```powershell
Dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase
```
> Only use `/ResetBase` if you really need the space and are confident the system is stable.

---

### 5. Windows Update Download Cache
**Check cache contents:**
```powershell
dir C:\Windows\SoftwareDistribution\Download
```

**Clear the cache:**
```powershell
# Stop Windows Update service first
net stop wuauserv

# Delete cache (PowerShell syntax — NOT cmd del syntax)
Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force

# Restart Windows Update service
net start wuauserv
```
> Windows will re-download what it needs at next update cycle.

---

### 6. User Temp Folder
**Size found:** 2.42 GB

**Clear it:**
```powershell
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
```

---

### 7. C Drive Folder Analysis Script
Created [analyze.ps1](../analyze.ps1) to scan folder sizes:

```powershell
$folders = @('Windows','Users','Program Files','Program Files (x86)','ProgramData')
foreach ($d in $folders) {
    $path = "C:\$d"
    $size = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $gb = [math]::Round($size/1GB, 2)
    Write-Host "$gb GB  -->  $d"
}
Write-Host ""
Write-Host "--- Temp folders ---"
$temp1 = (Get-ChildItem $env:TEMP -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
Write-Host ([math]::Round($temp1/1GB,2)) "GB  -->  User Temp"
$temp2 = (Get-ChildItem "C:\Windows\Temp" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
Write-Host ([math]::Round($temp2/1GB,2)) "GB  -->  Windows Temp"
```

**Run with:**
```powershell
powershell -ExecutionPolicy Bypass -File "D:\D Desktop\analyze.ps1"
```

**Results from this session:**
```
29.98 GB  -->  Windows
 9.07 GB  -->  Program Files
 7.57 GB  -->  ProgramData
 4.42 GB  -->  Program Files (x86)
 3.91 GB  -->  Users

--- Temp folders ---
 2.42 GB  -->  User Temp
 0.02 GB  -->  Windows Temp
```

---

## What Cannot Be Moved Off C: Drive

| Item | Why |
|------|-----|
| `hiberfil.sys` (hibernation) | Must be on system drive — needed before OS loads at resume |
| System Restore points (`C:\System Volume Information`) | Must be on the drive being protected |
| `pagefile.sys` | CAN be moved to D: (see above) |

---

## ProgramData Cleanup Notes

Folders identified as safe to clean/remove if apps are uninstalled:

| Folder | Notes |
|--------|-------|
| `McAfee` + `McInstTemp...` | Leftover from 2021, McAfee not installed |
| `ChocolateyHttpCache` | Download cache, safe to clear |
| `Foxit Software` | If Foxit PDF Reader not in use |
| `NCH Software` | If NCH apps not in use |
| `SolidDocuments` | Old remnant from 2021 |
| `SP_FT_Logs` | Log files from 2021, likely safe to delete |
| `WinZip` | If WinZip not in use |
| `WindowsHolographicDevices` | HoloLens/VR remnant, safe to delete |

**NVIDIA folders** — just small log files (~5MB total), not worth touching.

---

## Planned Next Steps / Ideas for Automation Script

Based on this session, a cleanup script (`windows_cleanup.ps1` or similar) could automate:

1. **Check free space** — report C: drive status before/after
2. **Clear User Temp** — `$env:TEMP\*`
3. **Clear Windows Temp** — `C:\Windows\Temp\*`
4. **Clear Windows Update cache** — stop wuauserv, delete SoftwareDistribution\Download\*, restart wuauserv
5. **Run DISM cleanup** — `Dism /Online /Cleanup-Image /StartComponentCleanup`
6. **Check/delete shadow copies** — report restore point sizes, optionally delete
7. **Analyze folder sizes** — report top space consumers
8. **Report total freed** — compare before/after disk space

### Possible script features:
- Dry-run mode (shows what would be deleted without doing it)
- Interactive prompts before each destructive action
- Log file output with before/after sizes
- Scheduled task option (run monthly)

---

## Key Facts About This Machine

- **RAM:** 16 GB
- **C: drive total:** ~100 GB (`106307776512` bytes)
- **C: free at start of session:** ~35 GB (hidden system files eating rest)
- **C: free after cleanup:** ~54 GB
- **D: drive:** 72 GB free (good candidate for page file)
- **Windows version:** 10.0.26200.7840 (Windows 11)
- **Last DISM cleanup before today:** 2026-02-14
